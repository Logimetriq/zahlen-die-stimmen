-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „NOT EXISTS: fehlende Produktreferenzen finden“ · Codeblock 25

SELECT t.order_id, t.product_id
FROM order_reference_check AS t
WHERE NOT EXISTS (
  SELECT 1 FROM products AS i
  WHERE i.product_id = t.product_id
)
ORDER BY t.order_id;
