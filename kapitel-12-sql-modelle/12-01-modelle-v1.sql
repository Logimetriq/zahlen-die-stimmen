-- Kapitel 12 · Schritt 2: Modellversion 1.0 aufbauen (Zwischenmodelle, Dimensionen, Facts, Ausgaben).
-- Enthält den Abschnitt „Quellabbildung und Zwischenmodelle begrenzen“ (int_inventory_valuation).
-- Aufruf:  psql -d zahlen_die_stimmen -f kapitel-12-sql-modelle/12-01-modelle-v1.sql

\set ON_ERROR_STOP on
SET search_path TO m04;
SET TIME ZONE 'UTC';
CREATE TABLE control_catalog(reference jsonb NOT NULL);
CREATE VIEW int_order_metrics AS
SELECT *, (received_at AT TIME ZONE 'UTC')::date AS received_date,
 (processed_at AT TIME ZONE 'UTC')::date AS processed_date,
 EXTRACT(EPOCH FROM processed_at-received_at)/60 AS duration_min
FROM src_orders;
CREATE VIEW int_inventory_valuation AS
SELECT *, quantity * price AS calculated_value_eur FROM src_inventory;
CREATE TABLE dim_customer AS SELECT * FROM src_customers;
ALTER TABLE dim_customer ADD PRIMARY KEY(customer_id);
CREATE TABLE dim_warehouse AS SELECT * FROM src_warehouses;
ALTER TABLE dim_warehouse ADD PRIMARY KEY(warehouse_id);
CREATE TABLE dim_product AS SELECT * FROM src_products;
ALTER TABLE dim_product ADD PRIMARY KEY(product_id);
CREATE TABLE dim_date AS
SELECT calendar_date, to_char(calendar_date,'YYYY-MM') AS calendar_month
FROM (SELECT received_date AS calendar_date FROM int_order_metrics
 UNION SELECT processed_date FROM int_order_metrics
 UNION SELECT snapshot_date FROM int_inventory_valuation) d;
ALTER TABLE dim_date ADD PRIMARY KEY(calendar_date);
CREATE TABLE fact_orders AS SELECT * FROM int_order_metrics;
ALTER TABLE fact_orders ADD PRIMARY KEY(order_id),
 ADD FOREIGN KEY(customer_id) REFERENCES dim_customer,
 ADD FOREIGN KEY(warehouse_id) REFERENCES dim_warehouse,
 ADD FOREIGN KEY(product_id) REFERENCES dim_product,
 ADD FOREIGN KEY(received_date) REFERENCES dim_date,
 ADD FOREIGN KEY(processed_date) REFERENCES dim_date;
ALTER TABLE fact_orders ALTER order_amount_eur SET NOT NULL,
 ALTER revision_id SET NOT NULL, ALTER available_at SET NOT NULL,
 ALTER customer_id SET NOT NULL, ALTER warehouse_id SET NOT NULL,
 ALTER product_id SET NOT NULL, ALTER received_date SET NOT NULL,
 ALTER processed_date SET NOT NULL, ALTER received_at SET NOT NULL,
 ALTER processed_at SET NOT NULL, ALTER duration_min SET NOT NULL,
 ALTER processing_group SET NOT NULL, ALTER event_at SET NOT NULL,
 ALTER currency SET NOT NULL, ADD CHECK(currency='EUR'),
 ADD CHECK(processed_at>=received_at), ADD CHECK(duration_min>=0),
 ADD CHECK(available_at <= '2026-09-15T06:00:00Z'::timestamptz);
CREATE TABLE fact_inventory_snapshots AS
SELECT warehouse_id,product_id,snapshot_date,quantity,price,
 calculated_value_eur AS inventory_value_eur, 'EUR'::text AS currency
FROM int_inventory_valuation;
ALTER TABLE fact_inventory_snapshots
 ADD PRIMARY KEY(warehouse_id,product_id,snapshot_date),
 ADD FOREIGN KEY(warehouse_id) REFERENCES dim_warehouse,
 ADD FOREIGN KEY(product_id) REFERENCES dim_product,
 ADD FOREIGN KEY(snapshot_date) REFERENCES dim_date,
 ALTER quantity SET NOT NULL, ALTER currency SET NOT NULL, ADD CHECK(currency='EUR');
CREATE VIEW operations_summary AS
WITH o AS (
 SELECT warehouse_id,product_id,received_date AS analysis_date,
 COUNT(*) AS order_count,SUM(order_amount_eur) AS order_amount_eur,
 SUM(duration_min) AS duration_sum_min,COUNT(duration_min) AS duration_count
 FROM fact_orders GROUP BY warehouse_id,product_id,received_date
), i AS (
 SELECT warehouse_id,product_id,snapshot_date AS analysis_date,
 SUM(inventory_value_eur) AS known_value_eur,
 COUNT(*) AS inventory_rows,COUNT(inventory_value_eur) AS valued_rows
 FROM fact_inventory_snapshots GROUP BY warehouse_id,product_id,snapshot_date
), keys AS (
 SELECT warehouse_id,product_id,analysis_date FROM o
 UNION SELECT warehouse_id,product_id,analysis_date FROM i
)
SELECT k.*,COALESCE(o.order_count,0) AS order_count,
 COALESCE(o.order_amount_eur,0) AS order_amount_eur,
 o.duration_sum_min,o.duration_count,i.known_value_eur,i.inventory_rows,i.valued_rows,
 CASE WHEN i.inventory_rows=i.valued_rows THEN i.known_value_eur END AS full_value_eur
FROM keys k LEFT JOIN o USING(warehouse_id,product_id,analysis_date)
LEFT JOIN i USING(warehouse_id,product_id,analysis_date);
CREATE VIEW operations_view AS
SELECT o.*,w.warehouse_name,p.product_name,c.customer_name,
 '2026-09-15T06:00:00Z'::timestamptz AS knowledge_cutoff
FROM fact_orders o JOIN dim_warehouse w USING(warehouse_id)
JOIN dim_product p USING(product_id) JOIN dim_customer c USING(customer_id);
CREATE VIEW quality_status AS
SELECT 'CH07-original-H0'::text AS data_state,
 '2026-09-15T06:00:00Z'::timestamptz AS knowledge_cutoff,
 'M04-PRICE-COMPLETE'::text AS rule_id,'fact_inventory_snapshots'::text AS checked_object,
 warehouse_id,'observed warehouse/product/day rows'::text AS population,
 COUNT(*) AS checked_denominator,COUNT(*)-COUNT(inventory_value_eur) AS missing_count,
 CASE WHEN COUNT(*)=COUNT(inventory_value_eur) THEN 'INFO' ELSE 'WARNING' END AS severity,
 CASE WHEN COUNT(*)=COUNT(inventory_value_eur) THEN 'PASS' ELSE 'LIMITED' END AS status,
 'Mara; Leon; Aylin'::text AS owner,
 CASE WHEN COUNT(*)=COUNT(inventory_value_eur) THEN 'Use checked known value'
 ELSE 'Aylin informs Leon/Mara before publication; Leon confirms next response by 08:00 UTC; escalate to Mara if absent; full value unknown' END AS planned_reaction
FROM fact_inventory_snapshots GROUP BY warehouse_id
UNION ALL
SELECT 'CH07-original-H0','2026-09-15T06:00:00Z'::timestamptz,
 'M04-ORDER-GRAIN','operations_view',NULL,'selected orders 4711-4714',COUNT(*),
 COUNT(*)-COUNT(DISTINCT order_id),
 CASE WHEN COUNT(*)=COUNT(DISTINCT order_id) THEN 'INFO' ELSE 'ERROR' END,
 CASE WHEN COUNT(*)=COUNT(DISTINCT order_id) THEN 'PASS' ELSE 'FAIL' END,
 'Aylin; Leon; Mara','FAIL blocks publication; investigate keys and joins'
FROM operations_view
UNION ALL
SELECT 'CH07-original-H0','2026-09-15T06:00:00Z'::timestamptz,
 rule_id,checked_object,NULL,population,denominator,deviation,
 CASE WHEN deviation=0 THEN 'INFO' ELSE 'ERROR' END,
 CASE WHEN deviation=0 THEN 'PASS' ELSE 'FAIL' END,
 'Aylin; Leon; Mara','FAIL blocks publication; Aylin documents, Leon investigates, Mara decides checked use'
FROM (
 SELECT 'M04-REFERENCES'::text AS rule_id,'facts/dimensions'::text AS checked_object,
 '4 orders and 2 snapshots'::text AS population,6::bigint AS denominator,
 (SELECT COUNT(*) FROM fact_orders o LEFT JOIN dim_customer c USING(customer_id)
 LEFT JOIN dim_warehouse w USING(warehouse_id) LEFT JOIN dim_product p USING(product_id)
 WHERE c.customer_id IS NULL OR w.warehouse_id IS NULL OR p.product_id IS NULL)
 +(SELECT COUNT(*) FROM fact_inventory_snapshots i LEFT JOIN dim_warehouse w USING(warehouse_id)
 LEFT JOIN dim_product p USING(product_id) WHERE w.warehouse_id IS NULL OR p.product_id IS NULL) AS deviation
 UNION ALL
 SELECT 'M04-REVISION','fact_orders','4 original selected revisions',4,
 COUNT(*) FILTER(WHERE revision_id<>'1' OR available_at>'2026-09-15T06:00:00Z'::timestamptz) FROM fact_orders
 UNION ALL
 SELECT 'M04-SUMMARY-GRAIN','operations_summary','warehouse/product/day groups',COUNT(*),
 COUNT(*)-COUNT(DISTINCT (warehouse_id,product_id,analysis_date)) FROM operations_summary
 UNION ALL
 SELECT 'M04-INVENTORY-GRAIN','fact_inventory_snapshots','2 snapshot identities',2,
 COUNT(*)-COUNT(DISTINCT (warehouse_id,product_id,snapshot_date)) FROM fact_inventory_snapshots
 UNION ALL
 SELECT 'M04-POPULATION','facts','4 order identities and 2 snapshot identities',6,
 ABS(4-(SELECT COUNT(*) FROM fact_orders))+ABS(2-(SELECT COUNT(*) FROM fact_inventory_snapshots))
 UNION ALL
 SELECT 'M04-SOURCE-VALUES','facts/source mapping','6 prepared selected source rows',6,
 (SELECT COUNT(*) FROM fact_orders f FULL JOIN int_order_metrics s USING(order_id)
 WHERE f.order_id IS NULL OR s.order_id IS NULL OR f.order_amount_eur IS DISTINCT FROM s.order_amount_eur
 OR f.duration_min IS DISTINCT FROM s.duration_min OR f.product_id IS DISTINCT FROM s.product_id
 OR f.warehouse_id IS DISTINCT FROM s.warehouse_id OR f.customer_id IS DISTINCT FROM s.customer_id)
 +(SELECT COUNT(*) FROM fact_inventory_snapshots f FULL JOIN int_inventory_valuation s USING(warehouse_id,product_id,snapshot_date)
 WHERE f.warehouse_id IS NULL OR s.warehouse_id IS NULL OR f.quantity IS DISTINCT FROM s.quantity
 OR f.inventory_value_eur IS DISTINCT FROM s.inventory_value_eur)
 UNION ALL
 SELECT 'M04-INDEPENDENT-RECONCILIATION','facts/M01-CH10-control','6 independently fixed reference identities and values',6,
 (SELECT COUNT(*) FROM fact_orders f FULL JOIN
 jsonb_to_recordset((SELECT reference->'orders' FROM control_catalog))
 AS e(order_id text,revision_id text,customer_id text,warehouse_id text,product_id text,order_amount_eur numeric,currency text,duration_min numeric)
 USING(order_id)
 WHERE f.order_id IS NULL OR e.order_id IS NULL OR f.revision_id IS DISTINCT FROM e.revision_id
 OR f.customer_id IS DISTINCT FROM e.customer_id OR f.warehouse_id IS DISTINCT FROM e.warehouse_id
 OR f.product_id IS DISTINCT FROM e.product_id OR f.order_amount_eur IS DISTINCT FROM e.order_amount_eur
 OR f.currency IS DISTINCT FROM e.currency OR f.duration_min IS DISTINCT FROM e.duration_min)
 +(SELECT COUNT(*) FROM fact_inventory_snapshots f FULL JOIN
 jsonb_to_recordset((SELECT reference->'inventory' FROM control_catalog))
 AS e(warehouse_id text,product_id text,snapshot_date date,quantity integer,currency text,price numeric,value_eur numeric)
 USING(warehouse_id,product_id,snapshot_date)
 WHERE f.warehouse_id IS NULL OR e.warehouse_id IS NULL OR f.quantity IS DISTINCT FROM e.quantity
 OR f.price IS DISTINCT FROM e.price OR f.inventory_value_eur IS DISTINCT FROM e.value_eur OR f.currency IS DISTINCT FROM e.currency)
) checks;

-- Unabhängig festgelegter Kontrollkatalog (Soll aus Kapitel 10) für die Qualitätsausgabe:
INSERT INTO control_catalog VALUES ('{"origin": "Manuell festgeschrieben aus book/running-case.md Kleiner Referenzfall und CH03 Preisprüfung; keine Ausgabe der Transformationen", "contract": {"population": "four_reference_orders", "grain": "order_id", "key_meaning": "business_order", "business_date": "2026-09-14", "cutoff": "2026-09-15T06:00:00Z", "currency": "EUR", "unit": "EUR", "scaling": "1", "metric": "order_amount_eur"}, "references": {"customer_id": ["101", "102"], "warehouse_id": ["301", "302"], "product_id": ["201", "202"]}, "orders": [{"order_id": "4711", "revision_id": "1", "customer_id": "101", "warehouse_id": "301", "product_id": "201", "order_amount_eur": "100.00", "currency": "EUR", "duration_min": "30.00"}, {"order_id": "4712", "revision_id": "1", "customer_id": "102", "warehouse_id": "301", "product_id": "201", "order_amount_eur": "200.00", "currency": "EUR", "duration_min": "90.00"}, {"order_id": "4713", "revision_id": "1", "customer_id": "101", "warehouse_id": "302", "product_id": "202", "order_amount_eur": "300.00", "currency": "EUR", "duration_min": "60.00"}, {"order_id": "4714", "revision_id": "1", "customer_id": "102", "warehouse_id": "302", "product_id": "201", "order_amount_eur": "400.00", "currency": "EUR", "duration_min": "120.00"}], "inventory_contract": {"population": "two_reference_inventory_rows", "grain": "warehouse_id/product_id/snapshot_date", "key_meaning": "warehouse_product_day", "business_date": "2026-09-14", "cutoff": "2026-09-15T06:00:00Z", "currency": "EUR", "unit": "pieces;EUR_per_piece;EUR", "scaling": "1", "metric": "inventory_value_eur"}, "inventory": [{"warehouse_id": "301", "product_id": "201", "snapshot_date": "2026-09-14", "quantity": "10", "currency": "EUR", "price": "100.00", "value_eur": "1000.00"}, {"warehouse_id": "302", "product_id": "202", "snapshot_date": "2026-09-14", "quantity": "5", "currency": "EUR", "price": null, "value_eur": null}], "aggregate": {"order_count": 4, "order_sum_eur": "1000.00", "warehouse_sums": {"301": "300.00", "302": "700.00"}, "inventory_rows": 2, "valued_rows": 1, "known_value_eur": "1000.00", "full_value_eur": null}}'::jsonb);
