-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „EXISTS und IN: gültige Produktziele prüfen“ · Codeblock 23

SELECT t.order_id
FROM order_reference_check AS t
WHERE EXISTS (
  SELECT 1 FROM products AS i
  WHERE i.product_id = t.product_id
)
ORDER BY t.order_id;
