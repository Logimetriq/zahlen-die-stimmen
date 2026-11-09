-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „COUNT und SUM: Zeilen sind nicht vorhandene Werte“ · Codeblock 9

SELECT COUNT(*) AS inventory_rows, COUNT(price) AS preise,
       SUM(price) AS preissumme
FROM inventory_price_check;
