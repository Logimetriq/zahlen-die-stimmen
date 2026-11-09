-- Kapitel 12 · SQL-Analysemodelle wiederverwenden und kontrolliert ändern
-- Abschnitt „Consumer-Regression tatsächlich ausführen“ · Codeblock 4

SELECT order_id, inventory_price_missing
FROM m04.operations_view
ORDER BY order_id;
