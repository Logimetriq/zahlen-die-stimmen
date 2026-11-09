-- Kapitel 12 · SQL-Analysemodelle wiederverwenden und kontrolliert ändern
-- Abschnitt „Consumer-Regression tatsächlich ausführen“ · Codeblock 3

SELECT COUNT(*) AS order_count,
       SUM(order_amount_eur) AS order_amount_eur,
       AVG(duration_min) AS mean_duration_min
FROM m04.operations_view;
