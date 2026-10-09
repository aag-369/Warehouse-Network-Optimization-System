# Warehouse Network Optimization System (WNOS)
## Database Design Document — Proposed Model

**Author:** Aayushman Ghatak
**RDBMS:** MySQL 8.0 (InnoDB, `utf8mb4_unicode_ci`)
**Schema:** `wnos`
**Scale of model:** 26 entities · 39 relationships · 3 views · 7 functional modules

---

## 1. Problem Statement

A multi-echelon distribution network carries three cost blocks that pull against each other:

| Cost block | Falls when you… | Rises when you… |
|---|---|---|
| Facility (fixed + handling) | operate fewer, larger warehouses | open more nodes |
| Transportation (freight) | operate more nodes close to demand | centralise |
| Inventory carrying | centralise (risk pooling) | decentralise |

Adding a warehouse cuts freight but adds fixed cost and fragments safety stock. Closing one does the reverse. The Warehouse Network Optimization System is the database and analytics layer that lets a planner answer, with evidence rather than intuition:

- **How many** warehouses should the network have, and **where**?
- **Which** warehouse should serve **which** customer order?
- **How much** of **which** SKU should sit at **each** node?
- **Which lane and mode** should each shipment move on?

## 2. Objectives

1. Model the complete physical network — facilities, zones, SKUs, suppliers, customers, lanes, carriers and fleet — in a normalised relational schema.
2. Maintain a live, auditable inventory position per warehouse-SKU with an immutable movement ledger.
3. Capture demand forecasts and their realised accuracy so the optimizer runs on projected, not historical, demand.
4. Store optimization scenarios, runs and per-node recommendations so results are reproducible and comparable across algorithms.
5. Expose the network's objective function — total cost — as a single queryable roll-up.

## 3. Objective Function

```
Minimise  Z = Σ (fixed facility cost)          for every open warehouse
            + Σ (variable handling cost × units processed)
            + Σ (freight cost of every lane-mode-shipment)
            + Σ (inventory carrying cost = value × holding rate)

Subject to:  demand at every customer node is met
             units stored ≤ warehouse storage capacity
             units processed/day ≤ warehouse throughput
             shipment weight ≤ vehicle capacity_weight_kg
             shipment volume ≤ vehicle capacity_volume_m3
             delivery lead time ≤ customer service_level_hours
             qty_on_hand ≥ safety_stock at all times
```

Query **Q20** in `03_analysis_queries.sql` evaluates `Z` directly from the live tables.

---

## 4. Module Map

| # | Module | Entities |
|---|---|---|
| 1 | Geography & Network Master | `region`, `location`, `warehouse`, `warehouse_zone` |
| 2 | Product & Supply Master | `product_category`, `product`, `supplier`, `supplier_product`, `customer` |
| 3 | Inventory | `inventory`, `inventory_transaction` |
| 4 | Demand, Orders & Fulfilment | `customer_order`, `order_line`, `order_fulfilment`, `demand_forecast` |
| 5 | Transportation Network | `carrier`, `vehicle`, `transport_lane`, `shipment`, `shipment_line`, `stock_transfer` |
| 6 | Optimization Engine | `optimization_scenario`, `optimization_run`, `optimization_result`, `kpi_snapshot` |
| 7 | Security | `app_user` |

---

## 5. Relationship / Cardinality Matrix

| Parent | Child | Cardinality | Meaning |
|---|---|---|---|
| region | location | 1 : N | a region contains many locations |
| location | warehouse | 1 : N | a warehouse is sited at one location |
| location | supplier | 1 : N | a supplier is located at one location |
| location | customer | 1 : N | a customer is located at one location |
| location | transport_lane | 1 : N (twice) | a lane has one origin and one destination |
| warehouse | warehouse_zone | 1 : N | a warehouse is divided into storage zones |
| warehouse | inventory | 1 : N | a warehouse stocks many SKUs |
| warehouse | order_fulfilment | 1 : N | a warehouse serves many orders |
| warehouse | demand_forecast | 1 : N | forecasts are generated per warehouse-SKU |
| warehouse | shipment | 1 : N | shipments are despatched from a warehouse |
| warehouse | stock_transfer | 1 : N (twice) | source and destination of a transfer |
| warehouse | kpi_snapshot | 1 : N | monthly KPI readings per warehouse |
| warehouse | optimization_result | 1 : N | recommendations target a warehouse |
| warehouse | app_user | 1 : N (optional) | a user may be scoped to one warehouse |
| product_category | product_category | 1 : N (recursive) | category hierarchy |
| product_category | product | 1 : N | a SKU belongs to one category |
| product | inventory | 1 : N | a SKU is stocked at many warehouses |
| product | order_line, demand_forecast, stock_transfer | 1 : N | |
| supplier ↔ product | supplier_product | M : N | resolved by a junction table |
| warehouse ↔ product | inventory | M : N | resolved with stock attributes |
| customer | customer_order | 1 : N | |
| customer_order | order_line | 1 : N | weak entity, identifying relationship |
| customer_order | order_fulfilment | 1 : N | an order can be split across warehouses |
| order_line ↔ shipment | shipment_line | M : N | order lines consolidated into shipments |
| carrier | vehicle | 1 : N | |
| carrier | shipment | 1 : N | |
| vehicle | shipment | 1 : N (optional) | |
| transport_lane | shipment | 1 : N | |
| shipment | stock_transfer | 1 : N (optional) | |
| optimization_scenario | optimization_run | 1 : N | |
| optimization_run | optimization_result | 1 : N | |

---

## 6. Table Reference with Sample Values

### 6.1 `region` — 5 rows

| Column | Type | Key | Notes |
|---|---|---|---|
| region_id | INT | PK | AUTO_INCREMENT |
| region_code | VARCHAR(10) | UQ | |
| region_name | VARCHAR(60) | | |
| country | VARCHAR(60) | | default `'India'` |

| region_id | region_code | region_name | country |
|---|---|---|---|
| 1 | NR | Northern Region | India |
| 2 | WR | Western Region | India |
| 3 | SR | Southern Region | India |
| 4 | ER | Eastern Region | India |
| 5 | CR | Central Region | India |

---

### 6.2 `location` — 15 rows

| Column | Type | Key | Notes |
|---|---|---|---|
| location_id | INT | PK | |
| city / state | VARCHAR(60) | | |
| postal_code | VARCHAR(12) | | |
| latitude | DECIMAL(9,6) | | CHECK −90 … 90 |
| longitude | DECIMAL(9,6) | | CHECK −180 … 180 |
| region_id | INT | FK → region | |

| location_id | city | state | latitude | longitude | region_id |
|---|---|---|---|---|---|
| 1 | Delhi | Delhi | 28.613900 | 77.209000 | 1 |
| 4 | Mumbai | Maharashtra | 19.076000 | 72.877700 | 2 |
| 7 | Bengaluru | Karnataka | 12.971600 | 77.594600 | 3 |
| 9 | Hyderabad | Telangana | 17.385000 | 78.486700 | 3 |
| 10 | Kolkata | West Bengal | 22.572600 | 88.363900 | 4 |
| 13 | Nagpur | Maharashtra | 21.145800 | 79.088200 | 5 |
| 14 | Indore | Madhya Pradesh | 22.719600 | 75.857700 | 5 |

*(full 15 rows in `02_sample_data_dml.sql`)*

The lat/long pair is what makes the **centre-of-gravity** (Q11) and **Haversine nearest-warehouse** (Q12) queries possible.

---

### 6.3 `warehouse` — 8 rows

| Column | Type | Key | Notes |
|---|---|---|---|
| warehouse_id | INT | PK | |
| warehouse_code | VARCHAR(12) | UQ | |
| location_id | INT | FK → location | |
| warehouse_type | ENUM | | CENTRAL_DC / REGIONAL_DC / FULFILMENT_CENTRE / CROSS_DOCK / DARK_STORE |
| storage_capacity_units | INT | | CHECK > 0 |
| throughput_per_day | INT | | CHECK > 0 |
| fixed_cost_monthly | DECIMAL(12,2) | | the *y·f* term of the objective |
| variable_cost_per_unit | DECIMAL(10,4) | | |
| status | ENUM | | ACTIVE / INACTIVE / PROPOSED / CLOSED |

| code | name | type | capacity | throughput | fixed cost/mo | status |
|---|---|---|---|---|---|---|
| WH-DEL-01 | Delhi Central DC | CENTRAL_DC | 95,000 | 12,000 | 4,500,000.00 | ACTIVE |
| WH-MUM-01 | Mumbai Regional DC | REGIONAL_DC | 32,000 | 4,000 | 5,200,000.00 | ACTIVE |
| WH-BLR-01 | Bengaluru Fulfilment Centre | FULFILMENT_CENTRE | 55,000 | 7,500 | 3,900,000.00 | ACTIVE |
| WH-KOL-01 | Kolkata Regional DC | REGIONAL_DC | 45,000 | 5,500 | 2,750,000.00 | ACTIVE |
| WH-NAG-01 | Nagpur Cross-Dock Hub | CROSS_DOCK | 22,000 | 6,500 | 1,400,000.00 | INACTIVE¹ |
| WH-HYD-01 | Hyderabad Fulfilment Centre | FULFILMENT_CENTRE | 48,000 | 6,000 | 3,300,000.00 | ACTIVE |
| WH-GUW-01 | Guwahati Dark Store | DARK_STORE | 12,000 | 1,500 | 620,000.00 | ACTIVE |
| WH-IDR-01 | Indore Regional DC (Proposed) | REGIONAL_DC | 40,000 | 5,000 | 1,950,000.00 | PROPOSED |

¹ Loaded as `ACTIVE`; the post-load `UPDATE` in the DML flips it to `INACTIVE` because three converged optimizer runs independently recommended `CLOSE_FACILITY` for it. This is the schema demonstrating a decision, not a typo.

---

### 6.4 `warehouse_zone` — 17 rows

Weak entity: `UNIQUE (warehouse_id, zone_code)`, `ON DELETE CASCADE`.

| zone_id | warehouse_id | zone_code | zone_type | capacity_units | temp range °C |
|---|---|---|---|---|---|
| 1 | 1 | A1 | AMBIENT | 150,000 | 15 – 30 |
| 2 | 1 | C1 | COLD_CHAIN | 50,000 | 2 – 8 |
| 3 | 1 | H1 | HAZMAT | 20,000 | 15 – 28 |
| 4 | 1 | V1 | HIGH_VALUE | 30,000 | 18 – 26 |
| 10 | 3 | F1 | FROZEN | 20,000 | −22 – −18 |

---

### 6.5 `product` — 15 rows

| sku | product_name | category | weight kg | volume m³ | cost | price | storage | ABC |
|---|---|---|---|---|---|---|---|---|
| SKU-EL-1001 | 4K Smart LED TV 55" | Electronics | 18.500 | 0.2200 | 32,000.00 | 41,999.00 | AMBIENT | A |
| SKU-MB-1002 | Smartphone 5G 128GB | Mobile Devices | 0.220 | 0.0015 | 14,500.00 | 19,999.00 | HIGH_VALUE | A |
| SKU-FM-1006 | Sunflower Refined Oil 5L | Packaged Foods | 4.800 | 0.0060 | 620.00 | 799.00 | AMBIENT | A |
| SKU-FM-1008 | Frozen Green Peas 1kg | Packaged Foods | 1.050 | 0.0018 | 95.00 | 149.00 | FROZEN | C |
| SKU-PH-1010 | Insulin Vial 10ml | Cold Chain Pharma | 0.090 | 0.0003 | 380.00 | 620.00 | COLD_CHAIN | A |
| SKU-IS-1013 | Hydraulic Oil 20L Drum | Industrial Spares | 18.000 | 0.0250 | 2,400.00 | 3,200.00 | HAZMAT | B |
| SKU-EL-1015 | Laptop 14" i5 16GB | Electronics | 1.450 | 0.0090 | 48,000.00 | 62,999.00 | HIGH_VALUE | A |

`unit_weight_kg` and `unit_volume_m3` are what let a shipment be checked against a vehicle's weight **and** cube capacity — the classic two-constraint loading problem (Q24).

**Constraints:** `CHECK (unit_price >= unit_cost)`, `CHECK (abc_class IN ('A','B','C'))`, `CHECK (unit_weight_kg > 0)`.

---

### 6.6 `supplier` (6) and `supplier_product` (18)

`supplier_product` is the M:N resolution with a composite primary key `(supplier_id, product_id)`.

| supplier | product | unit_purchase_cost | MOQ | lead_time_days | preferred |
|---|---|---|---|---|---|
| Aurora Electronics | SKU-EL-1001 | 32,000.00 | 20 | 10 | Yes |
| Coromandel Appliance Works | SKU-EL-1001 | 32,500.00 | 15 | 16 | No |
| Sahyadri FMCG | SKU-FM-1006 | 620.00 | 200 | 5 | Yes |
| Punjab Agro Foods | SKU-FM-1006 | 635.00 | 180 | 6 | No |
| Deccan Pharma Labs | SKU-PH-1010 | 380.00 | 100 | 6 | Yes |

Two suppliers for the same SKU at different prices is what makes the supplier scorecard (Q17) non-trivial.

---

### 6.7 `customer` — 12 rows

| customer_code | customer_name | type | city | tier | SLA hrs | credit limit |
|---|---|---|---|---|---|---|
| CUS-0001 | Metro Retail Hypermart | RETAIL | Delhi | PLATINUM | 24 | 5,000,000.00 |
| CUS-0003 | QuickCart Ecommerce | ECOMMERCE | Gurugram | PLATINUM | 12 | 8,000,000.00 |
| CUS-0005 | Pune Pharma Chain | B2B | Pune | PLATINUM | 12 | 4,200,000.00 |
| CUS-0011 | Brahmaputra Stores | RETAIL | Guwahati | BRONZE | 96 | 600,000.00 |

`service_level_hours` is the SLA the optimizer must respect when choosing a source warehouse; Q22 audits breaches against it.

---

### 6.8 `inventory` — 32 rows

| Column | Type | Notes |
|---|---|---|
| inventory_id | INT | PK |
| warehouse_id, product_id | INT | FK; `UNIQUE (warehouse_id, product_id)` |
| zone_id | INT | FK, nullable, `ON DELETE SET NULL` |
| qty_on_hand / qty_reserved / qty_in_transit | INT | |
| **qty_available** | INT | **GENERATED STORED** = `qty_on_hand − qty_reserved` |
| safety_stock / reorder_point / max_stock_level | INT | `CHECK (max_stock_level >= reorder_point)` |
| avg_daily_demand | DECIMAL(10,2) | feeds the ROP and EOQ formulas |

| warehouse | sku | on_hand | reserved | available | safety | ROP | max | avg daily |
|---|---|---|---|---|---|---|---|---|
| WH-DEL-01 | SKU-EL-1001 | 380 | 120 | **260** | 150 | 300 | 1,200 | 42.50 |
| WH-DEL-01 | SKU-FM-1006 | 17,000 | 1,500 | 15,500 | 2,500 | 5,000 | 18,000 | 720.00 |
| WH-DEL-01 | SKU-PH-1009 | 36,000 | 2,000 | 34,000 | 5,000 | 9,000 | 40,000 | 1,250.00 |
| WH-MUM-01 | SKU-PH-1010 | 1,600 | 500 | **1,100** | 900 | 1,800 | 6,500 | 210.00 |
| WH-KOL-01 | SKU-PH-1010 | 550 | 220 | **330** | 400 | 850 | 3,000 | 96.00 |
| WH-NAG-01 | SKU-FM-1006 | 1,600 | 800 | **800** | 600 | 1,400 | 5,000 | 410.00 |
| WH-GUW-01 | SKU-PH-1009 | 1,800 | 400 | **1,400** | 1,000 | 1,900 | 7,500 | 240.00 |

Rows in bold are below their reorder point and are exactly the 5 rows returned by **Q3**; `WH-KOL-01 / SKU-PH-1010` is below safety stock and is flagged `CRITICAL`.

---

### 6.9 `inventory_transaction` — 22 rows

Immutable ledger. Signed `quantity` (`CHECK quantity <> 0`), so a stock position can always be reconstructed by replay.

| txn_id | inventory_id | txn_type | quantity | txn_datetime | reference_no |
|---|---|---|---|---|---|
| 1 | 4 | INBOUND | +6,000 | 2026-07-01 08:15 | PO-2026-0451 |
| 3 | 2 | OUTBOUND | −300 | 2026-07-03 19:20 | ORD-2026-0002 |
| 8 | 4 | TRANSFER_OUT | −2,000 | 2026-07-08 04:10 | STO-2026-0011 |
| 9 | 23 | TRANSFER_IN | +2,000 | 2026-07-09 06:30 | STO-2026-0011 |
| 21 | 17 | DAMAGE | −85 | 2026-07-14 12:00 | ADJ-2026-0007 |
| 22 | 25 | ADJUSTMENT | +120 | 2026-07-18 16:20 | ADJ-2026-0008 |

Note the matched `TRANSFER_OUT` / `TRANSFER_IN` pair under one reference — an inter-warehouse move is double-entry.

---

### 6.10 `customer_order` (12) and `order_line` (27)

`order_line.line_amount` is a **generated column**: `quantity × unit_price × (1 − discount_pct/100)`.
`customer_order.order_value` is then derived by a post-load `UPDATE … JOIN` so the header always agrees with its lines.

| order_no | customer | order_date | required | status | priority | order_value |
|---|---|---|---|---|---|---|
| ORD-2026-0001 | Metro Retail Hypermart | 2026-07-02 | 2026-07-04 | DELIVERED | HIGH | 5,435,821.60 |
| ORD-2026-0002 | QuickCart Ecommerce | 2026-07-03 | 2026-07-04 | DELIVERED | URGENT | 7,249,258.00 |
| ORD-2026-0004 | Pune Pharma Chain | 2026-07-06 | 2026-07-07 | DELIVERED | URGENT | 1,052,591.25 |
| ORD-2026-0005 | Silicon Valley Electronics | 2026-07-08 | 2026-07-10 | SHIPPED | HIGH | 4,771,451.20 |
| ORD-2026-0011 | Sabarmati Distributors | 2026-07-17 | 2026-07-22 | BACKORDER | LOW | 3,397,922.93 |
| ORD-2026-0012 | Marina Mega Stores | 2026-07-18 | 2026-07-21 | NEW | HIGH | 1,751,271.88 |

*(order_value starts at 0.00 and is derived at load time by the post-load `UPDATE`; the figures above are what MySQL computes. Total order revenue across all 12 orders: **₹32,346,097.21**.)*

Sample lines for `ORD-2026-0002`:

| order_line_id | product | qty | unit_price | disc % | line_amount |
|---|---|---|---|---|---|
| 4 | SKU-MB-1002 | 300 | 19,999.00 | 6.00 | 5,639,718.00 |
| 5 | SKU-MB-1003 | 500 | 3,499.00 | 8.00 | 1,609,540.00 |

**Constraints:** `CHECK (required_date >= order_date)`, `CHECK (quantity > 0)`, `CHECK (discount_pct BETWEEN 0 AND 100)`, `UNIQUE (order_id, product_id)`.

---

### 6.11 `order_fulfilment` — 12 rows

This is the allocation decision — *which warehouse serves this order* — and the column that records **how** the decision was made.

| order_no | warehouse | allocation_method | dispatched_on | delivered_on | handling_cost | status |
|---|---|---|---|---|---|---|
| ORD-2026-0001 | WH-DEL-01 | OPTIMIZER | 2026-07-02 17:55 | 2026-07-03 14:20 | 18,500.00 | COMPLETE |
| ORD-2026-0003 | WH-MUM-01 | NEAREST | 2026-07-05 16:30 | 2026-07-07 11:45 | 9,800.00 | COMPLETE |
| ORD-2026-0004 | WH-MUM-01 | LOWEST_COST | 2026-07-06 14:30 | 2026-07-06 21:05 | 11,200.00 | COMPLETE |
| ORD-2026-0007 | WH-KOL-01 | LOAD_BALANCED | — | — | 0.00 | PENDING |
| ORD-2026-0008 | WH-KOL-01 | OPTIMIZER | 2026-07-15 06:00 | — | 7,400.00 | PARTIAL |

Order 8 is a Guwahati customer served from **Kolkata**, not from the local dark store — the optimizer's own recommendation (`optimization_result` #4) is to raise Guwahati stock so that stops happening.

---

### 6.12 `demand_forecast` — 16 rows

| warehouse | sku | period | forecast | actual | model | MAPE % |
|---|---|---|---|---|---|---|
| WH-DEL-01 | SKU-PH-1009 | Jul 2026 | 38,000 | 36,940 | LSTM | 2.79 |
| WH-HYD-01 | SKU-PH-1009 | Jul 2026 | 31,000 | 30,150 | LSTM | 2.74 |
| WH-BLR-01 | SKU-MB-1003 | Jul 2026 | 6,200 | 5,980 | EXP_SMOOTHING | 3.55 |
| WH-KOL-01 | SKU-IS-1012 | Jul 2026 | 19,500 | 20,310 | ARIMA | 4.16 |
| WH-GUW-01 | SKU-PH-1009 | Jul 2026 | 7,300 | 7,810 | MOVING_AVG | 6.99 |
| WH-DEL-01 | SKU-MB-1002 | Aug 2026 | 5,900 | *NULL* | SARIMA | *NULL* |

Rows with `actual_qty IS NULL` are open forecasts. Q10 aggregates the closed ones:

| model | forecasts | avg MAPE % |
|---|---|---|
| LSTM | 3 | 3.27 |
| EXP_SMOOTHING | 1 | 3.55 |
| XGBOOST | 2 | 3.68 |
| ARIMA | 4 | 4.20 |
| SARIMA | 2 | 4.54 |
| MOVING_AVG | 2 | 5.16 |

---

### 6.13 `carrier` (5) and `vehicle` (10)

| carrier_code | carrier_name | mode | cost/km | cost/kg | speed kmph | on-time % |
|---|---|---|---|---|---|---|
| CAR-BLU | BlueDart Surface Express | ROAD | 42.50 | 8.90 | 55.00 | 94.20 |
| CAR-GAT | Gati Multimodal Logistics | MULTIMODAL | 36.80 | 6.40 | 48.00 | 89.60 |
| CAR-CON | Concor Rail Freight | RAIL | 18.20 | 3.75 | 40.00 | 86.30 |
| CAR-AIR | SpiceXpress Air Cargo | AIR | 168.00 | 62.50 | 720.00 | 91.80 |
| CAR-VRL | VRL Roadlines | ROAD | 38.90 | 7.20 | 52.00 | 88.10 |

| registration_no | type | capacity kg | capacity m³ | fuel cost/km | CO₂ g/km |
|---|---|---|---|---|---|
| DL01AB1234 | HCV | 16,000.00 | 48.000 | 22.50 | 780.00 |
| MH12CD4321 | TRAILER | 25,000.00 | 76.000 | 31.40 | 1,120.00 |
| MH12CD8765 | REEFER | 12,000.00 | 36.000 | 26.90 | 910.00 |
| KA05EF1111 | CONTAINER | 30,000.00 | 90.000 | 12.60 | 420.00 |

`co2_g_per_km` is what makes the `MIN_CO2` objective (scenario 4) computable rather than decorative.

---

### 6.14 `transport_lane` — 22 rows

Each row is a **directed arc** of the network graph. `UNIQUE (origin, dest, transport_mode)` allows the same city pair to exist once per mode, which is what turns mode selection into a real choice.

| lane_id | origin → dest | mode | distance km | transit hrs | base freight | toll | congestion |
|---|---|---|---|---|---|---|---|
| 3 | Delhi → Mumbai | ROAD | 1,420.00 | 34.00 | 68,500.00 | 4,200.00 | 1.15 |
| 17 | Delhi → Mumbai | RAIL | 1,385.00 | 42.00 | 38,900.00 | 0.00 | 1.00 |
| 4 | Delhi → Bengaluru | ROAD | 2,150.00 | 52.00 | 96,800.00 | 6,100.00 | 1.10 |
| 18 | Delhi → Bengaluru | RAIL | 2,110.00 | 62.00 | 54,200.00 | 0.00 | 1.00 |
| 19 | Delhi → Bengaluru | AIR | 1,740.00 | 3.20 | 246,000.00 | 0.00 | 1.00 |
| 20 | Mumbai → Guwahati | MULTIMODAL | 2,870.00 | 74.00 | 118,500.00 | 5,200.00 | 1.12 |

Effective cost = `(base_freight_cost + toll_cost) × congestion_index`.

**Delhi → Mumbai worked example:** road = (68,500 + 4,200) × 1.15 = **83,605** in 34 h; rail = 38,900 × 1.00 = **38,900** in 42 h. Rail saves ₹44,705 for 8 extra hours — which is precisely the trade-off `optimization_result` #11 recommends taking once fuel prices rise.

**Constraints:** `CHECK (distance_km > 0)`, `CHECK (origin_location_id <> dest_location_id)`.

---

### 6.15 `shipment` (10), `shipment_line` (13), `stock_transfer` (6)

| shipment_no | lane | carrier | vehicle | weight kg | volume m³ | freight | status |
|---|---|---|---|---|---|---|---|
| SHP-2026-0001 | Delhi → Gurugram | BlueDart | DL01AB5678 | 96.00 | 0.650 | 3,240.00 | DELIVERED |
| SHP-2026-0002 | Mumbai → Pune | Gati | MH12CD8765 (REEFER) | 706.50 | 2.480 | 9,180.00 | DELIVERED |
| SHP-2026-0003 | Bengaluru → Hyderabad | VRL | TN10IJ4444 | 940.50 | 3.135 | 29,020.00 | DELAYED |
| SHP-2026-0006 | Delhi → Ludhiana | VRL | MH12CD4321 | 24,900.00 | 31.500 | 17,702.00 | PLANNED |
| SHP-2026-0009 | Delhi → Mumbai (RAIL) | Concor | KA05EF1111 | 14,400.00 | 18.000 | 38,900.00 | DELIVERED |

Every `total_weight_kg` above is the sum of `quantity × product.unit_weight_kg` over its `shipment_line` rows — the data is internally consistent, so Q24's load-factor calculation is meaningful.

`stock_transfer` records network rebalancing:

| from → to | sku | qty | date | shipment | cost | status |
|---|---|---|---|---|---|---|
| WH-DEL-01 → WH-NAG-01 | SKU-FM-1006 | 2,000 | 2026-07-08 | SHP-2026-0007 | 55,020.00 | RECEIVED |
| WH-DEL-01 → WH-KOL-01 | SKU-FM-1007 | 500 | 2026-07-09 | SHP-2026-0008 | 74,648.00 | RECEIVED |
| WH-DEL-01 → WH-MUM-01 | SKU-FM-1006 | 3,000 | 2026-07-11 | SHP-2026-0009 | 38,900.00 | RECEIVED |
| WH-BLR-01 → WH-HYD-01 | SKU-MB-1002 | 450 | 2026-07-20 | *NULL* | 26,800.00 | APPROVED |

`CHECK (from_warehouse_id <> to_warehouse_id)` prevents a self-transfer.

---

### 6.16 `optimization_scenario` (4) and `optimization_run` (7)

| scenario | horizon | demand growth % | fuel index | max WHs | SLA target % |
|---|---|---|---|---|---|
| Baseline FY2026 Network | 90 | 0.00 | 1.000 | — | 95.00 |
| Peak Season Surge +25% | 60 | 25.00 | 1.120 | 8 | 97.00 |
| Fuel Shock Stress Test | 90 | 5.00 | 1.380 | 7 | 93.00 |
| Green Network 2027 | 180 | 12.00 | 1.050 | 9 | 96.00 |

`savings_pct` is a generated column: `(baseline_cost − optimized_cost) / baseline_cost × 100`.

| run | scenario | objective | algorithm | baseline | optimized | savings % | iters | runtime s | status |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Baseline | MIN_TOTAL_COST | MILP | 48,250,000 | 44,180,000 | **8.44** | 1,420 | 186.420 | CONVERGED |
| 2 | Baseline | MIN_TOTAL_COST | GENETIC_ALGORITHM | 48,250,000 | 44,962,000 | 6.81 | 5,000 | 412.880 | CONVERGED |
| 3 | Peak Season | MIN_TOTAL_COST | MILP | 61,840,000 | 55,106,000 | **10.89** | 1,980 | 254.110 | CONVERGED |
| 4 | Peak Season | MAX_SERVICE_LEVEL | SIMULATED_ANNEALING | 61,840,000 | 58,472,000 | 5.45 | 12,000 | 320.760 | CONVERGED |
| 5 | Fuel Shock | MIN_TOTAL_COST | MILP | 57,390,000 | 50,914,000 | **11.28** | 2,240 | 298.530 | CONVERGED |
| 6 | Green Network | MIN_CO2 | PARTICLE_SWARM | 44,180,000 | 42,335,000 | 4.18 | 8,000 | 511.240 | CONVERGED |
| 7 | Green Network | MULTI_OBJECTIVE | MILP | 44,180,000 | 44,180,000 | 0.00 | 0 | 60.000 | INFEASIBLE |

Runs 1 and 2 solve the *same* problem with different algorithms: MILP reaches a 1.63-point better solution in less than half the wall-clock time. Run 7 is retained deliberately — an infeasible run is a result, and the schema must be able to store one.

---

### 6.17 `optimization_result` — 16 rows

| run | warehouse | sku | action | qty | projected saving | confidence | rationale |
|---|---|---|---|---|---|---|---|
| 1 | WH-IDR-01 | — | OPEN_NEW | — | 3,820,000.00 | 88.50 | Indore DC cuts central-region line-haul distance by 21% |
| 2 | WH-IDR-01 | — | OPEN_NEW | — | 3,510,000.00 | 80.60 | GA reached same siting decision as MILP, 1.8% cost gap |
| 5 | WH-NAG-01 | — | CLOSE_FACILITY | — | 1,420,000.00 | 79.30 | Cross-dock unit economics negative under fuel shock |
| 5 | WH-DEL-01 | — | RE_ROUTE | — | 1,284,000.00 | 90.20 | Move Delhi–Mumbai trunk from road to rail at fuel index 1.38 |
| 3 | WH-MUM-01 | SKU-FM-1006 | INCREASE_STOCK | 15,000 | 610,000.00 | 89.40 | Festive uplift of 25% breaches safety stock in week 3 |
| 1 | WH-DEL-01 | SKU-FM-1006 | REDUCE_STOCK | 9,000 | 268,000.00 | 91.30 | Delhi carries 42 days cover against a 21-day target |
| 1 | WH-GUW-01 | SKU-PH-1009 | INCREASE_STOCK | 6,500 | 142,000.00 | 86.70 | Guwahati stock-out probability 18% at current ROP |

Three separate converged runs (1, 2, 5) recommend closing `WH-NAG-01`. That agreement is what the post-load `UPDATE` in the DML acts on.

---

### 6.18 `kpi_snapshot` — 14 rows (7 warehouses × 2 month-ends)

| warehouse | date | turnover | fill rate % | OTD % | utilisation % | cost/order | carrying cost |
|---|---|---|---|---|---|---|---|
| WH-DEL-01 | 2026-06-30 | 8.40 | 96.20 | 93.50 | 72.30 | 412.50 | 8,620,000.00 |
| WH-DEL-01 | 2026-07-31 | 8.75 | 97.10 | 94.80 | 74.97 | 398.20 | 8,940,000.00 |
| WH-MUM-01 | 2026-07-31 | 7.95 | 95.60 | 92.40 | **43.66** | 452.30 | 7,210,000.00 |
| WH-BLR-01 | 2026-07-31 | 9.65 | 98.20 | 96.10 | 59.85 | 341.60 | 5,920,000.00 |
| WH-NAG-01 | 2026-07-31 | 11.80 | 88.40 | 84.90 | 52.73 | 296.70 | 1,310,000.00 |
| WH-GUW-01 | 2026-07-31 | 5.60 | 88.90 | 85.10 | **31.83** | 621.40 | 840,000.00 |

Mumbai carries the **highest** fixed cost in the network (₹5.2 M/month) at the **lowest** utilisation (43.66%). That single pair of facts is the sharpest argument in the whole dataset for re-optimising the network.

---

### 6.19 `app_user` — 7 rows

| username | full_name | role | warehouse scope | active |
|---|---|---|---|---|
| admin | Aayushman Ghatak | ADMIN | — | Yes |
| nplanner1 | Ritika Sharma | NETWORK_PLANNER | — | Yes |
| whm.del | Arjun Mehta | WAREHOUSE_MANAGER | WH-DEL-01 | Yes |
| whm.mum | Priya Nair | WAREHOUSE_MANAGER | WH-MUM-01 | Yes |
| analyst1 | Sneha Das | ANALYST | — | Yes |
| viewer1 | Rahul Verma | VIEWER | WH-KOL-01 | No |

Passwords are stored only as bcrypt hashes; the sample values are placeholders, not real credentials.

---

## 7. Views

| View | Purpose |
|---|---|
| `v_warehouse_master` | Warehouse joined to city, state and region — the denormalised lookup every screen needs |
| `v_stock_health` | Classifies every inventory row as CRITICAL / REORDER / OVERSTOCK / HEALTHY |
| `v_lane_cost_profile` | Effective lane cost and cost-per-km after tolls and congestion |

---

## 8. Normalisation

| Form | How the schema satisfies it |
|---|---|
| **1NF** | Every attribute is atomic. No repeating groups — multiple zones, lines, or lanes become rows in child tables, never comma-separated columns. |
| **2NF** | No partial dependency on a composite key. In `supplier_product` (PK = supplier_id + product_id), `unit_purchase_cost` and `lead_time_days` depend on **both** parts, so they belong there; `supplier_name` depends on `supplier_id` alone and therefore lives in `supplier`. |
| **3NF** | No transitive dependency. `warehouse` stores `location_id`, not `city`/`state`/`region_name` — those depend on `location_id`, not on `warehouse_id`. `order_line` stores `product_id`, not `product_name`. |
| **BCNF** | Every determinant is a candidate key. `warehouse.warehouse_code → warehouse_id` is fine because `warehouse_code` is itself declared `UNIQUE`. Same for `product.sku`, `customer.customer_code`, `shipment.shipment_no`. |

**Deliberate controlled redundancy:**

- `order_line.unit_price` duplicates `product.unit_price` **at the moment of sale**. This is not a 3NF violation — it is a *temporal* attribute. Repricing a SKU must not silently rewrite historical orders.
- `qty_available`, `line_amount` and `savings_pct` are **generated columns**: derived, but computed and enforced by the engine rather than by application code, so they cannot drift.
- `customer_order.order_value` is a materialised aggregate maintained by an explicit `UPDATE … JOIN`, traded for read performance on the dashboard.

---

## 9. Index Strategy

| Index | Table | Rationale |
|---|---|---|
| `ix_location_region` | location | region roll-ups (Q11) |
| `ix_warehouse_status` | warehouse | every optimizer query filters `status = 'ACTIVE'` |
| `ix_product_category`, `ix_product_abc` | product | category browse, ABC/Pareto (Q4) |
| `ix_inventory_product` | inventory | cross-warehouse SKU comparison (Q16 rebalancing) |
| `ix_txn_date` | inventory_transaction | time-window ledger scans |
| `ix_order_date`, `ix_order_status` | customer_order | dashboard filters |
| `ix_lane_origin`, `ix_lane_dest` | transport_lane | graph traversal from either endpoint |
| `ix_shipment_status` | shipment | in-transit tracking |
| `ix_result_run` | optimization_result | fetch all recommendations of one run |

Every `UNIQUE` constraint (`warehouse_code`, `sku`, `order_no`, `shipment_no`, `(warehouse_id, product_id)`, `(origin, dest, mode)`, …) is also a backing index.

---

## 10. Referential Integrity Policy

| Policy | Where used | Why |
|---|---|---|
| `ON DELETE RESTRICT` | location→warehouse, product→inventory, product→order_line | Master data referenced by transactions must never vanish underneath it |
| `ON DELETE CASCADE` | warehouse→zone, order→order_line, run→result, inventory→transaction | True parent-child ownership: the child has no meaning without its parent |
| `ON DELETE SET NULL` | inventory→zone, shipment→vehicle, transfer→shipment, user→warehouse | Optional association: losing the parent should degrade the row, not delete it |

All foreign keys use `ON UPDATE CASCADE`, with four deliberate exceptions:
`fk_lane_origin`, `fk_lane_dest`, `fk_st_from` and `fk_st_to` declare **no referential action** at all.

MySQL 8.0 forbids a column from appearing in both a `CHECK` constraint and a foreign key that carries
`ON UPDATE` / `ON DELETE` actions (error 3823). Those four columns are named in `ck_lane_nodes`
(`origin <> destination`) and `ck_st_nodes` (`from <> to`), so the referential action is omitted and the
`CHECK` is kept. Nothing is lost: `location_id` and `warehouse_id` are `AUTO_INCREMENT` surrogate keys
that never change, so `ON UPDATE CASCADE` had no work to do on them. The default, `NO ACTION`, is
treated as `RESTRICT` by InnoDB — which is what those relationships wanted anyway.

---

## 11. Verification Performed

| Check | Result |
|---|---|
| Statements parsed in MySQL dialect | 104 / 104 |
| Parse failures | 0 |
| DDL objects created | 26 tables + 3 views + 13 secondary indexes |
| DML statements executed | 29 |
| Foreign-key violations after full load | 0 |
| Analytical queries executed successfully | 25 / 25 |
| Queries returning an empty result set | 0 |

---

## 12. File Manifest

| File | Contents |
|---|---|
| `sql/01_schema_ddl.sql` | Database, 26 tables, constraints, indexes, 3 views |
| `sql/02_sample_data_dml.sql` | Full sample dataset + derived-value `UPDATE`s + row-count verification |
| `sql/03_analysis_queries.sql` | 25 analytical / optimization queries |
| `diagrams/architecture_diagram.png` `.pdf` `.svg` | Six-layer system architecture with cross-cutting concerns |
| `diagrams/er_diagram.png` `.pdf` `.svg` `.dot` | Full attribute-level ER diagram, crow's-foot notation |
| `diagrams/er_diagram_conceptual.png` `.pdf` `.dot` | Entity-level ER diagram for slides |
| `presentation/Warehouse_Network_Optimization_System.pptx` | 15-slide project presentation |
| `docs/Database_Design_Document.md` | This document |
