-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „NOT IN und NULL: Gegenprobe für Kunden ohne Bestellung“ · Codeblock 35

SELECT customer_id
FROM customer_check_customers
WHERE customer_id NOT IN (SELECT customer_id FROM customer_check_orders)
ORDER BY customer_id;
