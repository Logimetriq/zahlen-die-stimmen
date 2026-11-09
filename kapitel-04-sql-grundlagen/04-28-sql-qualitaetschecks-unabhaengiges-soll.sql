-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „SQL-Qualitätschecks: unabhängiges Soll und konkrete Fehlmenge“ · Codeblock 28

SELECT order_id, order_amount_eur
FROM orders
ORDER BY order_id;
