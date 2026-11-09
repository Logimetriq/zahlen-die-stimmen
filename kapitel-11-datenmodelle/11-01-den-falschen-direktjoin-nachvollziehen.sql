-- Kapitel 11 · Analytische Datenmodelle und gemeinsame Kennzahlen
-- Abschnitt „Den falschen Direktjoin nachvollziehen“ · Codeblock 1

SELECT SUM(o.order_amount_eur) AS order_amount_eur,
       SUM(i.inventory_value_eur) AS inventory_value_eur
FROM order_fact AS o
JOIN inventory_fact AS i
  ON i.warehouse_id = o.warehouse_id
 AND i.product_id = o.product_id
 AND i.snapshot_date = o.received_date
WHERE o.warehouse_id = '301' AND o.product_id = '201'
  AND o.received_date = '2026-09-14';
