-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „SQL-Qualitätschecks: unabhängiges Soll und konkrete Fehlmenge“ · Codeblock 27

SELECT COUNT(*) AS order_count, SUM(order_amount_eur) AS betrag_eur
FROM orders;
