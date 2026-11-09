-- Kapitel 5 · SQL für komplexe Analysen
-- Abschnitt „Gewählte Preise auf die beiden Bestände anwenden“ · Codeblock 17

SELECT p.product_id, p.quantity, r.price,
       p.quantity * r.price AS wert_eur
FROM inventory_snapshots AS p
LEFT JOIN selected_product_prices AS r
  ON r.product_id = p.product_id
 AND r.price_date = p.snapshot_date AND r.currency = 'EUR'
WHERE p.snapshot_date = DATE '2026-09-14'
ORDER BY p.warehouse_id, p.product_id;
