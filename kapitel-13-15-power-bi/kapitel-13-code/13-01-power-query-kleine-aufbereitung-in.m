// Kapitel 13 · Abschnitt „Power Query: kleine Aufbereitung in benannten Schritten“ · Codeblock 1

let
    Quelle = PostgreSQL.Database(Server, Database),
    Produkte = Quelle{
        [Schema = "m04", Item = "dim_product"]
    }[Data],
    Auswahl = Table.SelectColumns(
        Produkte, {"product_id", "product_name"}
    ),
    Typen = Table.TransformColumnTypes(
        Auswahl,
        {{"product_id", type text},
         {"product_name", type text}}
    )
in
    Typen
