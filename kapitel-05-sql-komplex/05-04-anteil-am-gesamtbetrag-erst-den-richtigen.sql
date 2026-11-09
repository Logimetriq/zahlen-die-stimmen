-- Kapitel 5 · SQL für komplexe Analysen
-- Abschnitt „Anteil am Gesamtbetrag: erst den richtigen Grain herstellen“ · Codeblock 4

WITH warehouse_totals AS (
  SELECT warehouse_id,
         COUNT(*) AS order_count,
         SUM(order_amount_eur) AS betrag_eur
  FROM orders
  GROUP BY warehouse_id
)
SELECT warehouse_id, betrag_eur,
       SUM(betrag_eur) OVER () AS gesamt_eur,
       CASE WHEN SUM(betrag_eur) OVER () > 0
            THEN ROUND(100.0 * betrag_eur
                       / SUM(betrag_eur) OVER (), 2)
       END AS anteil_prozent
FROM warehouse_totals ORDER BY warehouse_id;
