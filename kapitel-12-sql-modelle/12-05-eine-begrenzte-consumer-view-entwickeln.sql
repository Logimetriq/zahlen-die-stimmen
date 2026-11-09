-- Kapitel 12 · SQL-Analysemodelle wiederverwenden und kontrolliert ändern
-- Abschnitt „Eine begrenzte Consumer-View entwickeln“ · Codeblock 5
-- Vollständige Abfrage; das Buch zeigt davon einen Ausschnitt.

CREATE VIEW m04.exercise_warehouse_day AS
SELECT warehouse_id,
       snapshot_date,
       COUNT(*) AS observed_rows,
       COUNT(inventory_value_eur) AS valued_rows,
       SUM(inventory_value_eur) AS known_value_eur,
       CASE WHEN COUNT(*) = COUNT(inventory_value_eur)
            THEN SUM(inventory_value_eur)
       END AS full_value_eur
FROM m04.fact_inventory_snapshots
GROUP BY warehouse_id, snapshot_date;
