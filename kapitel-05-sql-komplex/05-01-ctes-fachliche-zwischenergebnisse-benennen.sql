-- Kapitel 5 · SQL für komplexe Analysen
-- Abschnitt „CTEs: fachliche Zwischenergebnisse benennen“ · Codeblock 1

WITH warehouse_totals AS (
  SELECT warehouse_id,
         COUNT(*) AS order_count,
         SUM(order_amount_eur) AS betrag_eur
  FROM orders
  GROUP BY warehouse_id
)
SELECT * FROM warehouse_totals ORDER BY warehouse_id;
