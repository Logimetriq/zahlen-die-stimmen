-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „HAVING: Gruppen prüfen, WHERE: Eingabezeilen prüfen“ · Codeblock 22

SELECT COUNT(*) AS rohzeilen,
       COUNT(DISTINCT order_id) AS order_ids
FROM order_duplicate_check;
