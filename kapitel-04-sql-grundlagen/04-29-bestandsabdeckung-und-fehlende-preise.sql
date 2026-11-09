-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „Bestandsabdeckung und fehlende Preise“ · Codeblock 29

SELECT COUNT(*) AS inventory_rows, COUNT(r.price) AS bewertet,
       COUNT(*) - COUNT(r.price) AS unbewertet,
       SUM(p.quantity * r.price) AS teilwert_eur,
       CASE WHEN COUNT(*) > 0
                 AND COUNT(r.price) = COUNT(*)
            THEN SUM(p.quantity * r.price)
            ELSE NULL END AS vollwert_eur
FROM inventory_snapshots AS p
LEFT JOIN selected_product_prices AS r
  ON r.product_id = p.product_id
 AND r.price_date = p.snapshot_date
 AND r.currency = 'EUR';
