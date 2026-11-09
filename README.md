# Zahlen, die stimmen – Begleitmaterial

**Daten richtig auswerten mit SQL, Python und Power BI**
LOGIMETRIQ · Band 1 · Christian Holzinger

Dieses Repository enthält die Daten und den Code zum Buch. Jeder Ordner gehört zu einem Kapitel; die Dateien tragen die Kapitel- und Abschnittsnamen aus dem Buch. Die Ergebnisse, mit denen Sie Ihre eigenen Ausgaben vergleichen, stehen im Buch direkt unter dem jeweiligen Codeblock.

**[⬇ Material herunterladen (ZIP)](https://github.com/Logimetriq/zahlen-die-stimmen/archive/refs/heads/main.zip)** – entpacken, dann weiter mit „Einrichtung“.

## Was enthalten ist

| Ordner | Kapitel | Inhalt |
| --- | --- | --- |
| `daten/` | alle | Die Tabellen des durchgehenden Falls als CSV: Bestellungen, Bestände, Preisrevisionen, Kunden, Lager, Produkte; in `pruefdaten/` die kleinen Kontrolltabellen |
| `einrichtung/` | 4–6 | `postgresql-setup.sql` legt alle Tabellen und Ansichten in einem Schritt an |
| `kapitel-04-sql-grundlagen/` | 4 | alle 38 SQL-Abfragen des Kapitels |
| `kapitel-05-sql-komplex/` | 5 | CTEs, Window Functions und Zeitstände; Abfragen, die das Buch in Teilen zeigt, liegen hier vollständig vor |
| `kapitel-06-sql-performance/` | 6 | Vorbereitung mit 100.000 erzeugten Bestellungen und die Abfragen für `EXPLAIN` |
| `kapitel-07-python-import/` | 7 | Notebook und die CSV-Dateien des Kapitels |
| `kapitel-08-pandas/` | 8 | Notebook mit allen Transformationen und den Diagrammen aus Abbildung 8.1 und 8.2 |
| `kapitel-09-reproduzierbar/` | 9 | vollständiges Programm: `analysis.py`, `run_analysis.py`, Tests, Konfigurationen, Vergleich zweier Läufe |
| `kapitel-10-reconciliation/` | 10 | Prüfscript `run_checks.py` mit unabhängigem Soll |
| `kapitel-11-datenmodelle/` | 11 | kleines Star Schema in SQLite und die beiden Abfragen |
| `kapitel-12-sql-modelle/` | 12 | Quelltabellen, Modellversion 1.0, Änderung auf 1.1 und Consumer-Abfragen |
| `kapitel-13-15-power-bi/` | 13–15 | Power-BI-Projekt (Operationsbericht) und alle Power-Query- und DAX-Blöcke als Dateien |

Die Kapitel 1 bis 3 arbeiten mit Tabellen auf Papier und brauchen keine Dateien.

## Geprüfte Versionen

| Werkzeug | Version |
| --- | --- |
| PostgreSQL | 16 |
| Python | 3.14 |
| pandas | 2.3.3 (alle Pakete in `requirements.txt`) |
| SQLite | 3 (Kapitel 11) |
| Power BI Desktop | Windows, aktuelle Version |

In anderen Versionen können einzelne Ausgaben abweichen. Ein Beispiel: Der zeitliche Merge in Kapitel 8 (`merge_asof`) bricht unter pandas 3 ab, weil pandas 3 Zeitangaben in einer anderen Auflösung einliest. Mit den Versionen aus `requirements.txt` laufen alle Beispiele wie im Buch.

## Einrichtung

Alle Befehle werden im Hauptordner des Materials ausgeführt.

**1. PostgreSQL (Kapitel 4, 5, 6, 12 und Power BI)**

```text
createdb zahlen_die_stimmen
psql -d zahlen_die_stimmen -f einrichtung/postgresql-setup.sql
```

Die Tabellen liegen im Schema `b2b`; die Datenbank findet sie automatisch, Sie können also wie im Buch `FROM orders` schreiben. Danach lässt sich jede Datei eines Kapitels ausführen, zum Beispiel:

```text
psql -d zahlen_die_stimmen -f kapitel-04-sql-grundlagen/04-07-on-versus-where-paarbildung-und.sql
```

Sie können die Dateien ebenso in pgAdmin oder DBeaver öffnen und dort ausführen.

**2. Python (Kapitel 7 bis 10)**

```text
python -m venv .venv
.venv\Scripts\activate          (Windows; macOS/Linux: source .venv/bin/activate)
python -m pip install -r requirements.txt
jupyter lab
```

In Jupyter das Notebook im Ordner des Kapitels öffnen und die Zellen von oben nach unten ausführen. Zellen, die im Buch absichtlich einen Fehler zeigen, fangen diesen Fehler ab und geben ihn aus.

**3. Power BI (Kapitel 13 bis 15)**

Siehe [`kapitel-13-15-power-bi/README.md`](kapitel-13-15-power-bi/README.md).

## Kapitel, die aufeinander aufbauen

- **Kapitel 6** braucht zuerst `kapitel-06-sql-performance/06-00-vorbereitung.sql`.
- **Kapitel 9** liest die Bestellungen aus `kapitel-07-python-import/`.
- **Kapitel 10** vergleicht mit den Ergebnissen aus Kapitel 9: zuerst im Ordner `kapitel-09-reproduzierbar` `python run_analysis.py` ausführen, dann im Ordner `kapitel-10-reconciliation` `python run_checks.py --output-dir outputs/mein-abgleich-01`.
- **Kapitel 12** in drei Schritten: `12-00-quelltabellen.sql`, `12-01-modelle-v1.sql`, `12-02-aenderung-v1-1.sql`. Erst danach lassen sich die Abfragen `12-03` bis `12-05` und der Power-BI-Bericht ausführen.

## Fehler gefunden?

Wenn ein Beispiel bei Ihnen anders läuft als im Buch beschrieben, freue ich mich über einen Hinweis unter [Issues](https://github.com/Logimetriq/zahlen-die-stimmen/issues). Bitte nennen Sie Kapitel, Datei und Ihre Versionen. Korrekturen erscheinen hier als neue Version des Materials.

## Lizenz

Der Code steht unter der [MIT-Lizenz](LICENSE), die Daten in `daten/` unter [CC BY 4.0](LICENSE-DATEN.md). Der Buchtext selbst ist nicht Teil dieses Repositorys.
