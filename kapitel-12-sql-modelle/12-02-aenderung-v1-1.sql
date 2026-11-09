-- Kapitel 12 · Schritt 3: additive Änderung auf Modellversion 1.1 (Abschnitt „Eine Ausnahmekennzeichnung ergänzen“).
-- Aufruf:  psql -d zahlen_die_stimmen -f kapitel-12-sql-modelle/12-02-aenderung-v1-1.sql

\set ON_ERROR_STOP on
SET search_path TO m04;
ALTER TABLE fact_inventory_snapshots ADD COLUMN inventory_price_missing boolean;
UPDATE fact_inventory_snapshots SET inventory_price_missing=(price IS NULL);
ALTER TABLE fact_inventory_snapshots ALTER inventory_price_missing SET NOT NULL;
CREATE OR REPLACE VIEW operations_summary AS
SELECT s.*
FROM (
 WITH o AS (
 SELECT warehouse_id,product_id,received_date AS analysis_date,COUNT(*) AS order_count,
 SUM(order_amount_eur) AS order_amount_eur,SUM(duration_min) AS duration_sum_min,
 COUNT(duration_min) AS duration_count FROM fact_orders GROUP BY warehouse_id,product_id,received_date
 ), i AS (
 SELECT warehouse_id,product_id,snapshot_date AS analysis_date,SUM(inventory_value_eur) AS known_value_eur,
 COUNT(*) AS inventory_rows,COUNT(inventory_value_eur) AS valued_rows,
 bool_or(inventory_price_missing) AS inventory_price_missing
 FROM fact_inventory_snapshots GROUP BY warehouse_id,product_id,snapshot_date
 ), keys AS (SELECT warehouse_id,product_id,analysis_date FROM o UNION SELECT warehouse_id,product_id,analysis_date FROM i)
 SELECT k.*,COALESCE(o.order_count,0) AS order_count,COALESCE(o.order_amount_eur,0) AS order_amount_eur,
 o.duration_sum_min,o.duration_count,i.known_value_eur,i.inventory_rows,i.valued_rows,
 CASE WHEN i.inventory_rows=i.valued_rows THEN i.known_value_eur END AS full_value_eur,
 i.inventory_price_missing
 FROM keys k LEFT JOIN o USING(warehouse_id,product_id,analysis_date) LEFT JOIN i USING(warehouse_id,product_id,analysis_date)
) s;
CREATE OR REPLACE VIEW operations_view AS
SELECT o.*,w.warehouse_name,p.product_name,c.customer_name,
 '2026-09-15T06:00:00Z'::timestamptz AS knowledge_cutoff,
 s.inventory_price_missing
FROM fact_orders o JOIN dim_warehouse w USING(warehouse_id)
JOIN dim_product p USING(product_id) JOIN dim_customer c USING(customer_id)
LEFT JOIN operations_summary s ON s.warehouse_id=o.warehouse_id AND s.product_id=o.product_id AND s.analysis_date=o.received_date;
