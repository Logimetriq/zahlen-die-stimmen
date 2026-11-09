-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „Dreiwertige Logik und WHERE“ · Codeblock 3

SELECT warehouse_id, price
FROM inventory_price_check
WHERE price > 0
ORDER BY warehouse_id;
