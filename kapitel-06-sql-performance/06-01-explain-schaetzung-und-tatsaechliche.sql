-- Kapitel 6 · SQL-Performance
-- Abschnitt „EXPLAIN: Schätzung und tatsächliche Ausführung unterscheiden“ · Codeblock 1

SELECT order_id, order_amount_eur
FROM ch06.perf_orders
WHERE (received_at AT TIME ZONE 'UTC')::date = DATE '2026-09-14'
ORDER BY order_id;
