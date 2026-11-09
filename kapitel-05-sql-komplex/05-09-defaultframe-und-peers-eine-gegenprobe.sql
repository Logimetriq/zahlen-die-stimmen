-- Kapitel 5 · SQL für komplexe Analysen
-- Abschnitt „Defaultframe und Peers: eine Gegenprobe“ · Codeblock 9

SELECT item_id, order_value, amount_eur,
       SUM(amount_eur) OVER (ORDER BY order_value)
         AS default_summe,
       SUM(amount_eur) OVER (
         ORDER BY order_value, item_id
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS rows_summe
FROM peer_control ORDER BY order_value, item_id;
