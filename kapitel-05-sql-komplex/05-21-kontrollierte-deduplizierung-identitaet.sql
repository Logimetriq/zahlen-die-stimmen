-- Kapitel 5 · SQL für komplexe Analysen
-- Abschnitt „Kontrollierte Deduplizierung: Identität vor Zeilennummer“ · Codeblock 24

WITH nummerierte_lieferungen AS (
  SELECT *, ROW_NUMBER() OVER (
    PARTITION BY observation_id, revision_id ORDER BY delivery_id
  ) AS liefernummer
  FROM delivery_control
)
SELECT delivery_id, observation_id, revision_id, value
FROM nummerierte_lieferungen WHERE liefernummer = 1
ORDER BY delivery_id;
