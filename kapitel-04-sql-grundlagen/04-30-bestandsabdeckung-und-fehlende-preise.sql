-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „Bestandsabdeckung und fehlende Preise“ · Codeblock 30

SELECT p.warehouse_id, p.product_id, p.snapshot_date
FROM inventory_snapshots AS p
LEFT JOIN selected_product_prices AS r
  ON r.product_id = p.product_id
 AND r.price_date = p.snapshot_date
 AND r.currency = 'EUR'
WHERE r.product_id IS NULL
ORDER BY p.warehouse_id, p.product_id;
