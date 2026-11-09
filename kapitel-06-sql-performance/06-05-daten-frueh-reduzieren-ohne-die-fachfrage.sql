-- Kapitel 6 · SQL-Performance
-- Abschnitt „Daten früh reduzieren, ohne die Fachfrage zu ändern“ · Codeblock 5

WITH totals AS (
  SELECT warehouse_id, COUNT(*) AS order_count,
         SUM(order_amount_eur) AS betrag_eur
  FROM ch06.perf_orders
  WHERE received_at >= TIMESTAMPTZ '2026-09-14 00:00:00+00'
    AND received_at < TIMESTAMPTZ '2026-09-15 00:00:00+00'
  GROUP BY warehouse_id
)
SELECT t.warehouse_id, w.warehouse_name, t.order_count, t.betrag_eur
FROM totals AS t
JOIN b2b.warehouses AS w ON w.warehouse_id = t.warehouse_id
ORDER BY t.warehouse_id;
