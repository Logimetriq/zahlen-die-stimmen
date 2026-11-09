-- Kapitel 6 · SQL-Performance
-- Vorbereitung: legt im Schema ch06 die Tabelle perf_orders mit 100.000 erzeugten Bestellungen an.
-- Voraussetzung: einrichtung/postgresql-setup.sql ist in derselben Datenbank ausgeführt.
-- Aufruf aus dem Hauptordner:  psql -d zahlen_die_stimmen -f kapitel-06-sql-performance/06-00-vorbereitung.sql
-- Die Pläne im Buch entstanden mit den folgenden Sitzungseinstellungen. Setzen Sie sie in Ihrer
-- Sitzung erneut, bevor Sie EXPLAIN ANALYZE vergleichen:
--   SET max_parallel_workers_per_gather = 0; SET jit = off; SET work_mem = '4MB';
-- Zeiten hängen von Ihrem Rechner ab; die Planform ist der Vergleichsmaßstab.

\set ON_ERROR_STOP on
CREATE SCHEMA ch06;
CREATE TABLE ch06.perf_orders (LIKE b2b.order_revisions INCLUDING ALL);
ALTER TABLE ch06.perf_orders ADD FOREIGN KEY (customer_id) REFERENCES b2b.customers;
ALTER TABLE ch06.perf_orders ADD FOREIGN KEY (warehouse_id) REFERENCES b2b.warehouses;
ALTER TABLE ch06.perf_orders ADD FOREIGN KEY (product_id) REFERENCES b2b.products;
ALTER TABLE ch06.perf_orders SET (autovacuum_enabled = false);
INSERT INTO ch06.perf_orders
SELECT 1000000 + n, 1,
       CASE WHEN n % 2 = 1 THEN 101 ELSE 102 END,
       CASE WHEN (n - 1) % 4 < 2 THEN 301 ELSE 302 END,
       CASE WHEN (n - 1) % 4 = 2 THEN 202 ELSE 201 END,
       (((n - 1) % 4) + 1) * 100, 'EUR',
       t, t,
       t + CASE (n - 1) % 4
             WHEN 0 THEN INTERVAL '30 minutes'
             WHEN 1 THEN INTERVAL '90 minutes'
             WHEN 2 THEN INTERVAL '60 minutes'
             ELSE INTERVAL '120 minutes' END,
       date_trunc('day', t) + INTERVAL '1 day 5 hours',
       CASE WHEN n % 2 = 1 THEN 'STANDARD' ELSE 'PRUEFBEDARF' END
FROM generate_series(1, 100000) AS g(n)
CROSS JOIN LATERAL (
 SELECT TIMESTAMPTZ '2026-08-01 00:00:00+00'
        + ((n - 1) / 1000) * INTERVAL '1 day'
        + ((n - 1) % 1000) * INTERVAL '1 second' AS t
) AS times;
ANALYZE ch06.perf_orders;
ANALYZE b2b.warehouses;
ANALYZE b2b.order_revisions;
ANALYZE b2b.inventory_snapshots;
ANALYZE b2b.product_price_revisions;
