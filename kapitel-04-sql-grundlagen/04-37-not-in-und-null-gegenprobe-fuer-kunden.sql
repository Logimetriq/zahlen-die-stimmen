-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „NOT IN und NULL: Gegenprobe für Kunden ohne Bestellung“ · Codeblock 37

SELECT c.customer_id
FROM customer_check_customers AS c
WHERE NOT EXISTS (
  SELECT 1 FROM customer_check_orders AS o
  WHERE o.customer_id = c.customer_id
)
ORDER BY c.customer_id;
