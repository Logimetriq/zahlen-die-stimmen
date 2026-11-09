-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „COUNT und SUM: Zeilen sind nicht vorhandene Werte“ · Codeblock 10

SELECT COUNT(*) AS zeilen, COUNT(price) AS werte,
       SUM(price) AS summe
FROM inventory_price_check
WHERE warehouse_id = 302;
