-- Kapitel 5 · SQL für komplexe Analysen
-- Abschnitt „Look-ahead-Gegenprobe: das passende Datum allein reicht nicht“ · Codeblock 20

SELECT SUM(p.quantity * r.price) AS scheinwert_eur
FROM inventory_snapshots AS p JOIN product_price_revisions AS r
  ON r.product_id = p.product_id
 AND r.price_date = p.snapshot_date AND r.currency = 'EUR'
WHERE p.snapshot_date = DATE '2026-09-14';
