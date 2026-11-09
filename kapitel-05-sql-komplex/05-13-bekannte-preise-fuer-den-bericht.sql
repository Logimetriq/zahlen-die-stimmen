-- Kapitel 5 · SQL für komplexe Analysen
-- Abschnitt „Bekannte Preise für den Bericht auswählen“ · Codeblock 14

SELECT product_id, price
FROM product_price_revisions
WHERE price_date = DATE '2026-09-14' AND currency = 'EUR'
  AND available_at <= TIMESTAMPTZ '2026-09-15 06:00:00+00'
ORDER BY product_id;
