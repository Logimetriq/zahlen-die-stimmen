-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „NOT IN und NULL: Gegenprobe für Kunden ohne Bestellung“ · Codeblock 38

SELECT customer_id
FROM customer_check_customers
WHERE customer_id NOT IN (
  SELECT customer_id FROM customer_check_orders WHERE customer_id IS NOT NULL
)
ORDER BY customer_id;
