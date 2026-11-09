-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „SELECT und WHERE gezielt auffrischen“ · Codeblock 1

SELECT order_id, warehouse_id, order_amount_eur
FROM orders
WHERE warehouse_id = 301
ORDER BY order_id;
