-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „Fan-out: richtige Paare, falsche Bestandssumme“ · Codeblock 12

SELECT t.order_id, p.warehouse_id, p.product_id,
       p.quantity * r.price AS value_eur
FROM orders AS t
INNER JOIN inventory_snapshots AS p
  ON p.warehouse_id = t.warehouse_id
 AND p.product_id = t.product_id
 AND p.snapshot_date = DATE '2026-09-14'
INNER JOIN selected_product_prices AS r
  ON r.product_id = p.product_id
 AND r.price_date = p.snapshot_date
 AND r.currency = 'EUR'
WHERE t.warehouse_id = 301
ORDER BY t.order_id;
