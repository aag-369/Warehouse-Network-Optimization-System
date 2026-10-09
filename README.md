# Warehouse Network Optimization System (WNOS)

DBMS major project — complete deliverable set.
**RDBMS:** MySQL 8.0 (InnoDB) · **Schema:** `wnos`


## Contents

```
sql/
  01_schema_ddl.sql          26 CREATE TABLE + constraints + indexes + 3 views
  02_sample_data_dml.sql     339 rows of sample data + derived-value UPDATEs
  03_analysis_queries.sql    25 analytical / optimization queries

diagrams/
  architecture_diagram.*     Six-layer system architecture (PNG / PDF / SVG)
  er_diagram.png/.pdf/.svg   Full attribute-level ER diagram (crow's-foot)
  er_diagram_conceptual.*    Entity-level ER diagram, for slides
  *.dot                      Graphviz sources, if you want to edit them

presentation/
  Warehouse_Network_Optimization_System.pptx   15-slide deck (speaker notes included)
  Warehouse_Network_Optimization_System.pdf    same deck, PDF

docs/
  Database_Design_Document.md   Table-by-table reference with sample values,
                                normalisation analysis, index and FK policy
```

## How to run

```bash
mysql -u root -p < sql/01_schema_ddl.sql
mysql -u root -p < sql/02_sample_data_dml.sql
mysql -u root -p wnos < sql/03_analysis_queries.sql
```

`01` drops and recreates the `wnos` database, so run it on a scratch server.
`02` ends with a row-count query so you can confirm the load.

## Model at a glance

| | |
|---|---|
| Entities | 26 across 7 functional modules |
| Relationships (FK constraints) | 39 |
| CHECK constraints | 32 |
| Secondary indexes | 13 |
| Views | 3 |
| Generated columns | `inventory.qty_available`, `order_line.line_amount`, `optimization_run.savings_pct` |
| Sample rows loaded | 339 |
| Analytical queries | 25 |

## Verification

| Check | Result |
|---|---|
| Statements parsed in MySQL dialect | 104 / 104, 0 failures |
| Full DDL + DML executed | 0 errors |
| Foreign-key violations after load | 0 |
| Queries executed | 25 / 25, all returning rows |
| PPTX file validation | passed |

## What the queries cover

Capacity utilisation · reorder and stock-out alerts · ABC/Pareto with window functions ·
days of cover · cost to serve · cheapest mode per corridor · carrier scorecard ·
forecast accuracy (MAPE) by model · demand-weighted centre of gravity ·
Haversine nearest-warehouse assignment · optimizer run benchmarking ·
KPI trend with `LAG` · rebalancing candidates · supplier scorecard ·
EOQ and reorder-point recalculation · total network cost roll-up ·
slow-moving and dead stock · SLA breach audit · vehicle load factor ·
one-row executive dashboard.
