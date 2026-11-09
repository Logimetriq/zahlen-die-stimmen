-- Kapitel 5 · SQL für komplexe Analysen
-- Abschnitt „Periodenvergleich: Differenz und Nenner prüfen“ · Codeblock 11
-- Vollständige Abfrage; das Buch zeigt davon einen Ausschnitt.

WITH vergleichsstand AS (
  SELECT observation_date, value,
         LAG(observation_date) OVER (
           PARTITION BY series_id ORDER BY observation_date
         ) AS vorheriger_tag,
         LAG(value) OVER (
           PARTITION BY series_id ORDER BY observation_date
         ) AS vorheriger_wert
  FROM observed_values
)
SELECT observation_date, value, vorheriger_wert,
       observation_date - vorheriger_tag AS abstand_tage,
       value - vorheriger_wert AS differenz,
       CASE WHEN vorheriger_wert <> 0
            THEN ROUND(100.0 * (value - vorheriger_wert)
                       / vorheriger_wert, 2)
       END AS aenderung_prozent
FROM vergleichsstand ORDER BY observation_date;
