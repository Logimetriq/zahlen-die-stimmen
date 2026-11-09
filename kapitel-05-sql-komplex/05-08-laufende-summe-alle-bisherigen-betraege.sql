-- Kapitel 5 · SQL für komplexe Analysen
-- Abschnitt „Laufende Summe: alle bisherigen Beträge“ · Codeblock 8

SELECT sequence_no, amount_eur,
       SUM(amount_eur) OVER (
         ORDER BY sequence_no
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS laufend_eur
FROM ordered_amounts ORDER BY sequence_no;
