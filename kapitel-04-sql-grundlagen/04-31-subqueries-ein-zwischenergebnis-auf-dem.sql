-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „Subqueries: ein Zwischenergebnis auf dem richtigen Grain“ · Codeblock 31

SELECT p.warehouse_id, p.product_id,
       t.order_count, t.betrag_eur,
       p.quantity * r.price AS value_eur
FROM inventory_snapshots AS p
LEFT JOIN (
  SELECT warehouse_id, product_id,
         COUNT(*) AS order_count, SUM(order_amount_eur) AS betrag_eur
  FROM orders
  GROUP BY warehouse_id, product_id
) AS t
  ON t.warehouse_id = p.warehouse_id
 AND t.product_id = p.product_id
LEFT JOIN selected_product_prices AS r
  ON r.product_id = p.product_id
 AND r.price_date = p.snapshot_date
 AND r.currency = 'EUR'
ORDER BY p.warehouse_id, p.product_id;
