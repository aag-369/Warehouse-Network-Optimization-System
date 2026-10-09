-- =====================================================================
-- PROJECT : WAREHOUSE NETWORK OPTIMIZATION SYSTEM (WNOS)
-- FILE    : 03_analysis_queries.sql
-- PURPOSE : Analytical / optimization queries that drive the system
-- RDBMS   : MySQL 8.0
-- AUTHOR  : Aayushman Ghatak
-- NOTE    : Run AFTER 01_schema_ddl.sql and 02_sample_data_dml.sql
-- =====================================================================

USE wnos;

-- ---------------------------------------------------------------------
-- Q1. NETWORK MASTER : every warehouse with its geography and cost base
-- ---------------------------------------------------------------------
SELECT  w.warehouse_code,
        w.warehouse_name,
        w.warehouse_type,
        r.region_name,
        l.city,
        w.storage_capacity_units,
        w.fixed_cost_monthly,
        w.status
FROM    warehouse w
JOIN    location  l ON l.location_id = w.location_id
JOIN    region    r ON r.region_id   = l.region_id
ORDER BY r.region_name, w.warehouse_code;


-- ---------------------------------------------------------------------
-- Q2. CAPACITY UTILISATION : occupied vs available space per warehouse
-- ---------------------------------------------------------------------
SELECT  w.warehouse_code,
        w.warehouse_name,
        w.storage_capacity_units                                  AS capacity_units,
        COALESCE(SUM(i.qty_on_hand), 0)                           AS units_stored,
        ROUND(COALESCE(SUM(i.qty_on_hand), 0)
              / w.storage_capacity_units * 100, 2)                AS utilisation_pct,
        w.storage_capacity_units - COALESCE(SUM(i.qty_on_hand), 0) AS free_units
FROM    warehouse w
LEFT JOIN inventory i ON i.warehouse_id = w.warehouse_id
GROUP BY w.warehouse_id, w.warehouse_code, w.warehouse_name, w.storage_capacity_units
ORDER BY utilisation_pct DESC;


-- ---------------------------------------------------------------------
-- Q3. REORDER ALERT : SKUs that have breached the reorder point
-- ---------------------------------------------------------------------
SELECT  w.warehouse_code,
        p.sku,
        p.product_name,
        p.abc_class,
        i.qty_on_hand,
        i.qty_reserved,
        i.qty_available,
        i.reorder_point,
        i.safety_stock,
        i.reorder_point - i.qty_available AS shortfall_units,
        CASE WHEN i.qty_available <= i.safety_stock THEN 'CRITICAL' ELSE 'REORDER' END AS alert_level
FROM    inventory i
JOIN    warehouse w ON w.warehouse_id = i.warehouse_id
JOIN    product   p ON p.product_id   = i.product_id
WHERE   i.qty_available <= i.reorder_point
ORDER BY alert_level, shortfall_units DESC;


-- ---------------------------------------------------------------------
-- Q4. ABC / PARETO ANALYSIS : cumulative inventory value contribution
--     (window functions - SUM OVER and running total)
-- ---------------------------------------------------------------------
WITH sku_value AS (
    SELECT  p.product_id,
            p.sku,
            p.product_name,
            p.abc_class,
            SUM(i.qty_on_hand)                 AS total_units,
            SUM(i.qty_on_hand * p.unit_cost)   AS inventory_value
    FROM    inventory i
    JOIN    product   p ON p.product_id = i.product_id
    GROUP BY p.product_id, p.sku, p.product_name, p.abc_class
)
SELECT  sku,
        product_name,
        abc_class,
        total_units,
        inventory_value,
        ROUND(inventory_value / SUM(inventory_value) OVER () * 100, 2) AS pct_of_value,
        ROUND(SUM(inventory_value) OVER (ORDER BY inventory_value DESC)
              / SUM(inventory_value) OVER () * 100, 2)                 AS cumulative_pct,
        RANK() OVER (ORDER BY inventory_value DESC)                    AS value_rank
FROM    sku_value
ORDER BY inventory_value DESC;


-- ---------------------------------------------------------------------
-- Q5. DAYS OF COVER : over-stocked and under-stocked positions
-- ---------------------------------------------------------------------
SELECT  w.warehouse_code,
        p.sku,
        i.qty_on_hand,
        i.avg_daily_demand,
        ROUND(i.qty_on_hand / NULLIF(i.avg_daily_demand, 0), 1) AS days_of_cover,
        CASE
            WHEN i.avg_daily_demand = 0                              THEN 'NO_MOVEMENT'
            WHEN i.qty_on_hand / i.avg_daily_demand > 30             THEN 'OVERSTOCK'
            WHEN i.qty_on_hand / i.avg_daily_demand < 7              THEN 'UNDERSTOCK'
            ELSE 'BALANCED'
        END AS cover_status
FROM    inventory i
JOIN    warehouse w ON w.warehouse_id = i.warehouse_id
JOIN    product   p ON p.product_id   = i.product_id
ORDER BY days_of_cover DESC;


-- ---------------------------------------------------------------------
-- Q6. COST TO SERVE : handling + freight cost carried by each order
-- ---------------------------------------------------------------------
SELECT  co.order_no,
        c.customer_name,
        c.priority_tier,
        w.warehouse_code                              AS served_from,
        co.order_value,
        f.handling_cost,
        COALESCE(SUM(s.freight_cost), 0)              AS freight_cost,
        f.handling_cost + COALESCE(SUM(s.freight_cost), 0) AS total_cost_to_serve,
        ROUND((f.handling_cost + COALESCE(SUM(s.freight_cost), 0))
              / NULLIF(co.order_value, 0) * 100, 2)   AS cost_to_serve_pct
FROM    customer_order   co
JOIN    customer          c ON c.customer_id  = co.customer_id
JOIN    order_fulfilment  f ON f.order_id     = co.order_id
JOIN    warehouse         w ON w.warehouse_id = f.warehouse_id
LEFT JOIN shipment_line  sl ON sl.order_line_id IN
            (SELECT order_line_id FROM order_line WHERE order_id = co.order_id)
LEFT JOIN shipment        s ON s.shipment_id = sl.shipment_id
GROUP BY co.order_id, co.order_no, c.customer_name, c.priority_tier,
         w.warehouse_code, co.order_value, f.handling_cost
ORDER BY cost_to_serve_pct DESC;


-- ---------------------------------------------------------------------
-- Q7. CHEAPEST MODE PER CORRIDOR : rank transport modes on each lane pair
--     (this is the core arc-selection step of the optimizer)
-- ---------------------------------------------------------------------
WITH lane_cost AS (
    SELECT  lo.city  AS origin_city,
            ld.city  AS dest_city,
            tl.transport_mode,
            tl.distance_km,
            tl.transit_time_hours,
            ROUND((tl.base_freight_cost + tl.toll_cost) * tl.congestion_index, 2) AS effective_cost
    FROM    transport_lane tl
    JOIN    location lo ON lo.location_id = tl.origin_location_id
    JOIN    location ld ON ld.location_id = tl.dest_location_id
    WHERE   tl.is_active = 1
)
SELECT  origin_city,
        dest_city,
        transport_mode,
        distance_km,
        transit_time_hours,
        effective_cost,
        ROUND(effective_cost / distance_km, 2) AS cost_per_km,
        RANK() OVER (PARTITION BY origin_city, dest_city ORDER BY effective_cost) AS cost_rank
FROM    lane_cost
ORDER BY origin_city, dest_city, cost_rank;


-- ---------------------------------------------------------------------
-- Q8. MODE TRADE-OFF : cost vs speed on the multi-modal corridors only
-- ---------------------------------------------------------------------
SELECT  lo.city AS origin_city,
        ld.city AS dest_city,
        tl.transport_mode,
        tl.transit_time_hours,
        ROUND((tl.base_freight_cost + tl.toll_cost) * tl.congestion_index, 2) AS effective_cost,
        ROUND(((tl.base_freight_cost + tl.toll_cost) * tl.congestion_index)
              / tl.transit_time_hours, 2) AS cost_per_hour_saved
FROM    transport_lane tl
JOIN    location lo ON lo.location_id = tl.origin_location_id
JOIN    location ld ON ld.location_id = tl.dest_location_id
WHERE  (tl.origin_location_id, tl.dest_location_id) IN (
            SELECT origin_location_id, dest_location_id
            FROM   transport_lane
            GROUP  BY origin_location_id, dest_location_id
            HAVING COUNT(DISTINCT transport_mode) > 1
       )
ORDER BY origin_city, dest_city, effective_cost;


-- ---------------------------------------------------------------------
-- Q9. CARRIER SCORECARD : realised on-time performance vs contracted
-- ---------------------------------------------------------------------
SELECT  ca.carrier_code,
        ca.carrier_name,
        ca.transport_mode,
        ca.on_time_pct                                        AS contracted_otd_pct,
        COUNT(s.shipment_id)                                  AS shipments,
        SUM(CASE WHEN s.actual_arrival IS NOT NULL
                  AND s.actual_arrival <= s.eta_datetime THEN 1 ELSE 0 END) AS on_time_shipments,
        ROUND(SUM(CASE WHEN s.actual_arrival IS NOT NULL
                        AND s.actual_arrival <= s.eta_datetime THEN 1 ELSE 0 END)
              / NULLIF(SUM(CASE WHEN s.actual_arrival IS NOT NULL THEN 1 ELSE 0 END), 0)
              * 100, 2)                                       AS actual_otd_pct,
        ROUND(SUM(s.freight_cost), 2)                         AS total_freight_spend,
        ROUND(SUM(s.freight_cost) / NULLIF(SUM(s.total_weight_kg), 0), 2) AS cost_per_kg
FROM    carrier  ca
LEFT JOIN shipment s ON s.carrier_id = ca.carrier_id
GROUP BY ca.carrier_id, ca.carrier_code, ca.carrier_name, ca.transport_mode, ca.on_time_pct
ORDER BY total_freight_spend DESC;


-- ---------------------------------------------------------------------
-- Q10. FORECAST ACCURACY : which model performs best, per warehouse
-- ---------------------------------------------------------------------
SELECT  df.model_used,
        COUNT(*)                                             AS forecasts_evaluated,
        ROUND(AVG(df.mape_pct), 2)                           AS avg_mape_pct,
        ROUND(AVG(ABS(df.actual_qty - df.forecast_qty)), 1)  AS avg_abs_error_units,
        ROUND(100 - AVG(df.mape_pct), 2)                     AS avg_accuracy_pct
FROM    demand_forecast df
WHERE   df.actual_qty IS NOT NULL
GROUP BY df.model_used
ORDER BY avg_mape_pct;


-- ---------------------------------------------------------------------
-- Q11. CENTRE OF GRAVITY : demand-weighted optimal warehouse coordinate
--      per region - the classic facility-location heuristic
-- ---------------------------------------------------------------------
SELECT  r.region_name,
        ROUND(SUM(l.latitude  * d.demand_units) / SUM(d.demand_units), 6) AS cog_latitude,
        ROUND(SUM(l.longitude * d.demand_units) / SUM(d.demand_units), 6) AS cog_longitude,
        SUM(d.demand_units)                                               AS total_demand_units
FROM   (
        SELECT co.customer_id, SUM(ol.quantity) AS demand_units
        FROM   order_line     ol
        JOIN   customer_order co ON co.order_id = ol.order_id
        GROUP  BY co.customer_id
       ) d
JOIN    customer c ON c.customer_id = d.customer_id
JOIN    location l ON l.location_id = c.location_id
JOIN    region   r ON r.region_id   = l.region_id
GROUP BY r.region_id, r.region_name
ORDER BY total_demand_units DESC;


-- ---------------------------------------------------------------------
-- Q12. NEAREST-WAREHOUSE ASSIGNMENT : Haversine great-circle distance
--      from every customer to every ACTIVE warehouse, best one kept
-- ---------------------------------------------------------------------
WITH distance_matrix AS (
    SELECT  c.customer_code,
            c.customer_name,
            lc.city                     AS customer_city,
            w.warehouse_code,
            lw.city                     AS warehouse_city,
            ROUND(6371 * ACOS(
                LEAST(1.0,
                    COS(RADIANS(lc.latitude)) * COS(RADIANS(lw.latitude))
                  * COS(RADIANS(lw.longitude) - RADIANS(lc.longitude))
                  + SIN(RADIANS(lc.latitude)) * SIN(RADIANS(lw.latitude))
                )), 2)                  AS distance_km
    FROM    customer  c
    JOIN    location  lc ON lc.location_id = c.location_id
    CROSS JOIN warehouse w
    JOIN    location  lw ON lw.location_id = w.location_id
    WHERE   w.status = 'ACTIVE'
)
SELECT  customer_code,
        customer_name,
        customer_city,
        warehouse_code,
        warehouse_city,
        distance_km
FROM   (
        SELECT dm.*,
               ROW_NUMBER() OVER (PARTITION BY customer_code ORDER BY distance_km) AS rn
        FROM   distance_matrix dm
       ) ranked
WHERE  rn = 1
ORDER BY distance_km DESC;


-- ---------------------------------------------------------------------
-- Q13. OPTIMIZATION RUN COMPARISON : algorithm benchmarking
-- ---------------------------------------------------------------------
SELECT  sc.scenario_name,
        orn.run_label,
        orn.objective,
        orn.algorithm,
        orn.baseline_cost,
        orn.optimized_cost,
        orn.baseline_cost - orn.optimized_cost AS absolute_saving,
        orn.savings_pct,
        orn.iterations,
        orn.runtime_seconds,
        orn.run_status
FROM    optimization_run       orn
JOIN    optimization_scenario  sc ON sc.scenario_id = orn.scenario_id
ORDER BY orn.savings_pct DESC;


-- ---------------------------------------------------------------------
-- Q14. TOP RECOMMENDATIONS : highest-value actions the optimizer proposes
-- ---------------------------------------------------------------------
SELECT  orn.run_label,
        w.warehouse_code,
        w.warehouse_name,
        COALESCE(p.sku, 'FACILITY-LEVEL') AS sku,
        res.recommended_action,
        res.recommended_qty,
        res.projected_saving,
        res.confidence_score,
        res.rationale
FROM    optimization_result res
JOIN    optimization_run    orn ON orn.run_id       = res.run_id
JOIN    warehouse           w   ON w.warehouse_id   = res.warehouse_id
LEFT JOIN product           p   ON p.product_id     = res.product_id
WHERE   res.projected_saving > 0
ORDER BY res.projected_saving DESC
LIMIT 10;


-- ---------------------------------------------------------------------
-- Q15. KPI TREND : month-on-month movement per warehouse (LAG)
-- ---------------------------------------------------------------------
SELECT  w.warehouse_code,
        k.snapshot_date,
        k.order_fill_rate_pct,
        LAG(k.order_fill_rate_pct) OVER (PARTITION BY k.warehouse_id ORDER BY k.snapshot_date)
            AS prev_fill_rate_pct,
        ROUND(k.order_fill_rate_pct
              - LAG(k.order_fill_rate_pct) OVER (PARTITION BY k.warehouse_id ORDER BY k.snapshot_date), 2)
            AS fill_rate_delta,
        k.capacity_utilization_pct,
        k.cost_per_order,
        ROUND(k.cost_per_order
              - LAG(k.cost_per_order) OVER (PARTITION BY k.warehouse_id ORDER BY k.snapshot_date), 2)
            AS cost_per_order_delta
FROM    kpi_snapshot k
JOIN    warehouse    w ON w.warehouse_id = k.warehouse_id
ORDER BY w.warehouse_code, k.snapshot_date;


-- ---------------------------------------------------------------------
-- Q16. REBALANCING CANDIDATES : surplus node -> deficit node for same SKU
-- ---------------------------------------------------------------------
SELECT  p.sku,
        p.product_name,
        src.warehouse_code AS surplus_warehouse,
        src.qty_on_hand    AS surplus_qty_on_hand,
        src.excess_units,
        dst.warehouse_code AS deficit_warehouse,
        dst.qty_on_hand    AS deficit_qty_on_hand,
        dst.shortfall_units,
        LEAST(src.excess_units, dst.shortfall_units) AS suggested_transfer_qty
FROM   (
        SELECT i.product_id, w.warehouse_code, i.qty_on_hand,
               CAST(i.qty_available - i.max_stock_level * 0.80 AS SIGNED) AS excess_units
        FROM   inventory i JOIN warehouse w ON w.warehouse_id = i.warehouse_id
        WHERE  i.qty_available > i.max_stock_level * 0.80
       ) src
JOIN   (
        SELECT i.product_id, w.warehouse_code, i.qty_on_hand,
               i.reorder_point - i.qty_available AS shortfall_units
        FROM   inventory i JOIN warehouse w ON w.warehouse_id = i.warehouse_id
        WHERE  i.qty_available <= i.reorder_point
       ) dst ON dst.product_id = src.product_id
JOIN    product p ON p.product_id = src.product_id
WHERE   src.warehouse_code <> dst.warehouse_code
ORDER BY suggested_transfer_qty DESC;


-- ---------------------------------------------------------------------
-- Q17. SUPPLIER SCORECARD : cost and lead-time competitiveness per SKU
-- ---------------------------------------------------------------------
SELECT  p.sku,
        p.product_name,
        s.supplier_name,
        sp.unit_purchase_cost,
        sp.lead_time_days,
        s.reliability_score,
        MIN(sp.unit_purchase_cost) OVER (PARTITION BY p.product_id) AS best_price,
        ROUND(sp.unit_purchase_cost
              - MIN(sp.unit_purchase_cost) OVER (PARTITION BY p.product_id), 2) AS price_premium,
        CASE WHEN sp.is_preferred = 1 THEN 'PREFERRED' ELSE 'ALTERNATE' END AS sourcing_status
FROM    supplier_product sp
JOIN    supplier s ON s.supplier_id = sp.supplier_id
JOIN    product  p ON p.product_id  = sp.product_id
ORDER BY p.sku, sp.unit_purchase_cost;


-- ---------------------------------------------------------------------
-- Q18. WAREHOUSE THROUGHPUT AND ORDER MIX
-- ---------------------------------------------------------------------
SELECT  w.warehouse_code,
        w.warehouse_name,
        COUNT(DISTINCT f.order_id)                    AS orders_allocated,
        SUM(CASE WHEN f.fulfilment_status = 'COMPLETE' THEN 1 ELSE 0 END) AS orders_completed,
        ROUND(SUM(CASE WHEN f.fulfilment_status = 'COMPLETE' THEN 1 ELSE 0 END)
              / COUNT(DISTINCT f.order_id) * 100, 2)  AS completion_rate_pct,
        ROUND(SUM(co.order_value), 2)                 AS revenue_handled,
        ROUND(AVG(co.order_value), 2)                 AS avg_order_value,
        ROUND(SUM(f.handling_cost), 2)                AS handling_cost
FROM    order_fulfilment f
JOIN    warehouse        w  ON w.warehouse_id = f.warehouse_id
JOIN    customer_order   co ON co.order_id    = f.order_id
GROUP BY w.warehouse_id, w.warehouse_code, w.warehouse_name
ORDER BY revenue_handled DESC;


-- ---------------------------------------------------------------------
-- Q19. REORDER POINT RECALCULATION
--      ROP = (avg daily demand x lead time) + safety stock
--      EOQ = SQRT( 2 x annual demand x ordering cost / holding cost )
-- ---------------------------------------------------------------------
SELECT  w.warehouse_code,
        p.sku,
        i.avg_daily_demand,
        sp.lead_time_days,
        i.safety_stock,
        i.reorder_point                                                    AS current_rop,
        CEIL(i.avg_daily_demand * sp.lead_time_days + i.safety_stock)      AS recommended_rop,
        CEIL(i.avg_daily_demand * sp.lead_time_days + i.safety_stock)
            - i.reorder_point                                              AS rop_adjustment,
        ROUND(SQRT( (2 * i.avg_daily_demand * 365 * 2500)
                    / NULLIF(p.unit_cost * 0.22, 0) ), 0)                  AS economic_order_qty
FROM    inventory i
JOIN    warehouse w ON w.warehouse_id = i.warehouse_id
JOIN    product   p ON p.product_id   = i.product_id
JOIN    supplier_product sp ON sp.product_id = i.product_id AND sp.is_preferred = 1
ORDER BY ABS(CEIL(i.avg_daily_demand * sp.lead_time_days + i.safety_stock) - i.reorder_point) DESC;


-- ---------------------------------------------------------------------
-- Q20. TOTAL NETWORK COST ROLL-UP : the objective function, evaluated
--      Total = fixed facility + variable handling + freight + carrying
-- ---------------------------------------------------------------------
SELECT  ROUND(SUM(fixed_cost),    2) AS fixed_facility_cost,
        ROUND(SUM(handling_cost), 2) AS handling_cost,
        ROUND(SUM(freight_cost),  2) AS freight_cost,
        ROUND(SUM(carrying_cost), 2) AS inventory_carrying_cost,
        ROUND(SUM(fixed_cost + handling_cost + freight_cost + carrying_cost), 2)
                                     AS total_network_cost
FROM   (
        SELECT SUM(fixed_cost_monthly) AS fixed_cost, 0 AS handling_cost,
               0 AS freight_cost, 0 AS carrying_cost
        FROM   warehouse WHERE status = 'ACTIVE'
        UNION ALL
        SELECT 0, SUM(handling_cost), 0, 0 FROM order_fulfilment
        UNION ALL
        SELECT 0, 0, SUM(freight_cost), 0 FROM shipment
        UNION ALL
        SELECT 0, 0, 0, SUM(i.qty_on_hand * p.unit_cost * 0.22 / 12)
        FROM   inventory i JOIN product p ON p.product_id = i.product_id
       ) cost_components;


-- ---------------------------------------------------------------------
-- Q21. SLOW-MOVING AND DEAD STOCK : no outbound movement in the period
-- ---------------------------------------------------------------------
SELECT  w.warehouse_code,
        p.sku,
        p.product_name,
        i.qty_on_hand,
        ROUND(i.qty_on_hand * p.unit_cost, 2) AS locked_capital,
        COALESCE(mv.outbound_units, 0)        AS outbound_units_in_period,
        CASE WHEN COALESCE(mv.outbound_units, 0) = 0 THEN 'DEAD_STOCK'
             WHEN COALESCE(mv.outbound_units, 0) < i.qty_on_hand * 0.05 THEN 'SLOW_MOVING'
             ELSE 'ACTIVE' END                AS movement_class
FROM    inventory i
JOIN    warehouse w ON w.warehouse_id = i.warehouse_id
JOIN    product   p ON p.product_id   = i.product_id
LEFT JOIN (
        SELECT inventory_id, SUM(ABS(quantity)) AS outbound_units
        FROM   inventory_transaction
        WHERE  txn_type IN ('OUTBOUND', 'TRANSFER_OUT')
        GROUP  BY inventory_id
       ) mv ON mv.inventory_id = i.inventory_id
ORDER BY locked_capital DESC;


-- ---------------------------------------------------------------------
-- Q22. SERVICE-LEVEL BREACH : orders that missed the customer SLA
-- ---------------------------------------------------------------------
SELECT  co.order_no,
        c.customer_name,
        c.priority_tier,
        c.service_level_hours                                       AS sla_hours,
        f.allocated_on,
        f.delivered_on,
        TIMESTAMPDIFF(HOUR, f.allocated_on, f.delivered_on)          AS actual_hours,
        TIMESTAMPDIFF(HOUR, f.allocated_on, f.delivered_on)
            - c.service_level_hours                                  AS hours_over_sla,
        CASE WHEN f.delivered_on IS NULL THEN 'IN_PROGRESS'
             WHEN TIMESTAMPDIFF(HOUR, f.allocated_on, f.delivered_on) <= c.service_level_hours
                  THEN 'MET' ELSE 'BREACHED' END                     AS sla_status
FROM    customer_order  co
JOIN    customer        c ON c.customer_id = co.customer_id
JOIN    order_fulfilment f ON f.order_id   = co.order_id
ORDER BY sla_status, hours_over_sla DESC;


-- ---------------------------------------------------------------------
-- Q23. STOCK TRANSFER LEDGER : realised network rebalancing and its cost
-- ---------------------------------------------------------------------
SELECT  st.transfer_id,
        wf.warehouse_code AS from_warehouse,
        wt.warehouse_code AS to_warehouse,
        p.sku,
        st.quantity,
        st.transfer_date,
        st.transfer_cost,
        ROUND(st.transfer_cost / st.quantity, 2) AS cost_per_unit_moved,
        s.shipment_no,
        st.transfer_status
FROM    stock_transfer st
JOIN    warehouse wf ON wf.warehouse_id = st.from_warehouse_id
JOIN    warehouse wt ON wt.warehouse_id = st.to_warehouse_id
JOIN    product   p  ON p.product_id    = st.product_id
LEFT JOIN shipment s ON s.shipment_id   = st.shipment_id
ORDER BY st.transfer_date;


-- ---------------------------------------------------------------------
-- Q24. VEHICLE LOAD FACTOR : how well fleet capacity is being used
-- ---------------------------------------------------------------------
SELECT  v.registration_no,
        v.vehicle_type,
        ca.carrier_name,
        v.capacity_weight_kg,
        s.shipment_no,
        s.total_weight_kg,
        ROUND(s.total_weight_kg / v.capacity_weight_kg * 100, 2) AS weight_fill_pct,
        ROUND(s.total_volume_m3 / v.capacity_volume_m3 * 100, 2) AS volume_fill_pct,
        ROUND(s.freight_cost / NULLIF(s.total_weight_kg, 0), 2)  AS freight_per_kg
FROM    shipment s
JOIN    vehicle  v  ON v.vehicle_id  = s.vehicle_id
JOIN    carrier  ca ON ca.carrier_id = v.carrier_id
ORDER BY weight_fill_pct;


-- ---------------------------------------------------------------------
-- Q25. EXECUTIVE SUMMARY : one-row network health dashboard
-- ---------------------------------------------------------------------
SELECT  (SELECT COUNT(*) FROM warehouse WHERE status = 'ACTIVE')          AS active_warehouses,
        (SELECT COUNT(*) FROM product)                                    AS skus_managed,
        (SELECT COUNT(*) FROM customer)                                   AS customers_served,
        (SELECT SUM(qty_on_hand) FROM inventory)                          AS total_units_in_network,
        (SELECT ROUND(SUM(i.qty_on_hand * p.unit_cost), 2)
           FROM inventory i JOIN product p ON p.product_id = i.product_id) AS inventory_value,
        (SELECT COUNT(*) FROM customer_order)                             AS orders_in_period,
        (SELECT ROUND(SUM(order_value), 2) FROM customer_order)           AS order_revenue,
        (SELECT ROUND(AVG(order_fill_rate_pct), 2)
           FROM kpi_snapshot WHERE snapshot_date = '2026-07-31')          AS avg_fill_rate_pct,
        (SELECT ROUND(MAX(savings_pct), 2)
           FROM optimization_run WHERE run_status = 'CONVERGED')          AS best_savings_pct;

-- =====================================================================
-- END OF ANALYSIS QUERIES
-- =====================================================================
