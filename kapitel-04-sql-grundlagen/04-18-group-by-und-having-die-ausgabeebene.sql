-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „GROUP BY und HAVING: die Ausgabeebene festlegen“ · Codeblock 18

SELECT warehouse_id, COUNT(*) AS order_count,
       SUM(order_amount_eur) AS betrag_eur
FROM orders
GROUP BY warehouse_id
ORDER BY warehouse_id;
