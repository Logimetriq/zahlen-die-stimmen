-- Kapitel 5 · SQL für komplexe Analysen
-- Abschnitt „Window Functions: Gruppen berechnen und Detailzeilen behalten“ · Codeblock 3

SELECT order_id, warehouse_id, order_amount_eur,
       SUM(order_amount_eur)
         OVER (PARTITION BY warehouse_id) AS warehouse_total_eur
FROM orders ORDER BY order_id;
