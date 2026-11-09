-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „HAVING: Gruppen prüfen, WHERE: Eingabezeilen prüfen“ · Codeblock 20

SELECT warehouse_id, SUM(order_amount_eur) AS betrag_eur
FROM orders
GROUP BY warehouse_id
HAVING SUM(order_amount_eur) > 500
ORDER BY warehouse_id;
