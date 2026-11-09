-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „UNION und UNION ALL: Mengen und Mehrfachvorkommen“ · Codeblock 32

SELECT order_id FROM orders
WHERE order_id IN (4711, 4712)
UNION ALL
SELECT order_id FROM orders
WHERE order_id IN (4712, 4713)
ORDER BY order_id;
