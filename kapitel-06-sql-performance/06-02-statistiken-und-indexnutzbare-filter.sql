-- Kapitel 6 · SQL-Performance
-- Abschnitt „Statistiken und indexnutzbare Filter beurteilen“ · Codeblock 2

SELECT order_id, order_amount_eur
FROM ch06.perf_orders
WHERE received_at >= TIMESTAMPTZ '2026-09-14 00:00:00+00'
  AND received_at < TIMESTAMPTZ '2026-09-15 00:00:00+00'
ORDER BY order_id;
