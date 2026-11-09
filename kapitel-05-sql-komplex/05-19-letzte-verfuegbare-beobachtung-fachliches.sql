-- Kapitel 5 · SQL für komplexe Analysen
-- Abschnitt „Letzte verfügbare Beobachtung: fachliches Datum und Kenntniszeit“ · Codeblock 21
-- Vollständige Abfrage; das Buch zeigt davon einen Ausschnitt.

WITH zulaessige_beobachtungen AS (
  SELECT * FROM last_known_price_check
  WHERE currency='EUR' AND price_date <= DATE '2026-09-16'
    AND available_at <= TIMESTAMPTZ '2026-09-17 06:00:00+00'
), rangiert AS (
  SELECT *, ROW_NUMBER() OVER (
    PARTITION BY product_id, currency
    ORDER BY price_date DESC, available_at DESC, revision_id DESC
  ) AS rn FROM zulaessige_beobachtungen
), reihen AS (
  SELECT DISTINCT product_id FROM last_known_price_check
)
SELECT s.product_id, r.price_date, r.price,
       DATE '2026-09-16' - r.price_date AS alter_tage
FROM reihen AS s LEFT JOIN rangiert AS r
  ON r.product_id=s.product_id AND r.rn=1
ORDER BY s.product_id;
