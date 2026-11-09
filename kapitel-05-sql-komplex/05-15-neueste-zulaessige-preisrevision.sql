-- Kapitel 5 · SQL für komplexe Analysen
-- Abschnitt „Neueste zulässige Preisrevision auswählen“ · Codeblock 16
-- Vollständige Abfrage; das Buch zeigt davon einen Ausschnitt.

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
SELECT product, revision_id, price
FROM rangierte_revisionen WHERE rn = 1 ORDER BY product;
