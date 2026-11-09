-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „NULL: fehlende Information technisch erhalten“ · Codeblock 2

SELECT warehouse_id, price, price > 0 AS positiv,
       price = NULL AS falscher_nulltest,
       price IS NULL AS fehlt
FROM inventory_price_check
ORDER BY warehouse_id;
