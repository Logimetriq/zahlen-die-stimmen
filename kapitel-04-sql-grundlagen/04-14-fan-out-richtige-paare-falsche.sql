-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „Fan-out: richtige Paare, falsche Bestandssumme“ · Codeblock 14

SELECT COUNT(*) AS order_count
FROM orders
WHERE warehouse_id = 301;
