# Kapitel 13 bis 15 · Power BI

Der Ordner `projekt/` enthält den fertigen **Operationsbericht** im Stand von Kapitel 15: Semantic Model mit Beziehungen und Measures, die Reportseite und die beiden Rollen für Row-Level Security. In `kapitel-13-code/`, `kapitel-14-code/` und `kapitel-15-code/` stehen alle Power-Query- und DAX-Blöcke des Buchs als einzelne Dateien.

## Voraussetzungen

- Windows mit Power BI Desktop
- PostgreSQL mit der Datenbank aus der Einrichtung und den drei Schritten aus Kapitel 12:

```text
psql -d zahlen_die_stimmen -f kapitel-12-sql-modelle/12-00-quelltabellen.sql
psql -d zahlen_die_stimmen -f kapitel-12-sql-modelle/12-01-modelle-v1.sql
psql -d zahlen_die_stimmen -f kapitel-12-sql-modelle/12-02-aenderung-v1-1.sql
```

## Öffnen und verbinden

1. Falls Ihre Power-BI-Version Projektdateien noch als Vorschaufeature führt: unter **Datei → Optionen und Einstellungen → Optionen → Vorschaufeatures** die Option **Power BI-Projektdateien (.pbip)** aktivieren.
2. `projekt/Operationsbericht.pbip` öffnen.
3. Unter **Transformieren → Parameter bearbeiten** prüfen:
   - `Server`: voreingestellt `localhost:5432`; anpassen, wenn Ihr PostgreSQL einen anderen Port verwendet
   - `Database`: voreingestellt `zahlen_die_stimmen`
4. **Aktualisieren** wählen und die Anmeldedaten Ihrer PostgreSQL-Datenbank eingeben (Datenbank-Anmeldung, etwa Benutzer `postgres`).

Bei der ersten Aktualisierung fragt Power BI zweimal nach:

- **„Native Datenbankabfrage“**: Zwei Tabellen lesen ihre Daten mit einer SQL-Abfrage, die Zeitangaben nach UTC umrechnet. Mit **Ausführen** genehmigen.
- **„Verschlüsselungsunterstützung“**: Eine lokale PostgreSQL-Installation bietet meist keine verschlüsselte Verbindung an. Für die Datenbank auf dem eigenen Rechner mit **OK** unverschlüsselt verbinden.

Öffnet Power BI nach dem Laden eine Startansicht, führt **Esc** oder ein Klick auf die Berichtsansicht links zurück zur Seite.

Danach zeigt die Seite die Werte aus Kapitel 15: vier Bestellungen mit 1.000 EUR, mittlere Bearbeitungsdauer 75 Minuten, Bestandsbewertung 1 von 2 Zeilen, bekannter Teilwert 1.000 EUR, vollständiger Wert unbekannt.

## Rollen testen

Unter **Modellierung → Anzeigen als** die Rolle `OPS_FRANKFURT` wählen. Der Bericht zeigt dann nur Lager Frankfurt (301): zwei Bestellungen mit 300 EUR. Eine Person darf immer nur eine der beiden Rollen haben: Mehrere Rollen addieren ihre Berechtigungen.
