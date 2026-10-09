-- =====================================================================
-- PROJECT : WAREHOUSE NETWORK OPTIMIZATION SYSTEM (WNOS)
-- FILE    : 02_sample_data_dml.sql
-- PURPOSE : Data Manipulation Language - populate every table with values
-- RDBMS   : MySQL 8.0
-- AUTHOR  : Aayushman Ghatak
-- NOTE    : Run AFTER 01_schema_ddl.sql
-- =====================================================================

USE wnos;

-- MySQL Workbench runs with "Safe Updates" on by default, which rejects any
-- UPDATE whose WHERE clause has no key column (Error 1175). The derived-value
-- UPDATEs at the end of this file are deliberate bulk updates, so turn it off
-- for this session only.
SET SQL_SAFE_UPDATES = 0;

-- =====================================================================
-- 1. REGION
-- =====================================================================
INSERT INTO region (region_id, region_code, region_name, country) VALUES
(1, 'NR', 'Northern Region', 'India'),
(2, 'WR', 'Western Region',  'India'),
(3, 'SR', 'Southern Region', 'India'),
(4, 'ER', 'Eastern Region',  'India'),
(5, 'CR', 'Central Region',  'India');

-- =====================================================================
-- 2. LOCATION
-- =====================================================================
INSERT INTO location (location_id, city, state, postal_code, latitude, longitude, region_id) VALUES
( 1, 'Delhi',       'Delhi',           '110001', 28.613900, 77.209000, 1),
( 2, 'Gurugram',    'Haryana',         '122001', 28.459500, 77.026600, 1),
( 3, 'Ludhiana',    'Punjab',          '141001', 30.900965, 75.857276, 1),
( 4, 'Mumbai',      'Maharashtra',     '400001', 19.076000, 72.877700, 2),
( 5, 'Pune',        'Maharashtra',     '411001', 18.520400, 73.856700, 2),
( 6, 'Ahmedabad',   'Gujarat',         '380001', 23.022500, 72.571400, 2),
( 7, 'Bengaluru',   'Karnataka',       '560001', 12.971600, 77.594600, 3),
( 8, 'Chennai',     'Tamil Nadu',      '600001', 13.082700, 80.270700, 3),
( 9, 'Hyderabad',   'Telangana',       '500001', 17.385000, 78.486700, 3),
(10, 'Kolkata',     'West Bengal',     '700001', 22.572600, 88.363900, 4),
(11, 'Guwahati',    'Assam',           '781001', 26.144500, 91.736200, 4),
(12, 'Bhubaneswar', 'Odisha',          '751001', 20.296100, 85.824500, 4),
(13, 'Nagpur',      'Maharashtra',     '440001', 21.145800, 79.088200, 5),
(14, 'Indore',      'Madhya Pradesh',  '452001', 22.719600, 75.857700, 5),
(15, 'Raipur',      'Chhattisgarh',    '492001', 21.251400, 81.629600, 5);

-- =====================================================================
-- 3. WAREHOUSE
-- =====================================================================
INSERT INTO warehouse
(warehouse_id, warehouse_code, warehouse_name, location_id, warehouse_type,
 storage_capacity_units, throughput_per_day, fixed_cost_monthly, variable_cost_per_unit,
 automation_level, opened_date, status) VALUES
(1, 'WH-DEL-01', 'Delhi Central Distribution Centre', 1, 'CENTRAL_DC',        95000, 12000, 4500000.00, 12.5000, 'AUTOMATED',      '2019-04-01', 'ACTIVE'),
(2, 'WH-MUM-01', 'Mumbai Regional Distribution Centre', 4, 'REGIONAL_DC',     32000,  4000, 5200000.00, 14.7500, 'SEMI_AUTOMATED', '2020-06-15', 'ACTIVE'),
(3, 'WH-BLR-01', 'Bengaluru Fulfilment Centre',        7, 'FULFILMENT_CENTRE', 55000,  7500, 3900000.00, 11.2000, 'AUTOMATED',      '2021-01-10', 'ACTIVE'),
(4, 'WH-KOL-01', 'Kolkata Regional Distribution Centre',10,'REGIONAL_DC',     45000,  5500, 2750000.00, 10.4000, 'SEMI_AUTOMATED', '2018-09-01', 'ACTIVE'),
(5, 'WH-NAG-01', 'Nagpur Cross-Dock Hub',             13, 'CROSS_DOCK',       22000,  6500, 1400000.00,  8.9000, 'MANUAL',         '2022-03-20', 'ACTIVE'),
(6, 'WH-HYD-01', 'Hyderabad Fulfilment Centre',        9, 'FULFILMENT_CENTRE', 48000,  6000, 3300000.00, 10.9500, 'SEMI_AUTOMATED', '2021-11-05', 'ACTIVE'),
(7, 'WH-GUW-01', 'Guwahati Dark Store',               11, 'DARK_STORE',       12000,  1500,  620000.00, 15.8000, 'MANUAL',         '2023-02-12', 'ACTIVE'),
(8, 'WH-IDR-01', 'Indore Regional DC (Proposed)',     14, 'REGIONAL_DC',      40000,  5000, 1950000.00,  9.6000, 'SEMI_AUTOMATED', '2026-01-01', 'PROPOSED');

-- =====================================================================
-- 4. WAREHOUSE_ZONE
-- =====================================================================
INSERT INTO warehouse_zone (zone_id, warehouse_id, zone_code, zone_type, capacity_units, temp_min_c, temp_max_c) VALUES
( 1, 1, 'A1', 'AMBIENT',     150000, 15.00, 30.00),
( 2, 1, 'C1', 'COLD_CHAIN',   50000,  2.00,  8.00),
( 3, 1, 'H1', 'HAZMAT',       20000, 15.00, 28.00),
( 4, 1, 'V1', 'HIGH_VALUE',   30000, 18.00, 26.00),
( 5, 2, 'A1', 'AMBIENT',     120000, 16.00, 32.00),
( 6, 2, 'C1', 'COLD_CHAIN',   40000,  2.00,  8.00),
( 7, 2, 'B1', 'BULK',         20000, 16.00, 34.00),
( 8, 3, 'A1', 'AMBIENT',     100000, 15.00, 29.00),
( 9, 3, 'V1', 'HIGH_VALUE',   30000, 18.00, 25.00),
(10, 3, 'F1', 'FROZEN',       20000,-22.00,-18.00),
(11, 4, 'A1', 'AMBIENT',      90000, 16.00, 33.00),
(12, 4, 'C1', 'COLD_CHAIN',   30000,  2.00,  8.00),
(13, 5, 'A1', 'AMBIENT',      60000, 16.00, 35.00),
(14, 6, 'A1', 'AMBIENT',     100000, 15.00, 31.00),
(15, 6, 'C1', 'COLD_CHAIN',   40000,  2.00,  8.00),
(16, 7, 'A1', 'AMBIENT',      25000, 14.00, 30.00),
(17, 8, 'A1', 'AMBIENT',     100000, 15.00, 32.00);

-- =====================================================================
-- 5. PRODUCT_CATEGORY
-- =====================================================================
INSERT INTO product_category (category_id, category_name, parent_category_id) VALUES
(1, 'Electronics',        NULL),
(2, 'Home Appliances',    NULL),
(3, 'FMCG',               NULL),
(4, 'Pharmaceuticals',    NULL),
(5, 'Industrial Spares',  NULL),
(6, 'Mobile Devices',     1),
(7, 'Packaged Foods',     3),
(8, 'Cold Chain Pharma',  4);

-- =====================================================================
-- 6. PRODUCT
-- =====================================================================
INSERT INTO product
(product_id, sku, product_name, category_id, unit_weight_kg, unit_volume_m3,
 unit_cost, unit_price, shelf_life_days, storage_type, abc_class, is_hazmat) VALUES
( 1, 'SKU-EL-1001', '4K Smart LED TV 55 inch',        1, 18.500, 0.2200, 32000.00, 41999.00, NULL, 'AMBIENT',    'A', 0),
( 2, 'SKU-MB-1002', 'Smartphone 5G 128GB',            6,  0.220, 0.0015, 14500.00, 19999.00, NULL, 'HIGH_VALUE', 'A', 0),
( 3, 'SKU-MB-1003', 'Wireless Earbuds Pro',           6,  0.060, 0.0004,  2200.00,  3499.00, NULL, 'HIGH_VALUE', 'B', 0),
( 4, 'SKU-HA-1004', 'Inverter Refrigerator 260L',     2, 58.000, 0.7800, 24500.00, 31999.00, NULL, 'AMBIENT',    'A', 0),
( 5, 'SKU-HA-1005', 'Front Load Washing Machine 7kg', 2, 65.000, 0.6500, 27000.00, 34999.00, NULL, 'AMBIENT',    'B', 0),
( 6, 'SKU-FM-1006', 'Sunflower Refined Oil 5L',       7,  4.800, 0.0060,   620.00,   799.00,  365, 'AMBIENT',    'A', 0),
( 7, 'SKU-FM-1007', 'Basmati Rice 10kg',              7, 10.200, 0.0130,   780.00,  1049.00,  540, 'AMBIENT',    'B', 0),
( 8, 'SKU-FM-1008', 'Frozen Green Peas 1kg',          7,  1.050, 0.0018,    95.00,   149.00,  180, 'FROZEN',     'C', 0),
( 9, 'SKU-PH-1009', 'Paracetamol 500mg (100 tabs)',   4,  0.180, 0.0006,    42.00,    79.00,  730, 'AMBIENT',    'B', 0),
(10, 'SKU-PH-1010', 'Insulin Vial 10ml',              8,  0.090, 0.0003,   380.00,   620.00,  545, 'COLD_CHAIN', 'A', 0),
(11, 'SKU-PH-1011', 'Vaccine Carton (10 dose)',       8,  0.450, 0.0020,  1250.00,  1899.00,  365, 'COLD_CHAIN', 'A', 0),
(12, 'SKU-IS-1012', 'Industrial Ball Bearing 6205',   5,  0.130, 0.0002,   210.00,   349.00, NULL, 'AMBIENT',    'C', 0),
(13, 'SKU-IS-1013', 'Hydraulic Oil 20L Drum',         5, 18.000, 0.0250,  2400.00,  3200.00,  720, 'HAZMAT',     'B', 1),
(14, 'SKU-IS-1014', 'Lithium Battery Pack 48V',       5, 12.500, 0.0180,  8600.00, 12499.00, NULL, 'HAZMAT',     'A', 1),
(15, 'SKU-EL-1015', 'Laptop 14 inch i5 16GB',         1,  1.450, 0.0090, 48000.00, 62999.00, NULL, 'HIGH_VALUE', 'A', 0);

-- =====================================================================
-- 7. SUPPLIER
-- =====================================================================
INSERT INTO supplier
(supplier_id, supplier_code, supplier_name, location_id, contact_email, contact_phone,
 avg_lead_time_days, reliability_score, is_active) VALUES
(1, 'SUP-N-001', 'Aurora Electronics Pvt Ltd',    2, 'sales@auroraelec.example.com',   '+91-124-4455661', 10, 94.50, 1),
(2, 'SUP-W-002', 'Sahyadri FMCG Distributors',    5, 'orders@sahyadrifmcg.example.com','+91-20-26551234',  5, 91.20, 1),
(3, 'SUP-S-003', 'Deccan Pharma Labs',            9, 'supply@deccanpharma.example.com','+91-40-23456789',  8, 96.80, 1),
(4, 'SUP-E-004', 'Bengal Industrial Supplies',   10, 'info@bengalind.example.com',     '+91-33-22114455', 12, 88.40, 1),
(5, 'SUP-N-005', 'Punjab Agro Foods',             3, 'trade@punjabagro.example.com',   '+91-161-2778899',  6, 92.75, 1),
(6, 'SUP-S-006', 'Coromandel Appliance Works',    8, 'b2b@coromandelapp.example.com',  '+91-44-28123456', 14, 89.90, 1);

-- =====================================================================
-- 8. SUPPLIER_PRODUCT  (M:N)
-- =====================================================================
INSERT INTO supplier_product (supplier_id, product_id, unit_purchase_cost, min_order_qty, lead_time_days, is_preferred) VALUES
(1,  1, 32000.00,  20, 10, 1),
(1,  2, 14500.00,  50,  9, 1),
(1,  3,  2200.00, 100,  7, 0),
(1, 15, 48000.00,  15, 12, 1),
(2,  6,   620.00, 200,  5, 1),
(2,  7,   780.00, 150,  5, 1),
(2,  8,    95.00, 300,  4, 1),
(3,  9,    42.00, 500,  8, 1),
(3, 10,   380.00, 100,  6, 1),
(3, 11,  1250.00,  60,  7, 1),
(4, 12,   210.00, 400, 12, 1),
(4, 13,  2400.00,  40, 10, 1),
(4, 14,  8600.00,  25, 15, 1),
(5,  6,   635.00, 180,  6, 0),
(5,  7,   765.00, 200,  6, 0),
(6,  4, 24500.00,  10, 14, 1),
(6,  5, 27000.00,  10, 14, 1),
(6,  1, 32500.00,  15, 16, 0);

-- =====================================================================
-- 9. CUSTOMER
-- =====================================================================
INSERT INTO customer
(customer_id, customer_code, customer_name, customer_type, location_id,
 priority_tier, service_level_hours, credit_limit, registered_on) VALUES
( 1, 'CUS-0001', 'Metro Retail Hypermart',     'RETAIL',     1, 'PLATINUM', 24, 5000000.00, '2019-05-10'),
( 2, 'CUS-0002', 'Shakti Wholesale Traders',   'WHOLESALE',  3, 'GOLD',     48, 3000000.00, '2020-02-18'),
( 3, 'CUS-0003', 'QuickCart Ecommerce',        'ECOMMERCE',  2, 'PLATINUM', 12, 8000000.00, '2021-07-01'),
( 4, 'CUS-0004', 'Konkan Supermarts',          'RETAIL',     4, 'GOLD',     24, 2500000.00, '2020-11-23'),
( 5, 'CUS-0005', 'Pune Pharma Chain',          'B2B',        5, 'PLATINUM', 12, 4200000.00, '2019-09-14'),
( 6, 'CUS-0006', 'Sabarmati Distributors',     'WHOLESALE',  6, 'SILVER',   72, 1800000.00, '2022-01-30'),
( 7, 'CUS-0007', 'Silicon Valley Electronics', 'RETAIL',     7, 'GOLD',     24, 3600000.00, '2021-03-08'),
( 8, 'CUS-0008', 'Marina Mega Stores',         'RETAIL',     8, 'SILVER',   48, 1500000.00, '2022-06-19'),
( 9, 'CUS-0009', 'Charminar Trading Co',       'WHOLESALE',  9, 'GOLD',     36, 2900000.00, '2020-08-05'),
(10, 'CUS-0010', 'Howrah Retail Network',      'RETAIL',    10, 'SILVER',   48, 1200000.00, '2021-12-11'),
(11, 'CUS-0011', 'Brahmaputra Stores',         'RETAIL',    11, 'BRONZE',   96,  600000.00, '2023-04-02'),
(12, 'CUS-0012', 'Orange City Industrials',    'B2B',       13, 'GOLD',     36, 2200000.00, '2022-09-27');

-- =====================================================================
-- 10. INVENTORY   (qty_available is a GENERATED column - not inserted)
-- =====================================================================
INSERT INTO inventory
(inventory_id, warehouse_id, product_id, zone_id, qty_on_hand, qty_reserved, qty_in_transit,
 safety_stock, reorder_point, max_stock_level, avg_daily_demand, last_counted_date) VALUES
-- Delhi Central DC
( 1, 1,  1,  1,   380,  120,  200,   150,   300,   1200,   42.50, '2026-07-15'),
( 2, 1,  2,  4,  3200,  450,  800,   600,  1200,   4500,  185.00, '2026-07-15'),
( 3, 1,  3,  4,  5400,  300,    0,   800,  1500,   7000,  240.00, '2026-07-15'),
( 4, 1,  6,  1, 17000, 1500, 3000,  2500,  5000,  18000,  720.00, '2026-07-16'),
( 5, 1,  7,  1,  8600,  900,    0,  2000,  4000,  14000,  540.00, '2026-07-16'),
( 6, 1,  9,  1, 36000, 2000, 5000,  5000,  9000,  40000, 1250.00, '2026-07-16'),
( 7, 1, 15,  4,   640,   80,  150,   120,   250,    900,   33.00, '2026-07-15'),
-- Mumbai Regional DC
( 8, 2,  1,  5,   520,   60,  100,   100,   220,    800,   28.00, '2026-07-14'),
( 9, 2,  4,  5,   310,   40,   60,    60,   130,    500,   17.50, '2026-07-14'),
(10, 2,  5,  5,   240,   25,    0,    50,   110,    400,   14.00, '2026-07-14'),
(11, 2,  6,  5,  9500, 1100, 2000,  2000,  4200,  15000,  610.00, '2026-07-17'),
(12, 2, 10,  6,  1600,  500,  900,   900,  1800,   6500,  210.00, '2026-07-17'),
(13, 2, 11,  6,  1800,  200,  400,   350,   700,   2800,   88.00, '2026-07-17'),
-- Bengaluru Fulfilment Centre
(14, 3,  2,  9,  2800,  380,  600,   500,  1000,   4000,  160.00, '2026-07-13'),
(15, 3,  3,  9,  4600,  260,    0,   700,  1300,   6000,  205.00, '2026-07-13'),
(16, 3, 15,  9,   720,   90,  180,   130,   280,   1000,   38.00, '2026-07-13'),
(17, 3,  8, 10,  6800,  700, 1200,  1400,  2600,   9500,  380.00, '2026-07-18'),
(18, 3,  9,  8, 18000, 1500,    0,  3500,  6500,  28000,  890.00, '2026-07-18'),
-- Kolkata Regional DC
(19, 4,  6, 11,  5400,  600, 1000,  1200,  2400,   8500,  330.00, '2026-07-12'),
(20, 4,  7, 11,  4200,  400,    0,   900,  1900,   7000,  260.00, '2026-07-12'),
(21, 4, 12, 11, 15000,  900, 2000,  2500,  5000,  22000,  640.00, '2026-07-12'),
(22, 4, 10, 12,   550,  220,  300,   400,   850,   3000,   96.00, '2026-07-19'),
-- Nagpur Cross-Dock
(23, 5,  6, 13,  1600,  800, 1500,   600,  1400,   5000,  410.00, '2026-07-11'),
(24, 5,  7, 13,  2600,  650, 1200,   500,  1200,   4200,  350.00, '2026-07-11'),
(25, 5, 12, 13,  7400, 1200, 1800,  1200,  2600,  11000,  520.00, '2026-07-11'),
-- Hyderabad Fulfilment Centre
(26, 6,  2, 14,  2100,  300,  450,   400,   850,   3200,  128.00, '2026-07-16'),
(27, 6,  9, 14, 21000, 1800, 3500,  4000,  7500,  32000, 1020.00, '2026-07-16'),
(28, 6, 10, 15,  5200,  420,  700,   750,  1500,   5500,  178.00, '2026-07-16'),
(29, 6, 11, 15,  1450,  160,  300,   300,   620,   2400,   74.00, '2026-07-16'),
-- Guwahati Dark Store
(30, 7,  6, 16,  1400,  180,  400,   300,   620,   2200,   95.00, '2026-07-10'),
(31, 7,  9, 16,  1800,  400,  900,  1000,  1900,   7500,  240.00, '2026-07-10'),
(32, 7,  3, 16,   620,   60,  150,   130,   280,   1000,   34.00, '2026-07-10');

-- =====================================================================
-- 11. INVENTORY_TRANSACTION
-- =====================================================================
INSERT INTO inventory_transaction (txn_id, inventory_id, txn_type, quantity, txn_datetime, reference_no, remarks) VALUES
( 1,  4, 'INBOUND',       6000, '2026-07-01 08:15:00', 'PO-2026-0451', 'Replenishment from Sahyadri FMCG'),
( 2,  6, 'INBOUND',      12000, '2026-07-01 10:40:00', 'PO-2026-0452', 'Deccan Pharma bulk receipt'),
( 3,  2, 'OUTBOUND',      -300, '2026-07-03 19:20:00', 'ORD-2026-0002','Allocated to QuickCart Ecommerce'),
( 4,  3, 'OUTBOUND',      -500, '2026-07-03 19:22:00', 'ORD-2026-0002','Allocated to QuickCart Ecommerce'),
( 5, 11, 'OUTBOUND',     -1200, '2026-07-05 11:05:00', 'ORD-2026-0003','Konkan Supermarts order'),
( 6, 12, 'OUTBOUND',      -600, '2026-07-06 13:50:00', 'ORD-2026-0004','Cold chain despatch to Pune'),
( 7, 13, 'OUTBOUND',      -250, '2026-07-06 13:52:00', 'ORD-2026-0004','Vaccine carton despatch'),
( 8,  4, 'TRANSFER_OUT',  -2000,'2026-07-08 04:10:00', 'STO-2026-0011','Rebalancing to Nagpur cross-dock'),
( 9, 23, 'TRANSFER_IN',    2000,'2026-07-09 06:30:00', 'STO-2026-0011','Received from Delhi Central DC'),
(10,  5, 'TRANSFER_OUT',   -500,'2026-07-09 03:45:00', 'STO-2026-0012','Rebalancing to Kolkata'),
(11, 20, 'TRANSFER_IN',     500,'2026-07-10 18:20:00', 'STO-2026-0012','Received from Delhi Central DC'),
(12, 18, 'OUTBOUND',      -5000,'2026-07-11 08:10:00', 'ORD-2026-0006','Charminar Trading despatch'),
(13, 27, 'INBOUND',        9000,'2026-07-12 09:25:00', 'PO-2026-0463', 'Deccan Pharma replenishment'),
(14,  4, 'TRANSFER_OUT',  -3000,'2026-07-11 22:05:00', 'STO-2026-0013','Rail move to Mumbai RDC'),
(15, 11, 'TRANSFER_IN',    3000,'2026-07-13 14:35:00', 'STO-2026-0013','Received via Concor rail'),
(16, 30, 'OUTBOUND',       -300,'2026-07-15 06:15:00', 'ORD-2026-0008','Brahmaputra Stores order'),
(17, 21, 'OUTBOUND',      -2500,'2026-07-12 15:40:00', 'ORD-2026-0007','Howrah Retail Network order'),
(18, 15, 'OUTBOUND',       -260,'2026-07-19 07:30:00', 'ORD-2026-0012','Marina Mega Stores order'),
(19,  1, 'OUTBOUND',        -40,'2026-07-02 17:55:00', 'ORD-2026-0001','Metro Retail Hypermart order'),
(20,  7, 'OUTBOUND',        -25,'2026-07-02 17:58:00', 'ORD-2026-0001','Metro Retail Hypermart order'),
(21, 17, 'DAMAGE',          -85,'2026-07-14 12:00:00', 'ADJ-2026-0007','Cold chain excursion, frozen peas written off'),
(22, 25, 'ADJUSTMENT',      120,'2026-07-18 16:20:00', 'ADJ-2026-0008','Cycle count surplus reconciled');

-- =====================================================================
-- 12. CUSTOMER_ORDER   (order_value is synchronised at the end of file)
-- =====================================================================
INSERT INTO customer_order (order_id, order_no, customer_id, order_date, required_date, order_status, priority, order_value) VALUES
( 1, 'ORD-2026-0001',  1, '2026-07-02', '2026-07-04', 'DELIVERED', 'HIGH',   0.00),
( 2, 'ORD-2026-0002',  3, '2026-07-03', '2026-07-04', 'DELIVERED', 'URGENT', 0.00),
( 3, 'ORD-2026-0003',  4, '2026-07-05', '2026-07-08', 'DELIVERED', 'NORMAL', 0.00),
( 4, 'ORD-2026-0004',  5, '2026-07-06', '2026-07-07', 'DELIVERED', 'URGENT', 0.00),
( 5, 'ORD-2026-0005',  7, '2026-07-08', '2026-07-10', 'SHIPPED',   'HIGH',   0.00),
( 6, 'ORD-2026-0006',  9, '2026-07-10', '2026-07-13', 'SHIPPED',   'NORMAL', 0.00),
( 7, 'ORD-2026-0007', 10, '2026-07-12', '2026-07-15', 'PICKING',   'NORMAL', 0.00),
( 8, 'ORD-2026-0008', 11, '2026-07-14', '2026-07-19', 'ALLOCATED', 'LOW',    0.00),
( 9, 'ORD-2026-0009', 12, '2026-07-15', '2026-07-18', 'ALLOCATED', 'NORMAL', 0.00),
(10, 'ORD-2026-0010',  2, '2026-07-16', '2026-07-20', 'NEW',       'NORMAL', 0.00),
(11, 'ORD-2026-0011',  6, '2026-07-17', '2026-07-22', 'BACKORDER', 'LOW',    0.00),
(12, 'ORD-2026-0012',  8, '2026-07-18', '2026-07-21', 'NEW',       'HIGH',   0.00);

-- =====================================================================
-- 13. ORDER_LINE   (line_amount is a GENERATED column - not inserted)
-- =====================================================================
INSERT INTO order_line (order_line_id, order_id, product_id, quantity, unit_price, discount_pct) VALUES
( 1,  1,  1,   40, 41999.00, 5.00),
( 2,  1,  2,  120, 19999.00, 3.00),
( 3,  1, 15,   25, 62999.00, 4.00),
( 4,  2,  2,  300, 19999.00, 6.00),
( 5,  2,  3,  500,  3499.00, 8.00),
( 6,  3,  6, 1200,   799.00, 4.00),
( 7,  3,  7,  800,  1049.00, 3.50),
( 8,  4, 10,  600,   620.00, 2.00),
( 9,  4, 11,  250,  1899.00, 2.50),
(10,  4,  9, 3000,    79.00, 5.00),
(11,  5,  2,  180, 19999.00, 4.00),
(12,  5,  3,  400,  3499.00, 6.00),
(13,  6,  9, 5000,    79.00, 7.00),
(14,  6, 10,  450,   620.00, 3.00),
(15,  7,  6,  900,   799.00, 3.00),
(16,  7, 12, 2500,   349.00, 6.00),
(17,  8,  6,  300,   799.00, 0.00),
(18,  8,  9,  800,    79.00, 2.00),
(19,  9, 12, 1800,   349.00, 5.00),
(20,  9, 13,  120,  3200.00, 4.00),
(21,  9, 14,   45, 12499.00, 3.00),
(22, 10,  7, 1500,  1049.00, 6.00),
(23, 10,  6, 2000,   799.00, 5.50),
(24, 11,  4,   60, 31999.00, 3.00),
(25, 11,  5,   45, 34999.00, 2.50),
(26, 12,  1,   22, 41999.00, 4.00),
(27, 12,  3,  260,  3499.00, 5.00);

-- =====================================================================
-- 14. ORDER_FULFILMENT   (warehouse allocation decided by the optimizer)
-- =====================================================================
INSERT INTO order_fulfilment
(fulfilment_id, order_id, warehouse_id, allocation_method, allocated_on, dispatched_on, delivered_on,
 handling_cost, fulfilment_status) VALUES
( 1,  1, 1, 'OPTIMIZER',     '2026-07-02 09:15:00', '2026-07-02 17:55:00', '2026-07-03 14:20:00',  18500.00, 'COMPLETE'),
( 2,  2, 1, 'OPTIMIZER',     '2026-07-03 10:05:00', '2026-07-03 20:15:00', '2026-07-04 03:10:00',  12400.00, 'COMPLETE'),
( 3,  3, 2, 'NEAREST',       '2026-07-05 09:40:00', '2026-07-05 16:30:00', '2026-07-07 11:45:00',   9800.00, 'COMPLETE'),
( 4,  4, 2, 'LOWEST_COST',   '2026-07-06 08:20:00', '2026-07-06 14:30:00', '2026-07-06 21:05:00',  11200.00, 'COMPLETE'),
( 5,  5, 3, 'OPTIMIZER',     '2026-07-08 11:10:00', '2026-07-08 18:45:00', NULL,                   10600.00, 'PARTIAL'),
( 6,  6, 3, 'OPTIMIZER',     '2026-07-10 09:55:00', '2026-07-11 08:00:00', NULL,                   14300.00, 'PARTIAL'),
( 7,  7, 4, 'LOAD_BALANCED', '2026-07-12 12:30:00', NULL,                  NULL,                       0.00, 'PENDING'),
( 8,  8, 4, 'OPTIMIZER',     '2026-07-14 15:00:00', '2026-07-15 06:00:00', NULL,                    7400.00, 'PARTIAL'),
( 9,  9, 5, 'OPTIMIZER',     '2026-07-15 10:20:00', NULL,                  NULL,                       0.00, 'PENDING'),
(10, 10, 1, 'OPTIMIZER',     '2026-07-16 09:05:00', '2026-07-17 05:30:00', NULL,                   16800.00, 'PARTIAL'),
(11, 11, 2, 'MANUAL',        '2026-07-17 14:45:00', NULL,                  NULL,                       0.00, 'PENDING'),
(12, 12, 3, 'OPTIMIZER',     '2026-07-18 16:10:00', '2026-07-19 07:45:00', NULL,                    8900.00, 'PARTIAL');

-- =====================================================================
-- 15. DEMAND_FORECAST
-- =====================================================================
INSERT INTO demand_forecast
(forecast_id, warehouse_id, product_id, period_start, period_end, forecast_qty, actual_qty, model_used, mape_pct) VALUES
( 1, 1,  2, '2026-07-01', '2026-07-31',  5600,  5320, 'SARIMA',         5.00),
( 2, 1,  6, '2026-07-01', '2026-07-31', 21500, 22380, 'ARIMA',          4.09),
( 3, 1,  9, '2026-07-01', '2026-07-31', 38000, 36940, 'LSTM',           2.79),
( 4, 1,  2, '2026-08-01', '2026-08-31',  5900,  NULL, 'SARIMA',         NULL),
( 5, 2,  6, '2026-07-01', '2026-07-31', 18500, 19240, 'ARIMA',          3.85),
( 6, 2, 10, '2026-07-01', '2026-07-31',  6400,  6180, 'XGBOOST',        3.44),
( 7, 2, 10, '2026-08-01', '2026-08-31',  6750,  NULL, 'XGBOOST',        NULL),
( 8, 3,  2, '2026-07-01', '2026-07-31',  4900,  5110, 'LSTM',           4.29),
( 9, 3,  3, '2026-07-01', '2026-07-31',  6200,  5980, 'EXP_SMOOTHING',  3.55),
(10, 3,  8, '2026-07-01', '2026-07-31', 11500, 12040, 'ARIMA',          4.70),
(11, 4,  6, '2026-07-01', '2026-07-31', 10200,  9860, 'MOVING_AVG',     3.33),
(12, 4, 12, '2026-07-01', '2026-07-31', 19500, 20310, 'ARIMA',          4.16),
(13, 5, 12, '2026-07-01', '2026-07-31', 15800, 16420, 'XGBOOST',        3.92),
(14, 6,  9, '2026-07-01', '2026-07-31', 31000, 30150, 'LSTM',           2.74),
(15, 6, 10, '2026-07-01', '2026-07-31',  5400,  5620, 'SARIMA',         4.07),
(16, 7,  9, '2026-07-01', '2026-07-31',  7300,  7810, 'MOVING_AVG',     6.99);

-- =====================================================================
-- 16. CARRIER
-- =====================================================================
INSERT INTO carrier (carrier_id, carrier_code, carrier_name, transport_mode, cost_per_km, cost_per_kg, avg_speed_kmph, on_time_pct, is_active) VALUES
(1, 'CAR-BLU', 'BlueDart Surface Express',   'ROAD',        42.50,  8.90,  55.00, 94.20, 1),
(2, 'CAR-GAT', 'Gati Multimodal Logistics',  'MULTIMODAL',  36.80,  6.40,  48.00, 89.60, 1),
(3, 'CAR-CON', 'Concor Rail Freight',        'RAIL',        18.20,  3.75,  40.00, 86.30, 1),
(4, 'CAR-AIR', 'SpiceXpress Air Cargo',      'AIR',        168.00, 62.50, 720.00, 91.80, 1),
(5, 'CAR-VRL', 'VRL Roadlines',              'ROAD',        38.90,  7.20,  52.00, 88.10, 1);

-- =====================================================================
-- 17. VEHICLE
-- =====================================================================
INSERT INTO vehicle
(vehicle_id, carrier_id, registration_no, vehicle_type, capacity_weight_kg, capacity_volume_m3,
 fuel_cost_per_km, co2_g_per_km, is_available) VALUES
( 1, 1, 'DL01AB1234', 'HCV',        16000.00, 48.000, 22.50,  780.00, 1),
( 2, 1, 'DL01AB5678', 'MCV',         9000.00, 28.000, 16.80,  540.00, 1),
( 3, 2, 'MH12CD4321', 'TRAILER',    25000.00, 76.000, 31.40, 1120.00, 1),
( 4, 2, 'MH12CD8765', 'REEFER',     12000.00, 36.000, 26.90,  910.00, 1),
( 5, 3, 'KA05EF1111', 'CONTAINER',  30000.00, 90.000, 12.60,  420.00, 1),
( 6, 3, 'KA05EF2222', 'HCV',        18000.00, 52.000, 23.10,  800.00, 0),
( 7, 4, 'WB20GH3333', 'LCV',         3500.00, 12.000, 11.40,  320.00, 1),
( 8, 5, 'TN10IJ4444', 'MCV',         9500.00, 30.000, 17.20,  560.00, 1),
( 9, 5, 'TS09KL5555', 'MINI_TRUCK',  1500.00,  6.000,  7.80,  190.00, 1),
(10, 1, 'GJ01MN6666', 'REEFER',     11000.00, 34.000, 27.50,  940.00, 1);

-- =====================================================================
-- 18. TRANSPORT_LANE   (arcs of the network graph)
-- =====================================================================
INSERT INTO transport_lane
(lane_id, origin_location_id, dest_location_id, transport_mode, distance_km, transit_time_hours,
 base_freight_cost, toll_cost, congestion_index, is_active) VALUES
( 1,  1,  2, 'ROAD',         32.00,  1.20,   2400.00,  120.00, 1.35, 1),
( 2,  1,  3, 'ROAD',        310.00,  6.50,  15800.00,  850.00, 1.06, 1),
( 3,  1,  4, 'ROAD',       1420.00, 34.00,  68500.00, 4200.00, 1.15, 1),
( 4,  1,  7, 'ROAD',       2150.00, 52.00,  96800.00, 6100.00, 1.10, 1),
( 5,  1, 10, 'ROAD',       1490.00, 36.00,  71200.00, 4400.00, 1.08, 1),
( 6,  1, 13, 'ROAD',       1075.00, 26.00,  52400.00, 3300.00, 1.05, 1),
( 7,  4,  5, 'ROAD',        150.00,  3.50,   8200.00,  420.00, 1.12, 1),
( 8,  4,  6, 'ROAD',        525.00, 12.00,  26400.00, 1500.00, 1.07, 1),
( 9,  4,  7, 'ROAD',        985.00, 24.00,  47800.00, 2900.00, 1.12, 1),
(10,  4,  9, 'ROAD',        710.00, 17.00,  34600.00, 2100.00, 1.06, 1),
(11,  7,  8, 'ROAD',        350.00,  8.50,  17800.00,  950.00, 1.09, 1),
(12,  7,  9, 'ROAD',        570.00, 13.50,  27900.00, 1650.00, 1.04, 1),
(13, 10, 11, 'ROAD',        990.00, 26.00,  51200.00, 2800.00, 1.18, 1),
(14, 10, 12, 'ROAD',        442.00, 11.00,  22400.00, 1200.00, 1.07, 1),
(15, 13, 14, 'ROAD',        445.00, 10.50,  21900.00, 1150.00, 1.03, 1),
(16, 13, 15, 'ROAD',        285.00,  7.00,  14600.00,  780.00, 1.02, 1),
(17,  1,  4, 'RAIL',       1385.00, 42.00,  38900.00,    0.00, 1.00, 1),
(18,  1,  7, 'RAIL',       2110.00, 62.00,  54200.00,    0.00, 1.00, 1),
(19,  1,  7, 'AIR',        1740.00,  3.20, 246000.00,    0.00, 1.00, 1),
(20,  4, 11, 'MULTIMODAL', 2870.00, 74.00, 118500.00, 5200.00, 1.12, 1),
(21,  9, 13, 'ROAD',        500.00, 12.00,  24800.00, 1400.00, 1.05, 1),
(22,  1, 14, 'ROAD',        800.00, 19.00,  39400.00, 2300.00, 1.04, 1);

-- =====================================================================
-- 19. SHIPMENT
-- =====================================================================
INSERT INTO shipment
(shipment_id, shipment_no, lane_id, carrier_id, vehicle_id, origin_warehouse_id,
 dispatch_datetime, eta_datetime, actual_arrival, total_weight_kg, total_volume_m3,
 freight_cost, shipment_status) VALUES
( 1, 'SHP-2026-0001',  1, 1,  2, 1, '2026-07-03 20:15:00', '2026-07-04 03:00:00', '2026-07-04 02:40:00',    96.00,  0.650,   3240.00, 'DELIVERED'),
( 2, 'SHP-2026-0002',  7, 2,  4, 2, '2026-07-06 14:30:00', '2026-07-06 20:00:00', '2026-07-06 19:10:00',   706.50,  2.480,   9180.00, 'DELIVERED'),
( 3, 'SHP-2026-0003', 12, 5,  8, 3, '2026-07-11 08:00:00', '2026-07-11 21:30:00', '2026-07-11 22:45:00',   940.50,  3.135,  29020.00, 'DELAYED'),
( 4, 'SHP-2026-0004', 13, 2,  3, 4, '2026-07-15 06:00:00', '2026-07-16 08:00:00', NULL,                   1584.00,  2.280,  60416.00, 'IN_TRANSIT'),
( 5, 'SHP-2026-0005', 11, 1,  8, 3, '2026-07-19 07:45:00', '2026-07-19 16:15:00', NULL,                    422.60,  4.944,  20463.00, 'IN_TRANSIT'),
( 6, 'SHP-2026-0006',  2, 5,  3, 1, '2026-07-17 05:30:00', '2026-07-17 12:00:00', NULL,                  24900.00, 31.500,  17702.00, 'PLANNED'),
( 7, 'SHP-2026-0007',  6, 1,  1, 1, '2026-07-08 04:00:00', '2026-07-09 06:00:00', '2026-07-09 05:20:00',  9600.00, 12.000,  55020.00, 'DELIVERED'),
( 8, 'SHP-2026-0008',  5, 2,  1, 1, '2026-07-09 03:30:00', '2026-07-10 15:30:00', '2026-07-10 18:05:00',  5100.00,  6.500,  74648.00, 'DELAYED'),
( 9, 'SHP-2026-0009', 17, 3,  5, 1, '2026-07-11 22:00:00', '2026-07-13 16:00:00', '2026-07-13 14:20:00', 14400.00, 18.000,  38900.00, 'DELIVERED'),
(10, 'SHP-2026-0010', 20, 2, 10, 2, '2026-07-13 09:00:00', '2026-07-16 11:00:00', NULL,                   1920.00,  2.400, 132720.00, 'IN_TRANSIT');

-- =====================================================================
-- 20. SHIPMENT_LINE
-- =====================================================================
INSERT INTO shipment_line (shipment_line_id, shipment_id, order_line_id, quantity_shipped) VALUES
( 1, 1,  4,  300),
( 2, 1,  5,  500),
( 3, 2,  8,  600),
( 4, 2,  9,  250),
( 5, 2, 10, 3000),
( 6, 3, 13, 5000),
( 7, 3, 14,  450),
( 8, 4, 17,  300),
( 9, 4, 18,  800),
(10, 5, 26,   22),
(11, 5, 27,  260),
(12, 6, 22, 1500),
(13, 6, 23, 2000);

-- =====================================================================
-- 21. STOCK_TRANSFER   (network rebalancing moves)
-- =====================================================================
INSERT INTO stock_transfer
(transfer_id, from_warehouse_id, to_warehouse_id, product_id, quantity, transfer_date,
 shipment_id, transfer_cost, transfer_status) VALUES
(1, 1, 5,  6, 2000, '2026-07-08',  7,  55020.00, 'RECEIVED'),
(2, 1, 4,  7,  500, '2026-07-09',  8,  74648.00, 'RECEIVED'),
(3, 1, 2,  6, 3000, '2026-07-11',  9,  38900.00, 'RECEIVED'),
(4, 2, 7,  6,  400, '2026-07-13', 10, 132720.00, 'IN_TRANSIT'),
(5, 3, 6,  2,  450, '2026-07-20', NULL, 26800.00, 'APPROVED'),
(6, 6, 5,  9, 3500, '2026-07-22', NULL, 19400.00, 'REQUESTED');

-- =====================================================================
-- 22. OPTIMIZATION_SCENARIO
-- =====================================================================
INSERT INTO optimization_scenario
(scenario_id, scenario_name, description, planning_horizon_days, demand_growth_pct,
 fuel_price_index, max_warehouses_allowed, service_level_target) VALUES
(1, 'Baseline FY2026 Network',  'Current 7-node active network, no structural change',           90,  0.00, 1.000, NULL, 95.00),
(2, 'Peak Season Surge +25%',   'Festive demand uplift applied across all regions',              60, 25.00, 1.120,    8, 97.00),
(3, 'Fuel Shock Stress Test',   'Diesel price index +38 percent, road lanes penalised',          90,  5.00, 1.380,    7, 93.00),
(4, 'Green Network 2027',       'CO2 minimisation with rail and multimodal preference',         180, 12.00, 1.050,    9, 96.00);

-- =====================================================================
-- 23. OPTIMIZATION_RUN   (savings_pct is a GENERATED column)
-- =====================================================================
INSERT INTO optimization_run
(run_id, scenario_id, run_label, objective, algorithm, run_datetime,
 baseline_cost, optimized_cost, iterations, runtime_seconds, run_status) VALUES
(1, 1, 'Baseline MILP Run',            'MIN_TOTAL_COST',    'MILP',                '2026-07-20 02:00:00', 48250000.00, 44180000.00,  1420, 186.420, 'CONVERGED'),
(2, 1, 'Baseline GA Benchmark',        'MIN_TOTAL_COST',    'GENETIC_ALGORITHM',   '2026-07-20 03:10:00', 48250000.00, 44962000.00,  5000, 412.880, 'CONVERGED'),
(3, 2, 'Peak Season MILP',             'MIN_TOTAL_COST',    'MILP',                '2026-07-21 01:30:00', 61840000.00, 55106000.00,  1980, 254.110, 'CONVERGED'),
(4, 2, 'Peak Season Service Max',      'MAX_SERVICE_LEVEL', 'SIMULATED_ANNEALING', '2026-07-21 04:45:00', 61840000.00, 58472000.00, 12000, 320.760, 'CONVERGED'),
(5, 3, 'Fuel Shock MILP',              'MIN_TOTAL_COST',    'MILP',                '2026-07-22 02:15:00', 57390000.00, 50914000.00,  2240, 298.530, 'CONVERGED'),
(6, 4, 'Green Network CO2 Minimise',   'MIN_CO2',           'PARTICLE_SWARM',      '2026-07-23 03:00:00', 44180000.00, 42335000.00,  8000, 511.240, 'CONVERGED'),
(7, 4, 'Green Network Trial (9 nodes)','MULTI_OBJECTIVE',   'MILP',                '2026-07-23 06:20:00', 44180000.00, 44180000.00,     0,  60.000, 'INFEASIBLE');

-- =====================================================================
-- 24. OPTIMIZATION_RESULT   (the actual recommendations)
-- =====================================================================
INSERT INTO optimization_result
(result_id, run_id, warehouse_id, product_id, recommended_action, recommended_qty,
 projected_saving, confidence_score, rationale) VALUES
( 1, 1, 8, NULL, 'OPEN_NEW',        NULL, 3820000.00, 88.50, 'Indore DC cuts central-region line-haul distance by 21 percent'),
( 2, 1, 5, NULL, 'CLOSE_FACILITY',  NULL, 1160000.00, 74.20, 'Nagpur cross-dock volume fully absorbed by proposed Indore DC'),
( 3, 1, 1,    6, 'REDUCE_STOCK',    9000,  268000.00, 91.30, 'Delhi carries 42 days cover against a 21-day policy target'),
( 4, 1, 7,    9, 'INCREASE_STOCK',  6500,  142000.00, 86.70, 'Guwahati stock-out probability 18 percent at current reorder point'),
( 5, 1, 3, NULL, 'KEEP_OPEN',       NULL,       0.00, 95.00, 'Bengaluru FC at 60 percent utilisation, economically optimal'),
( 6, 2, 8, NULL, 'OPEN_NEW',        NULL, 3510000.00, 80.60, 'GA reached same siting decision as MILP with a 1.8 percent cost gap'),
( 7, 2, 5, NULL, 'CLOSE_FACILITY',  NULL, 1090000.00, 71.40, 'Consistent with MILP recommendation for the same scenario'),
( 8, 3, 2,    6, 'INCREASE_STOCK', 15000,  610000.00, 89.40, 'Festive uplift of 25 percent breaches Mumbai safety stock in week 3'),
( 9, 3, 6,    9, 'INCREASE_STOCK', 12000,  445000.00, 87.10, 'Hyderabad pharma demand peaks 31 percent above baseline'),
(10, 3, 4, NULL, 'REALLOCATE',      NULL,  372000.00, 82.60, 'Shift 18 percent of east-region volume from Kolkata to Guwahati'),
(11, 5, 1, NULL, 'RE_ROUTE',        NULL, 1284000.00, 90.20, 'Move Delhi-Mumbai trunk from road to rail at fuel index 1.38'),
(12, 5, 2, NULL, 'RE_ROUTE',        NULL,  968000.00, 88.90, 'Mumbai-Bengaluru switched to multimodal for a 14 percent freight saving'),
(13, 5, 5, NULL, 'CLOSE_FACILITY',  NULL, 1420000.00, 79.30, 'Cross-dock unit economics turn negative under the fuel shock'),
(14, 6, 1, NULL, 'RE_ROUTE',        NULL,  845000.00, 84.50, 'Rail substitution avoids an estimated 312 tonnes CO2 per quarter'),
(15, 6, 8, NULL, 'OPEN_NEW',        NULL,  690000.00, 81.20, 'Indore node shortens the average delivery leg by 186 km'),
(16, 6, 3,    3, 'REALLOCATE',      1200,  118000.00, 77.80, 'Consolidate earbud inventory at Bengaluru for southern demand');

-- =====================================================================
-- 25. KPI_SNAPSHOT
-- =====================================================================
INSERT INTO kpi_snapshot
(snapshot_id, warehouse_id, snapshot_date, inventory_turnover, order_fill_rate_pct,
 on_time_delivery_pct, capacity_utilization_pct, cost_per_order, carrying_cost) VALUES
( 1, 1, '2026-06-30',  8.40, 96.20, 93.50, 72.30, 412.50, 8620000.00),
( 2, 1, '2026-07-31',  8.75, 97.10, 94.80, 74.97, 398.20, 8940000.00),
( 3, 2, '2026-06-30',  7.60, 94.80, 91.20, 41.20, 468.90, 6980000.00),
( 4, 2, '2026-07-31',  7.95, 95.60, 92.40, 43.66, 452.30, 7210000.00),
( 5, 3, '2026-06-30',  9.20, 97.60, 95.40, 57.40, 356.80, 5740000.00),
( 6, 3, '2026-07-31',  9.65, 98.20, 96.10, 59.85, 341.60, 5920000.00),
( 7, 4, '2026-06-30',  6.80, 92.40, 88.70, 53.10, 502.40, 4180000.00),
( 8, 4, '2026-07-31',  7.05, 93.10, 89.90, 55.89, 489.70, 4310000.00),
( 9, 5, '2026-06-30', 11.40, 89.60, 86.20, 50.60, 289.30, 1240000.00),
(10, 5, '2026-07-31', 11.80, 88.40, 84.90, 52.73, 296.70, 1310000.00),
(11, 6, '2026-06-30',  8.10, 95.30, 92.80, 59.30, 421.60, 5260000.00),
(12, 6, '2026-07-31',  8.45, 96.00, 93.60, 61.98, 408.90, 5440000.00),
(13, 7, '2026-06-30',  5.20, 86.70, 82.40, 29.40, 648.20,  780000.00),
(14, 7, '2026-07-31',  5.60, 88.90, 85.10, 31.83, 621.40,  840000.00);

-- =====================================================================
-- 26. APP_USER
-- =====================================================================
INSERT INTO app_user
(user_id, username, full_name, email, password_hash, user_role, warehouse_id, is_active) VALUES
(1, 'admin',     'Aayushman Ghatak', 'admin@wnos.example.com',         '$2b$12$SAMPLEHASHADMIN00000000000000000000000000000000000000', 'ADMIN',             NULL, 1),
(2, 'nplanner1', 'Ritika Sharma',    'ritika.sharma@wnos.example.com', '$2b$12$SAMPLEHASHPLANNER0000000000000000000000000000000000000', 'NETWORK_PLANNER',   NULL, 1),
(3, 'whm.del',   'Arjun Mehta',      'arjun.mehta@wnos.example.com',   '$2b$12$SAMPLEHASHWHMDEL000000000000000000000000000000000000000', 'WAREHOUSE_MANAGER',    1, 1),
(4, 'whm.mum',   'Priya Nair',       'priya.nair@wnos.example.com',    '$2b$12$SAMPLEHASHWHMMUM000000000000000000000000000000000000000', 'WAREHOUSE_MANAGER',    2, 1),
(5, 'whm.blr',   'Karthik Rao',      'karthik.rao@wnos.example.com',   '$2b$12$SAMPLEHASHWHMBLR000000000000000000000000000000000000000', 'WAREHOUSE_MANAGER',    3, 1),
(6, 'analyst1',  'Sneha Das',        'sneha.das@wnos.example.com',     '$2b$12$SAMPLEHASHANALYST0000000000000000000000000000000000000', 'ANALYST',           NULL, 1),
(7, 'viewer1',   'Rahul Verma',      'rahul.verma@wnos.example.com',   '$2b$12$SAMPLEHASHVIEWER00000000000000000000000000000000000000', 'VIEWER',               4, 0);

-- =====================================================================
-- POST-LOAD DML : derive order_value from the order lines
-- =====================================================================
UPDATE customer_order co
JOIN (
        SELECT order_id, SUM(line_amount) AS total
        FROM   order_line
        GROUP  BY order_id
     ) t ON t.order_id = co.order_id
SET    co.order_value = t.total;

-- Reserve stock at the allocated warehouse for every order not yet shipped
UPDATE inventory i
JOIN (
        SELECT f.warehouse_id,
               ol.product_id,
               SUM(ol.quantity) AS qty_to_reserve
        FROM   order_line       ol
        JOIN   customer_order   co ON co.order_id = ol.order_id
        JOIN   order_fulfilment f  ON f.order_id  = ol.order_id
        WHERE  co.order_status = 'ALLOCATED'
        GROUP  BY f.warehouse_id, ol.product_id
     ) r ON r.warehouse_id = i.warehouse_id
        AND r.product_id   = i.product_id
SET    i.qty_reserved = i.qty_reserved + r.qty_to_reserve;

-- Flag the cross-dock as INACTIVE only if an optimizer run recommended closure
UPDATE warehouse w
SET    w.status = 'INACTIVE'
WHERE  w.warehouse_id IN (
           SELECT warehouse_id FROM (
               SELECT r.warehouse_id
               FROM   optimization_result r
               JOIN   optimization_run    o ON o.run_id = r.run_id
               WHERE  r.recommended_action = 'CLOSE_FACILITY'
               AND    o.run_status = 'CONVERGED'
               GROUP  BY r.warehouse_id
               HAVING COUNT(*) >= 3
           ) x
       );

COMMIT;

-- =====================================================================
-- QUICK VERIFICATION OF LOADED VOLUMES
-- =====================================================================
SELECT 'region' AS table_name, COUNT(*) AS row_count FROM region
UNION ALL SELECT 'location',              COUNT(*) FROM location
UNION ALL SELECT 'warehouse',             COUNT(*) FROM warehouse
UNION ALL SELECT 'warehouse_zone',        COUNT(*) FROM warehouse_zone
UNION ALL SELECT 'product_category',      COUNT(*) FROM product_category
UNION ALL SELECT 'product',               COUNT(*) FROM product
UNION ALL SELECT 'supplier',              COUNT(*) FROM supplier
UNION ALL SELECT 'supplier_product',      COUNT(*) FROM supplier_product
UNION ALL SELECT 'customer',              COUNT(*) FROM customer
UNION ALL SELECT 'inventory',             COUNT(*) FROM inventory
UNION ALL SELECT 'inventory_transaction', COUNT(*) FROM inventory_transaction
UNION ALL SELECT 'customer_order',        COUNT(*) FROM customer_order
UNION ALL SELECT 'order_line',            COUNT(*) FROM order_line
UNION ALL SELECT 'order_fulfilment',      COUNT(*) FROM order_fulfilment
UNION ALL SELECT 'demand_forecast',       COUNT(*) FROM demand_forecast
UNION ALL SELECT 'carrier',               COUNT(*) FROM carrier
UNION ALL SELECT 'vehicle',               COUNT(*) FROM vehicle
UNION ALL SELECT 'transport_lane',        COUNT(*) FROM transport_lane
UNION ALL SELECT 'shipment',              COUNT(*) FROM shipment
UNION ALL SELECT 'shipment_line',         COUNT(*) FROM shipment_line
UNION ALL SELECT 'stock_transfer',        COUNT(*) FROM stock_transfer
UNION ALL SELECT 'optimization_scenario', COUNT(*) FROM optimization_scenario
UNION ALL SELECT 'optimization_run',      COUNT(*) FROM optimization_run
UNION ALL SELECT 'optimization_result',   COUNT(*) FROM optimization_result
UNION ALL SELECT 'kpi_snapshot',          COUNT(*) FROM kpi_snapshot
UNION ALL SELECT 'app_user',              COUNT(*) FROM app_user;

-- =====================================================================
-- END OF DML
-- =====================================================================
