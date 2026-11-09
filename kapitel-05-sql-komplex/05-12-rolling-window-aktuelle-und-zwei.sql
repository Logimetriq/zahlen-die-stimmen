-- Kapitel 5 · SQL für komplexe Analysen
-- Abschnitt „Rolling Window: aktuelle und zwei vorherige Beobachtungen“ · Codeblock 13

SELECT observation_date, value,
       COUNT(*) OVER (
         PARTITION BY series_id ORDER BY observation_date
         ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
       ) AS beobachtungen,
       ROUND(AVG(value) OVER (
         PARTITION BY series_id ORDER BY observation_date
         ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
       ), 2) AS rolling_mittel
FROM observed_values ORDER BY series_id, observation_date;
