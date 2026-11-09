-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „EXISTS und IN: gültige Produktziele prüfen“ · Codeblock 24

SELECT order_id
FROM order_reference_check
WHERE product_id IN (SELECT product_id FROM products)
ORDER BY order_id;
