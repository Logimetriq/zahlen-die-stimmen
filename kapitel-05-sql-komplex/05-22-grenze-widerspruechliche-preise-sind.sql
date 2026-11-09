-- Kapitel 5 · SQL für komplexe Analysen
-- Abschnitt „Grenze: widersprüchliche Preise sind keine Lieferkopien“ · Codeblock 25

SELECT product_id, price_date, currency, revision_id,
       available_at, COUNT(*) AS kandidaten,
       COUNT(DISTINCT price) AS preise
FROM ambiguous_price_check
GROUP BY product_id, price_date, currency, revision_id,
         available_at
HAVING COUNT(DISTINCT price) > 1
ORDER BY product_id, price_date, currency, revision_id,
         available_at;
