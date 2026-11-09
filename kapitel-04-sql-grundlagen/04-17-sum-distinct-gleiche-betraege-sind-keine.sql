-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „SUM(DISTINCT ...): gleiche Beträge sind keine Identitäten“ · Codeblock 17

SELECT SUM(p.quantity * r.price) AS richtiger_wert_eur,
       SUM(DISTINCT p.quantity * r.price) AS falscher_wert_eur
FROM inventory_snapshots AS p
INNER JOIN selected_product_prices_later AS r
  ON r.product_id = p.product_id
 AND r.price_date = p.snapshot_date
 AND r.currency = 'EUR';
