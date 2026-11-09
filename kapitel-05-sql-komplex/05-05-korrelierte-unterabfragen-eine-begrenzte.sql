-- Kapitel 5 · SQL für komplexe Analysen
-- Abschnitt „Korrelierte Unterabfragen: eine begrenzte Alternative“ · Codeblock 5

SELECT t.order_id, t.warehouse_id,
       (SELECT SUM(v.order_amount_eur)
          FROM orders AS v
         WHERE v.warehouse_id = t.warehouse_id
       ) AS warehouse_total_eur
FROM orders AS t ORDER BY t.order_id;
