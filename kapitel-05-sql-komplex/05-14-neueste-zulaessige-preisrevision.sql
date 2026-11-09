-- Kapitel 5 · SQL für komplexe Analysen
-- Abschnitt „Neueste zulässige Preisrevision auswählen“ · Codeblock 15

WITH zulaessige_revisionen AS (
  SELECT * FROM revision_example
  WHERE price_date = DATE '2026-09-14' AND currency = 'EUR'
    AND available_at <= TIMESTAMPTZ '2026-09-15 12:00:00+00'
), rangierte_revisionen AS (
  SELECT *, ROW_NUMBER() OVER (
    PARTITION BY product, price_date, currency
    ORDER BY available_at DESC, revision_id DESC
  ) AS rn
  FROM zulaessige_revisionen
)
SELECT product, revision_id, price, rn
FROM rangierte_revisionen ORDER BY product, rn;
