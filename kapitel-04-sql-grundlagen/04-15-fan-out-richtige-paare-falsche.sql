-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „Fan-out: richtige Paare, falsche Bestandssumme“ · Codeblock 15

SELECT SUM(p.quantity * r.price) AS bekannter_teilwert_eur
FROM inventory_snapshots AS p
LEFT JOIN selected_product_prices AS r
  ON r.product_id = p.product_id
 AND r.price_date = p.snapshot_date
 AND r.currency = 'EUR';
