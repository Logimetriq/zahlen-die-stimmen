-- Kapitel 6 · SQL-Performance
-- Abschnitt „Join, Sortierung und Aggregation im Plan verfolgen“ · Codeblock 4

SELECT o.warehouse_id, w.warehouse_name,
       COUNT(*) AS order_count, SUM(o.order_amount_eur) AS betrag_eur
FROM ch06.perf_orders AS o
JOIN b2b.warehouses AS w ON w.warehouse_id = o.warehouse_id
WHERE o.received_at >= TIMESTAMPTZ '2026-09-14 00:00:00+00'
  AND o.received_at < TIMESTAMPTZ '2026-09-15 00:00:00+00'
GROUP BY o.warehouse_id, w.warehouse_name
ORDER BY o.warehouse_id;
