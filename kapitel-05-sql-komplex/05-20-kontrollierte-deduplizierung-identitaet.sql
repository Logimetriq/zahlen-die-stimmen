-- Kapitel 5 · SQL für komplexe Analysen
-- Abschnitt „Kontrollierte Deduplizierung: Identität vor Zeilennummer“ · Codeblock 23

SELECT observation_id, revision_id, COUNT(*) AS lieferungen,
       COUNT(DISTINCT value) AS werte,
       COUNT(DISTINCT available_at) AS kenntniszeiten
FROM delivery_control GROUP BY observation_id, revision_id
HAVING COUNT(*) > 1 ORDER BY observation_id, revision_id;
