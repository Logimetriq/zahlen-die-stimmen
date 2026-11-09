-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „Fan-out: richtige Paare, falsche Bestandssumme“ · Codeblock 13

SELECT SUM(p.quantity * r.price) AS falscher_wert_eur
FROM orders AS t
INNER JOIN inventory_snapshots AS p
  ON p.warehouse_id = t.warehouse_id
 AND p.product_id = t.product_id
 AND p.snapshot_date = DATE '2026-09-14'
INNER JOIN selected_product_prices AS r
  ON r.product_id = p.product_id
 AND r.price_date = p.snapshot_date
 AND r.currency = 'EUR'
WHERE t.warehouse_id = 301;
