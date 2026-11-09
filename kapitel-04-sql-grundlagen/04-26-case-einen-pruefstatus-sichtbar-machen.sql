-- Kapitel 4 · SQL für Datenanalysen
-- Abschnitt „CASE: einen Prüfstatus sichtbar machen“ · Codeblock 26

SELECT order_id, order_amount_eur,
       CASE WHEN order_amount_eur > 250 THEN 'Rueckfrage'
            ELSE 'unauffaellig' END AS pruefstatus
FROM orders
ORDER BY order_id;
