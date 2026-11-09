-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „HAVING: Gruppen prüfen, WHERE: Eingabezeilen prüfen“ · Codeblock 21

SELECT order_id, revision_id,
       COUNT(*) AS vorkommen, COUNT(*) - 1 AS ueberschuss
FROM order_duplicate_check
GROUP BY order_id, revision_id
HAVING COUNT(*) > 1
ORDER BY order_id, revision_id;
