-- Kapitel 5 · SQL für komplexe Analysen
-- Abschnitt „Gewählte Preise auf die beiden Bestände anwenden“ · Codeblock 18
-- Vollständige Abfrage; das Buch zeigt davon einen Ausschnitt.

WITH zulaessige_revisionen AS (
  SELECT * FROM product_price_revisions
  WHERE price_date = DATE '2026-09-14' AND currency = 'EUR'
    AND available_at <= TIMESTAMPTZ '2026-09-15 06:00:00+00'
), rangierte_revisionen AS (
  SELECT *, ROW_NUMBER() OVER (
    PARTITION BY product_id, price_date, currency
    ORDER BY available_at DESC, revision_id DESC
  ) AS rn
  FROM zulaessige_revisionen
), gewaehlte_revision AS (
  SELECT * FROM rangierte_revisionen WHERE rn = 1
), inventory_values AS (
  SELECT p.warehouse_id, p.product_id, p.snapshot_date, p.quantity,
         r.revision_id, r.price, p.quantity * r.price AS wert_eur
  FROM inventory_snapshots AS p LEFT JOIN gewaehlte_revision AS r
    ON r.product_id = p.product_id
   AND r.price_date = p.snapshot_date AND r.currency = 'EUR'
  WHERE p.snapshot_date = DATE '2026-09-14'
)
SELECT COUNT(*) AS inventory_rows, COUNT(price) AS bewertet,
       COUNT(*) - COUNT(price) AS fehlend, SUM(wert_eur) AS teilwert_eur,
       CASE WHEN COUNT(*) > 0 AND COUNT(price) = COUNT(*)
            THEN SUM(wert_eur) END AS vollwert_eur
FROM inventory_values;
