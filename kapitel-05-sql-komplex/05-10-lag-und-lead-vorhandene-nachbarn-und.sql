-- Kapitel 5 · SQL für komplexe Analysen
-- Abschnitt „LAG und LEAD: vorhandene Nachbarn und Periodenvergleich“ · Codeblock 10

SELECT observation_date, value,
       LAG(observation_date) OVER (
         PARTITION BY series_id ORDER BY observation_date
       ) AS vorheriger_tag,
       LAG(value) OVER (
         PARTITION BY series_id ORDER BY observation_date
       ) AS vorheriger_wert,
       LEAD(value) OVER (
         PARTITION BY series_id ORDER BY observation_date
       ) AS naechster_wert
FROM observed_values ORDER BY series_id, observation_date;
