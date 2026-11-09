-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „Dreiwertige Logik und WHERE“ · Codeblock 4

SELECT warehouse_id, price
FROM inventory_price_check
WHERE price IS NULL
ORDER BY warehouse_id;
