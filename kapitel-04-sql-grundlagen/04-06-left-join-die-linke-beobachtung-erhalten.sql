-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „LEFT JOIN: die linke Beobachtung erhalten“ · Codeblock 6

SELECT p.warehouse_id, p.product_id, p.quantity,
       r.price, p.quantity * r.price AS value_eur
FROM inventory_snapshots AS p
LEFT JOIN selected_product_prices AS r
  ON r.product_id = p.product_id
 AND r.price_date = p.snapshot_date
 AND r.currency = 'EUR'
ORDER BY p.warehouse_id, p.product_id;
