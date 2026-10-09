-- =====================================================================
-- PROJECT : WAREHOUSE NETWORK OPTIMIZATION SYSTEM (WNOS)
-- FILE    : 01_schema_ddl.sql
-- PURPOSE : Data Definition Language - complete physical schema
-- RDBMS   : MySQL 8.0 (InnoDB, utf8mb4)
-- AUTHOR  : Aayushman Ghatak
-- =====================================================================
-- RUN ORDER : 01_schema_ddl.sql -> 02_sample_data_dml.sql -> 03_analysis_queries.sql
-- =====================================================================

DROP DATABASE IF EXISTS wnos;
CREATE DATABASE wnos
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;
USE wnos;

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================
-- MODULE 1 : GEOGRAPHY / NETWORK MASTER
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. REGION : top-level geographic grouping of the distribution network
-- ---------------------------------------------------------------------
CREATE TABLE region (
    region_id       INT             NOT NULL AUTO_INCREMENT,
    region_code     VARCHAR(10)     NOT NULL,
    region_name     VARCHAR(60)     NOT NULL,
    country         VARCHAR(60)     NOT NULL DEFAULT 'India',
    CONSTRAINT pk_region PRIMARY KEY (region_id),
    CONSTRAINT uq_region_code UNIQUE (region_code)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 2. LOCATION : geo-coded node used by warehouses, suppliers, customers
-- ---------------------------------------------------------------------
CREATE TABLE location (
    location_id     INT             NOT NULL AUTO_INCREMENT,
    city            VARCHAR(60)     NOT NULL,
    state           VARCHAR(60)     NOT NULL,
    postal_code     VARCHAR(12)     NOT NULL,
    latitude        DECIMAL(9,6)    NOT NULL,
    longitude       DECIMAL(9,6)    NOT NULL,
    region_id       INT             NOT NULL,
    CONSTRAINT pk_location PRIMARY KEY (location_id),
    CONSTRAINT fk_location_region FOREIGN KEY (region_id)
        REFERENCES region (region_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_location_lat CHECK (latitude  BETWEEN  -90 AND  90),
    CONSTRAINT ck_location_lon CHECK (longitude BETWEEN -180 AND 180)
) ENGINE = InnoDB;

CREATE INDEX ix_location_region ON location (region_id);

-- ---------------------------------------------------------------------
-- 3. WAREHOUSE : physical facility (the decision variable of the model)
-- ---------------------------------------------------------------------
CREATE TABLE warehouse (
    warehouse_id            INT             NOT NULL AUTO_INCREMENT,
    warehouse_code          VARCHAR(12)     NOT NULL,
    warehouse_name          VARCHAR(80)     NOT NULL,
    location_id             INT             NOT NULL,
    warehouse_type          ENUM('CENTRAL_DC','REGIONAL_DC','FULFILMENT_CENTRE','CROSS_DOCK','DARK_STORE')
                                            NOT NULL DEFAULT 'REGIONAL_DC',
    storage_capacity_units  INT             NOT NULL,
    throughput_per_day      INT             NOT NULL,
    fixed_cost_monthly      DECIMAL(12,2)   NOT NULL,
    variable_cost_per_unit  DECIMAL(10,4)   NOT NULL,
    automation_level        ENUM('MANUAL','SEMI_AUTOMATED','AUTOMATED') NOT NULL DEFAULT 'SEMI_AUTOMATED',
    opened_date             DATE            NOT NULL,
    status                  ENUM('ACTIVE','INACTIVE','PROPOSED','CLOSED') NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT pk_warehouse PRIMARY KEY (warehouse_id),
    CONSTRAINT uq_warehouse_code UNIQUE (warehouse_code),
    CONSTRAINT fk_warehouse_location FOREIGN KEY (location_id)
        REFERENCES location (location_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_wh_capacity   CHECK (storage_capacity_units > 0),
    CONSTRAINT ck_wh_throughput CHECK (throughput_per_day    > 0)
) ENGINE = InnoDB;

CREATE INDEX ix_warehouse_status ON warehouse (status);

-- ---------------------------------------------------------------------
-- 4. WAREHOUSE_ZONE : storage zones inside a warehouse (weak entity)
-- ---------------------------------------------------------------------
CREATE TABLE warehouse_zone (
    zone_id         INT             NOT NULL AUTO_INCREMENT,
    warehouse_id    INT             NOT NULL,
    zone_code       VARCHAR(10)     NOT NULL,
    zone_type       ENUM('AMBIENT','COLD_CHAIN','FROZEN','HAZMAT','BULK','HIGH_VALUE')
                                    NOT NULL DEFAULT 'AMBIENT',
    capacity_units  INT             NOT NULL,
    temp_min_c      DECIMAL(5,2)    NULL,
    temp_max_c      DECIMAL(5,2)    NULL,
    CONSTRAINT pk_warehouse_zone PRIMARY KEY (zone_id),
    CONSTRAINT uq_zone_per_wh UNIQUE (warehouse_id, zone_code),
    CONSTRAINT fk_zone_warehouse FOREIGN KEY (warehouse_id)
        REFERENCES warehouse (warehouse_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT ck_zone_capacity CHECK (capacity_units > 0)
) ENGINE = InnoDB;

-- =====================================================================
-- MODULE 2 : PRODUCT & SUPPLY MASTER
-- =====================================================================

-- ---------------------------------------------------------------------
-- 5. PRODUCT_CATEGORY : self-referencing hierarchy
-- ---------------------------------------------------------------------
CREATE TABLE product_category (
    category_id         INT             NOT NULL AUTO_INCREMENT,
    category_name       VARCHAR(60)     NOT NULL,
    parent_category_id  INT             NULL,
    CONSTRAINT pk_product_category PRIMARY KEY (category_id),
    CONSTRAINT uq_category_name UNIQUE (category_name),
    CONSTRAINT fk_category_parent FOREIGN KEY (parent_category_id)
        REFERENCES product_category (category_id) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 6. PRODUCT : SKU master with logistics attributes
-- ---------------------------------------------------------------------
CREATE TABLE product (
    product_id      INT             NOT NULL AUTO_INCREMENT,
    sku             VARCHAR(20)     NOT NULL,
    product_name    VARCHAR(100)    NOT NULL,
    category_id     INT             NOT NULL,
    unit_weight_kg  DECIMAL(8,3)    NOT NULL,
    unit_volume_m3  DECIMAL(8,4)    NOT NULL,
    unit_cost       DECIMAL(10,2)   NOT NULL,
    unit_price      DECIMAL(10,2)   NOT NULL,
    shelf_life_days INT             NULL,
    storage_type    ENUM('AMBIENT','COLD_CHAIN','FROZEN','HAZMAT','HIGH_VALUE') NOT NULL DEFAULT 'AMBIENT',
    abc_class       CHAR(1)         NOT NULL DEFAULT 'C',
    is_hazmat       BOOLEAN         NOT NULL DEFAULT 0,
    CONSTRAINT pk_product PRIMARY KEY (product_id),
    CONSTRAINT uq_product_sku UNIQUE (sku),
    CONSTRAINT fk_product_category FOREIGN KEY (category_id)
        REFERENCES product_category (category_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_product_abc   CHECK (abc_class IN ('A','B','C')),
    CONSTRAINT ck_product_price CHECK (unit_price >= unit_cost),
    CONSTRAINT ck_product_wt    CHECK (unit_weight_kg > 0)
) ENGINE = InnoDB;

CREATE INDEX ix_product_category ON product (category_id);
CREATE INDEX ix_product_abc      ON product (abc_class);

-- ---------------------------------------------------------------------
-- 7. SUPPLIER : upstream source nodes
-- ---------------------------------------------------------------------
CREATE TABLE supplier (
    supplier_id         INT             NOT NULL AUTO_INCREMENT,
    supplier_code       VARCHAR(12)     NOT NULL,
    supplier_name       VARCHAR(90)     NOT NULL,
    location_id         INT             NOT NULL,
    contact_email       VARCHAR(100)    NULL,
    contact_phone       VARCHAR(20)     NULL,
    avg_lead_time_days  INT             NOT NULL DEFAULT 7,
    reliability_score   DECIMAL(4,2)    NOT NULL DEFAULT 90.00,
    is_active           BOOLEAN         NOT NULL DEFAULT 1,
    CONSTRAINT pk_supplier PRIMARY KEY (supplier_id),
    CONSTRAINT uq_supplier_code UNIQUE (supplier_code),
    CONSTRAINT fk_supplier_location FOREIGN KEY (location_id)
        REFERENCES location (location_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_supplier_reliability CHECK (reliability_score BETWEEN 0 AND 100)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 8. SUPPLIER_PRODUCT : M:N resolution (supplier supplies product)
-- ---------------------------------------------------------------------
CREATE TABLE supplier_product (
    supplier_id         INT             NOT NULL,
    product_id          INT             NOT NULL,
    unit_purchase_cost  DECIMAL(10,2)   NOT NULL,
    min_order_qty       INT             NOT NULL DEFAULT 1,
    lead_time_days      INT             NOT NULL DEFAULT 7,
    is_preferred        BOOLEAN         NOT NULL DEFAULT 0,
    CONSTRAINT pk_supplier_product PRIMARY KEY (supplier_id, product_id),
    CONSTRAINT fk_sp_supplier FOREIGN KEY (supplier_id)
        REFERENCES supplier (supplier_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_sp_product FOREIGN KEY (product_id)
        REFERENCES product (product_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT ck_sp_moq CHECK (min_order_qty > 0)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 9. CUSTOMER : demand nodes served by the network
-- ---------------------------------------------------------------------
CREATE TABLE customer (
    customer_id             INT             NOT NULL AUTO_INCREMENT,
    customer_code           VARCHAR(12)     NOT NULL,
    customer_name           VARCHAR(90)     NOT NULL,
    customer_type           ENUM('RETAIL','WHOLESALE','B2B','ECOMMERCE') NOT NULL DEFAULT 'RETAIL',
    location_id             INT             NOT NULL,
    priority_tier           ENUM('PLATINUM','GOLD','SILVER','BRONZE') NOT NULL DEFAULT 'SILVER',
    service_level_hours     INT             NOT NULL DEFAULT 48,
    credit_limit            DECIMAL(12,2)   NOT NULL DEFAULT 0.00,
    registered_on           DATE            NOT NULL,
    CONSTRAINT pk_customer PRIMARY KEY (customer_id),
    CONSTRAINT uq_customer_code UNIQUE (customer_code),
    CONSTRAINT fk_customer_location FOREIGN KEY (location_id)
        REFERENCES location (location_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_customer_sl CHECK (service_level_hours > 0)
) ENGINE = InnoDB;

CREATE INDEX ix_customer_location ON customer (location_id);

-- =====================================================================
-- MODULE 3 : INVENTORY
-- =====================================================================

-- ---------------------------------------------------------------------
-- 10. INVENTORY : stock position of a SKU at a warehouse
-- ---------------------------------------------------------------------
CREATE TABLE inventory (
    inventory_id        INT             NOT NULL AUTO_INCREMENT,
    warehouse_id        INT             NOT NULL,
    product_id          INT             NOT NULL,
    zone_id             INT             NULL,
    qty_on_hand         INT             NOT NULL DEFAULT 0,
    qty_reserved        INT             NOT NULL DEFAULT 0,
    qty_in_transit      INT             NOT NULL DEFAULT 0,
    qty_available       INT AS (qty_on_hand - qty_reserved) STORED,
    safety_stock        INT             NOT NULL DEFAULT 0,
    reorder_point       INT             NOT NULL DEFAULT 0,
    max_stock_level     INT             NOT NULL,
    avg_daily_demand    DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
    last_counted_date   DATE            NULL,
    CONSTRAINT pk_inventory PRIMARY KEY (inventory_id),
    CONSTRAINT uq_inventory_wh_product UNIQUE (warehouse_id, product_id),
    CONSTRAINT fk_inv_warehouse FOREIGN KEY (warehouse_id)
        REFERENCES warehouse (warehouse_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_inv_product FOREIGN KEY (product_id)
        REFERENCES product (product_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_inv_zone FOREIGN KEY (zone_id)
        REFERENCES warehouse_zone (zone_id) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT ck_inv_qty       CHECK (qty_on_hand >= 0 AND qty_reserved >= 0),
    CONSTRAINT ck_inv_max_level CHECK (max_stock_level >= reorder_point)
) ENGINE = InnoDB;

CREATE INDEX ix_inventory_product ON inventory (product_id);

-- ---------------------------------------------------------------------
-- 11. INVENTORY_TRANSACTION : immutable stock movement ledger
-- ---------------------------------------------------------------------
CREATE TABLE inventory_transaction (
    txn_id          BIGINT          NOT NULL AUTO_INCREMENT,
    inventory_id    INT             NOT NULL,
    txn_type        ENUM('INBOUND','OUTBOUND','TRANSFER_IN','TRANSFER_OUT','ADJUSTMENT','RETURN','DAMAGE')
                                    NOT NULL,
    quantity        INT             NOT NULL,
    txn_datetime    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reference_no    VARCHAR(30)     NULL,
    remarks         VARCHAR(200)    NULL,
    CONSTRAINT pk_inventory_transaction PRIMARY KEY (txn_id),
    CONSTRAINT fk_txn_inventory FOREIGN KEY (inventory_id)
        REFERENCES inventory (inventory_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT ck_txn_qty CHECK (quantity <> 0)
) ENGINE = InnoDB;

CREATE INDEX ix_txn_date ON inventory_transaction (txn_datetime);

-- =====================================================================
-- MODULE 4 : DEMAND, ORDERS & FULFILMENT
-- =====================================================================

-- ---------------------------------------------------------------------
-- 12. CUSTOMER_ORDER : order header
-- ---------------------------------------------------------------------
CREATE TABLE customer_order (
    order_id        INT             NOT NULL AUTO_INCREMENT,
    order_no        VARCHAR(20)     NOT NULL,
    customer_id     INT             NOT NULL,
    order_date      DATE            NOT NULL,
    required_date   DATE            NOT NULL,
    order_status    ENUM('NEW','ALLOCATED','PICKING','SHIPPED','DELIVERED','CANCELLED','BACKORDER')
                                    NOT NULL DEFAULT 'NEW',
    priority        ENUM('LOW','NORMAL','HIGH','URGENT') NOT NULL DEFAULT 'NORMAL',
    order_value     DECIMAL(12,2)   NOT NULL DEFAULT 0.00,
    CONSTRAINT pk_customer_order PRIMARY KEY (order_id),
    CONSTRAINT uq_order_no UNIQUE (order_no),
    CONSTRAINT fk_order_customer FOREIGN KEY (customer_id)
        REFERENCES customer (customer_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_order_dates CHECK (required_date >= order_date)
) ENGINE = InnoDB;

CREATE INDEX ix_order_date   ON customer_order (order_date);
CREATE INDEX ix_order_status ON customer_order (order_status);

-- ---------------------------------------------------------------------
-- 13. ORDER_LINE : order detail (weak entity of CUSTOMER_ORDER)
-- ---------------------------------------------------------------------
CREATE TABLE order_line (
    order_line_id   INT             NOT NULL AUTO_INCREMENT,
    order_id        INT             NOT NULL,
    product_id      INT             NOT NULL,
    quantity        INT             NOT NULL,
    unit_price      DECIMAL(10,2)   NOT NULL,
    discount_pct    DECIMAL(5,2)    NOT NULL DEFAULT 0.00,
    line_amount     DECIMAL(12,2) AS (quantity * unit_price * (1 - discount_pct / 100)) STORED,
    CONSTRAINT pk_order_line PRIMARY KEY (order_line_id),
    CONSTRAINT uq_order_line UNIQUE (order_id, product_id),
    CONSTRAINT fk_ol_order FOREIGN KEY (order_id)
        REFERENCES customer_order (order_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_ol_product FOREIGN KEY (product_id)
        REFERENCES product (product_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_ol_qty CHECK (quantity > 0),
    CONSTRAINT ck_ol_disc CHECK (discount_pct BETWEEN 0 AND 100)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 14. ORDER_FULFILMENT : which warehouse serves which order (allocation)
-- ---------------------------------------------------------------------
CREATE TABLE order_fulfilment (
    fulfilment_id       INT             NOT NULL AUTO_INCREMENT,
    order_id            INT             NOT NULL,
    warehouse_id        INT             NOT NULL,
    allocation_method   ENUM('NEAREST','LOWEST_COST','LOAD_BALANCED','OPTIMIZER','MANUAL')
                                        NOT NULL DEFAULT 'OPTIMIZER',
    allocated_on        DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dispatched_on       DATETIME        NULL,
    delivered_on        DATETIME        NULL,
    handling_cost       DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
    fulfilment_status   ENUM('PENDING','PARTIAL','COMPLETE','FAILED') NOT NULL DEFAULT 'PENDING',
    CONSTRAINT pk_order_fulfilment PRIMARY KEY (fulfilment_id),
    CONSTRAINT uq_fulfilment UNIQUE (order_id, warehouse_id),
    CONSTRAINT fk_of_order FOREIGN KEY (order_id)
        REFERENCES customer_order (order_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_of_warehouse FOREIGN KEY (warehouse_id)
        REFERENCES warehouse (warehouse_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 15. DEMAND_FORECAST : model output per warehouse-SKU-period
-- ---------------------------------------------------------------------
CREATE TABLE demand_forecast (
    forecast_id     INT             NOT NULL AUTO_INCREMENT,
    warehouse_id    INT             NOT NULL,
    product_id      INT             NOT NULL,
    period_start    DATE            NOT NULL,
    period_end      DATE            NOT NULL,
    forecast_qty    INT             NOT NULL,
    actual_qty      INT             NULL,
    model_used      ENUM('MOVING_AVG','EXP_SMOOTHING','ARIMA','SARIMA','LSTM','XGBOOST')
                                    NOT NULL DEFAULT 'ARIMA',
    mape_pct        DECIMAL(6,2)    NULL,
    generated_on    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_demand_forecast PRIMARY KEY (forecast_id),
    CONSTRAINT uq_forecast UNIQUE (warehouse_id, product_id, period_start),
    CONSTRAINT fk_df_warehouse FOREIGN KEY (warehouse_id)
        REFERENCES warehouse (warehouse_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_df_product FOREIGN KEY (product_id)
        REFERENCES product (product_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT ck_df_period CHECK (period_end > period_start),
    CONSTRAINT ck_df_qty    CHECK (forecast_qty >= 0)
) ENGINE = InnoDB;

-- =====================================================================
-- MODULE 5 : TRANSPORTATION NETWORK
-- =====================================================================

-- ---------------------------------------------------------------------
-- 16. CARRIER : logistics service providers
-- ---------------------------------------------------------------------
CREATE TABLE carrier (
    carrier_id      INT             NOT NULL AUTO_INCREMENT,
    carrier_code    VARCHAR(12)     NOT NULL,
    carrier_name    VARCHAR(80)     NOT NULL,
    transport_mode  ENUM('ROAD','RAIL','AIR','SEA','MULTIMODAL') NOT NULL DEFAULT 'ROAD',
    cost_per_km     DECIMAL(8,2)    NOT NULL,
    cost_per_kg     DECIMAL(8,2)    NOT NULL,
    avg_speed_kmph  DECIMAL(6,2)    NOT NULL,
    on_time_pct     DECIMAL(5,2)    NOT NULL DEFAULT 90.00,
    is_active       BOOLEAN         NOT NULL DEFAULT 1,
    CONSTRAINT pk_carrier PRIMARY KEY (carrier_id),
    CONSTRAINT uq_carrier_code UNIQUE (carrier_code),
    CONSTRAINT ck_carrier_ontime CHECK (on_time_pct BETWEEN 0 AND 100),
    CONSTRAINT ck_carrier_speed  CHECK (avg_speed_kmph > 0)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 17. VEHICLE : fleet owned/contracted by a carrier
-- ---------------------------------------------------------------------
CREATE TABLE vehicle (
    vehicle_id          INT             NOT NULL AUTO_INCREMENT,
    carrier_id          INT             NOT NULL,
    registration_no     VARCHAR(20)     NOT NULL,
    vehicle_type        ENUM('MINI_TRUCK','LCV','MCV','HCV','TRAILER','REEFER','CONTAINER')
                                        NOT NULL DEFAULT 'MCV',
    capacity_weight_kg  DECIMAL(10,2)   NOT NULL,
    capacity_volume_m3  DECIMAL(10,3)   NOT NULL,
    fuel_cost_per_km    DECIMAL(8,2)    NOT NULL,
    co2_g_per_km        DECIMAL(8,2)    NOT NULL DEFAULT 0.00,
    is_available        BOOLEAN         NOT NULL DEFAULT 1,
    CONSTRAINT pk_vehicle PRIMARY KEY (vehicle_id),
    CONSTRAINT uq_vehicle_reg UNIQUE (registration_no),
    CONSTRAINT fk_vehicle_carrier FOREIGN KEY (carrier_id)
        REFERENCES carrier (carrier_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT ck_vehicle_cap CHECK (capacity_weight_kg > 0 AND capacity_volume_m3 > 0)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 18. TRANSPORT_LANE : directed arc of the network graph (origin -> dest)
-- ---------------------------------------------------------------------
CREATE TABLE transport_lane (
    lane_id             INT             NOT NULL AUTO_INCREMENT,
    origin_location_id  INT             NOT NULL,
    dest_location_id    INT             NOT NULL,
    transport_mode      ENUM('ROAD','RAIL','AIR','SEA','MULTIMODAL') NOT NULL DEFAULT 'ROAD',
    distance_km         DECIMAL(9,2)    NOT NULL,
    transit_time_hours  DECIMAL(7,2)    NOT NULL,
    base_freight_cost   DECIMAL(10,2)   NOT NULL,
    toll_cost           DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
    congestion_index    DECIMAL(4,2)    NOT NULL DEFAULT 1.00,
    is_active           BOOLEAN         NOT NULL DEFAULT 1,
    CONSTRAINT pk_transport_lane PRIMARY KEY (lane_id),
    CONSTRAINT uq_lane UNIQUE (origin_location_id, dest_location_id, transport_mode),
    -- NOTE: these two FKs deliberately declare NO referential action.
    -- MySQL 8.0 forbids a column from appearing in both a CHECK constraint and
    -- a foreign key that carries ON UPDATE / ON DELETE actions (error 3823).
    -- location_id is a surrogate key that never changes, so CASCADE had no work
    -- to do here; omitting it keeps ck_lane_nodes legal. Default is NO ACTION,
    -- which InnoDB treats as RESTRICT.
    CONSTRAINT fk_lane_origin FOREIGN KEY (origin_location_id)
        REFERENCES location (location_id),
    CONSTRAINT fk_lane_dest FOREIGN KEY (dest_location_id)
        REFERENCES location (location_id),
    CONSTRAINT ck_lane_distance CHECK (distance_km > 0),
    CONSTRAINT ck_lane_nodes    CHECK (origin_location_id <> dest_location_id)
) ENGINE = InnoDB;

CREATE INDEX ix_lane_origin ON transport_lane (origin_location_id);
CREATE INDEX ix_lane_dest   ON transport_lane (dest_location_id);

-- ---------------------------------------------------------------------
-- 19. SHIPMENT : a physical consignment moving over a lane
-- ---------------------------------------------------------------------
CREATE TABLE shipment (
    shipment_id         INT             NOT NULL AUTO_INCREMENT,
    shipment_no         VARCHAR(20)     NOT NULL,
    lane_id             INT             NOT NULL,
    carrier_id          INT             NOT NULL,
    vehicle_id          INT             NULL,
    origin_warehouse_id INT             NOT NULL,
    dispatch_datetime   DATETIME        NOT NULL,
    eta_datetime        DATETIME        NOT NULL,
    actual_arrival      DATETIME        NULL,
    total_weight_kg     DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
    total_volume_m3     DECIMAL(10,3)   NOT NULL DEFAULT 0.000,
    freight_cost        DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
    shipment_status     ENUM('PLANNED','IN_TRANSIT','DELIVERED','DELAYED','CANCELLED')
                                        NOT NULL DEFAULT 'PLANNED',
    CONSTRAINT pk_shipment PRIMARY KEY (shipment_id),
    CONSTRAINT uq_shipment_no UNIQUE (shipment_no),
    CONSTRAINT fk_ship_lane FOREIGN KEY (lane_id)
        REFERENCES transport_lane (lane_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_ship_carrier FOREIGN KEY (carrier_id)
        REFERENCES carrier (carrier_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_ship_vehicle FOREIGN KEY (vehicle_id)
        REFERENCES vehicle (vehicle_id) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_ship_warehouse FOREIGN KEY (origin_warehouse_id)
        REFERENCES warehouse (warehouse_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_ship_eta CHECK (eta_datetime > dispatch_datetime)
) ENGINE = InnoDB;

CREATE INDEX ix_shipment_status ON shipment (shipment_status);

-- ---------------------------------------------------------------------
-- 20. SHIPMENT_LINE : order lines consolidated into a shipment (M:N)
-- ---------------------------------------------------------------------
CREATE TABLE shipment_line (
    shipment_line_id    INT             NOT NULL AUTO_INCREMENT,
    shipment_id         INT             NOT NULL,
    order_line_id       INT             NOT NULL,
    quantity_shipped    INT             NOT NULL,
    CONSTRAINT pk_shipment_line PRIMARY KEY (shipment_line_id),
    CONSTRAINT uq_shipment_line UNIQUE (shipment_id, order_line_id),
    CONSTRAINT fk_sl_shipment FOREIGN KEY (shipment_id)
        REFERENCES shipment (shipment_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_sl_order_line FOREIGN KEY (order_line_id)
        REFERENCES order_line (order_line_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_sl_qty CHECK (quantity_shipped > 0)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 21. STOCK_TRANSFER : inter-warehouse rebalancing recommended by optimizer
-- ---------------------------------------------------------------------
CREATE TABLE stock_transfer (
    transfer_id         INT             NOT NULL AUTO_INCREMENT,
    from_warehouse_id   INT             NOT NULL,
    to_warehouse_id     INT             NOT NULL,
    product_id          INT             NOT NULL,
    quantity            INT             NOT NULL,
    transfer_date       DATE            NOT NULL,
    shipment_id         INT             NULL,
    transfer_cost       DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
    transfer_status     ENUM('REQUESTED','APPROVED','IN_TRANSIT','RECEIVED','CANCELLED')
                                        NOT NULL DEFAULT 'REQUESTED',
    CONSTRAINT pk_stock_transfer PRIMARY KEY (transfer_id),
    -- No referential action, for the same reason as transport_lane above:
    -- these columns are named in ck_st_nodes (from <> to).
    CONSTRAINT fk_st_from FOREIGN KEY (from_warehouse_id)
        REFERENCES warehouse (warehouse_id),
    CONSTRAINT fk_st_to FOREIGN KEY (to_warehouse_id)
        REFERENCES warehouse (warehouse_id),
    CONSTRAINT fk_st_product FOREIGN KEY (product_id)
        REFERENCES product (product_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_st_shipment FOREIGN KEY (shipment_id)
        REFERENCES shipment (shipment_id) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT ck_st_qty   CHECK (quantity > 0),
    CONSTRAINT ck_st_nodes CHECK (from_warehouse_id <> to_warehouse_id)
) ENGINE = InnoDB;

-- =====================================================================
-- MODULE 6 : OPTIMIZATION ENGINE
-- =====================================================================

-- ---------------------------------------------------------------------
-- 22. OPTIMIZATION_SCENARIO : what-if parameter set
-- ---------------------------------------------------------------------
CREATE TABLE optimization_scenario (
    scenario_id             INT             NOT NULL AUTO_INCREMENT,
    scenario_name           VARCHAR(80)     NOT NULL,
    description             VARCHAR(255)    NULL,
    planning_horizon_days   INT             NOT NULL DEFAULT 90,
    demand_growth_pct       DECIMAL(6,2)    NOT NULL DEFAULT 0.00,
    fuel_price_index        DECIMAL(6,3)    NOT NULL DEFAULT 1.000,
    max_warehouses_allowed  INT             NULL,
    service_level_target    DECIMAL(5,2)    NOT NULL DEFAULT 95.00,
    created_on              DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_optimization_scenario PRIMARY KEY (scenario_id),
    CONSTRAINT uq_scenario_name UNIQUE (scenario_name),
    CONSTRAINT ck_scn_horizon CHECK (planning_horizon_days > 0)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 23. OPTIMIZATION_RUN : one execution of a solver on a scenario
-- ---------------------------------------------------------------------
CREATE TABLE optimization_run (
    run_id              INT             NOT NULL AUTO_INCREMENT,
    scenario_id         INT             NOT NULL,
    run_label           VARCHAR(80)     NOT NULL,
    objective           ENUM('MIN_TOTAL_COST','MIN_LEAD_TIME','MIN_CO2','MAX_SERVICE_LEVEL','MULTI_OBJECTIVE')
                                        NOT NULL DEFAULT 'MIN_TOTAL_COST',
    algorithm           ENUM('MILP','GENETIC_ALGORITHM','SIMULATED_ANNEALING','PARTICLE_SWARM','GREEDY_HEURISTIC','K_MEANS_CLUSTERING')
                                        NOT NULL DEFAULT 'MILP',
    run_datetime        DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    baseline_cost       DECIMAL(14,2)   NOT NULL,
    optimized_cost      DECIMAL(14,2)   NOT NULL,
    savings_pct         DECIMAL(6,2) AS (
                            CASE WHEN baseline_cost = 0 THEN 0
                                 ELSE (baseline_cost - optimized_cost) / baseline_cost * 100 END
                        ) STORED,
    iterations          INT             NOT NULL DEFAULT 0,
    runtime_seconds     DECIMAL(9,3)    NOT NULL DEFAULT 0.000,
    run_status          ENUM('QUEUED','RUNNING','CONVERGED','INFEASIBLE','FAILED') NOT NULL DEFAULT 'CONVERGED',
    CONSTRAINT pk_optimization_run PRIMARY KEY (run_id),
    CONSTRAINT fk_run_scenario FOREIGN KEY (scenario_id)
        REFERENCES optimization_scenario (scenario_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT ck_run_costs CHECK (baseline_cost >= 0 AND optimized_cost >= 0)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 24. OPTIMIZATION_RESULT : per-node recommendation produced by a run
-- ---------------------------------------------------------------------
CREATE TABLE optimization_result (
    result_id           INT             NOT NULL AUTO_INCREMENT,
    run_id              INT             NOT NULL,
    warehouse_id        INT             NOT NULL,
    product_id          INT             NULL,
    recommended_action  ENUM('KEEP_OPEN','CLOSE_FACILITY','OPEN_NEW','INCREASE_STOCK','REDUCE_STOCK','REALLOCATE','RE_ROUTE')
                                        NOT NULL,
    recommended_qty     INT             NULL,
    projected_saving    DECIMAL(12,2)   NOT NULL DEFAULT 0.00,
    confidence_score    DECIMAL(5,2)    NOT NULL DEFAULT 80.00,
    rationale           VARCHAR(255)    NULL,
    CONSTRAINT pk_optimization_result PRIMARY KEY (result_id),
    CONSTRAINT fk_res_run FOREIGN KEY (run_id)
        REFERENCES optimization_run (run_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_res_warehouse FOREIGN KEY (warehouse_id)
        REFERENCES warehouse (warehouse_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_res_product FOREIGN KEY (product_id)
        REFERENCES product (product_id) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT ck_res_conf CHECK (confidence_score BETWEEN 0 AND 100)
) ENGINE = InnoDB;

CREATE INDEX ix_result_run ON optimization_result (run_id);

-- ---------------------------------------------------------------------
-- 25. KPI_SNAPSHOT : periodic performance measurement per warehouse
-- ---------------------------------------------------------------------
CREATE TABLE kpi_snapshot (
    snapshot_id             INT             NOT NULL AUTO_INCREMENT,
    warehouse_id            INT             NOT NULL,
    snapshot_date           DATE            NOT NULL,
    inventory_turnover      DECIMAL(7,2)    NOT NULL,
    order_fill_rate_pct     DECIMAL(5,2)    NOT NULL,
    on_time_delivery_pct    DECIMAL(5,2)    NOT NULL,
    capacity_utilization_pct DECIMAL(5,2)   NOT NULL,
    cost_per_order          DECIMAL(10,2)   NOT NULL,
    carrying_cost           DECIMAL(12,2)   NOT NULL,
    CONSTRAINT pk_kpi_snapshot PRIMARY KEY (snapshot_id),
    CONSTRAINT uq_kpi UNIQUE (warehouse_id, snapshot_date),
    CONSTRAINT fk_kpi_warehouse FOREIGN KEY (warehouse_id)
        REFERENCES warehouse (warehouse_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT ck_kpi_rates CHECK (order_fill_rate_pct BETWEEN 0 AND 100
                               AND on_time_delivery_pct BETWEEN 0 AND 100)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 26. APP_USER : system users and their warehouse scope
-- ---------------------------------------------------------------------
CREATE TABLE app_user (
    user_id         INT             NOT NULL AUTO_INCREMENT,
    username        VARCHAR(40)     NOT NULL,
    full_name       VARCHAR(80)     NOT NULL,
    email           VARCHAR(100)    NOT NULL,
    password_hash   VARCHAR(255)    NOT NULL,
    user_role       ENUM('ADMIN','NETWORK_PLANNER','WAREHOUSE_MANAGER','ANALYST','VIEWER')
                                    NOT NULL DEFAULT 'VIEWER',
    warehouse_id    INT             NULL,
    is_active       BOOLEAN         NOT NULL DEFAULT 1,
    created_on      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_app_user PRIMARY KEY (user_id),
    CONSTRAINT uq_username UNIQUE (username),
    CONSTRAINT uq_user_email UNIQUE (email),
    CONSTRAINT fk_user_warehouse FOREIGN KEY (warehouse_id)
        REFERENCES warehouse (warehouse_id) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE = InnoDB;

-- =====================================================================
-- VIEWS : denormalised reporting layer
-- =====================================================================

CREATE OR REPLACE VIEW v_warehouse_master AS
SELECT  w.warehouse_id,
        w.warehouse_code,
        w.warehouse_name,
        w.warehouse_type,
        w.status,
        l.city,
        l.state,
        r.region_name,
        w.storage_capacity_units,
        w.fixed_cost_monthly
FROM    warehouse w
JOIN    location  l ON l.location_id = w.location_id
JOIN    region    r ON r.region_id   = l.region_id;

CREATE OR REPLACE VIEW v_stock_health AS
SELECT  i.inventory_id,
        w.warehouse_code,
        p.sku,
        p.product_name,
        p.abc_class,
        i.qty_on_hand,
        i.qty_reserved,
        i.qty_available,
        i.reorder_point,
        i.safety_stock,
        CASE
            WHEN i.qty_available <= i.safety_stock  THEN 'CRITICAL'
            WHEN i.qty_available <= i.reorder_point THEN 'REORDER'
            WHEN i.qty_on_hand   >= i.max_stock_level THEN 'OVERSTOCK'
            ELSE 'HEALTHY'
        END AS stock_status
FROM    inventory i
JOIN    warehouse w ON w.warehouse_id = i.warehouse_id
JOIN    product   p ON p.product_id   = i.product_id;

CREATE OR REPLACE VIEW v_lane_cost_profile AS
SELECT  tl.lane_id,
        lo.city AS origin_city,
        ld.city AS dest_city,
        tl.transport_mode,
        tl.distance_km,
        tl.transit_time_hours,
        (tl.base_freight_cost + tl.toll_cost) * tl.congestion_index AS effective_lane_cost,
        ROUND((tl.base_freight_cost + tl.toll_cost) * tl.congestion_index / tl.distance_km, 2)
            AS cost_per_km
FROM    transport_lane tl
JOIN    location lo ON lo.location_id = tl.origin_location_id
JOIN    location ld ON ld.location_id = tl.dest_location_id;

-- =====================================================================
-- END OF DDL
-- =====================================================================
