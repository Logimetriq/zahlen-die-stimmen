-- Kapitel 11 · Analytische Datenmodelle und gemeinsame Kennzahlen
-- Abschnitt „Getrennt aggregieren und erst danach verbinden“ · Codeblock 2

WITH orders_by_day AS (
  SELECT warehouse_id, product_id, received_date AS analysis_date,
         SUM(order_amount_eur) AS order_amount_eur
  FROM order_fact
  GROUP BY warehouse_id, product_id, received_date
), inventory_by_day AS (
  SELECT warehouse_id, product_id, snapshot_date AS analysis_date,
         SUM(inventory_value_eur) AS inventory_value_eur
  FROM inventory_fact
  GROUP BY warehouse_id, product_id, snapshot_date
)
SELECT o.warehouse_id, o.product_id, o.analysis_date,
       o.order_amount_eur, i.inventory_value_eur
FROM orders_by_day AS o
JOIN inventory_by_day AS i
  ON i.warehouse_id = o.warehouse_id
 AND i.product_id = o.product_id
 AND i.analysis_date = o.analysis_date
WHERE o.warehouse_id = '301' AND o.product_id = '201'
  AND o.analysis_date = '2026-09-14';
