-- Kapitel 5 · SQL für komplexe Analysen
-- Abschnitt „ROW_NUMBER, RANK und DENSE_RANK: Gleichstände bewusst behandeln“ · Codeblock 6

SELECT ticket_id, minutes,
       ROW_NUMBER() OVER (ORDER BY minutes DESC, ticket_id)
         AS zeilennummer,
       RANK() OVER (ORDER BY minutes DESC) AS rang,
       DENSE_RANK() OVER (ORDER BY minutes DESC) AS rangstufe
FROM ticket_control ORDER BY minutes DESC, ticket_id;
