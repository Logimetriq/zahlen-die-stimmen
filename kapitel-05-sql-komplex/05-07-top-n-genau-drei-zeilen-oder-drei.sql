-- Kapitel 5 · SQL für komplexe Analysen
-- Abschnitt „Top-N: genau drei Zeilen oder drei Rangstufen“ · Codeblock 7

WITH rangiert AS (
  SELECT ticket_id,
         DENSE_RANK() OVER (ORDER BY minutes DESC) AS rangstufe
  FROM ticket_control
)
SELECT ticket_id FROM rangiert WHERE rangstufe <= 3
ORDER BY ticket_id;
