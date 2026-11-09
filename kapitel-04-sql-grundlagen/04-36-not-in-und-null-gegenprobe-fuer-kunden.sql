-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „NOT IN und NULL: Gegenprobe für Kunden ohne Bestellung“ · Codeblock 36

SELECT customer_id,
       customer_id NOT IN (
         SELECT customer_id FROM customer_check_orders
       ) AS ohne_bestellung
FROM customer_check_customers
ORDER BY customer_id;
