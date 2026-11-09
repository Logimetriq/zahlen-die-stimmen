-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „NOT, AND und OR: Gegenprobe für UNKNOWN“ · Codeblock 34

SELECT NOT (NULL::boolean) AS nicht_unbekannt,
       FALSE AND NULL::boolean AS falsch_und_unbekannt,
       TRUE OR NULL::boolean AS wahr_oder_unbekannt;
