# Zahlen, die stimmen – Begleitmaterial

**Daten richtig auswerten mit SQL, Python und Power BI**
LOGIMETRIQ · Band 1 · Christian Holzinger

Dieses Repository enthält die Daten und den Code zum Buch. Jeder Ordner gehört zu einem Kapitel; die Dateien tragen die Kapitel- und Abschnittsnamen aus dem Buch. Die Ergebnisse, mit denen Sie Ihre eigenen Ausgaben vergleichen, stehen im Buch direkt unter dem jeweiligen Codeblock.

**[⬇ Material herunterladen (ZIP)](https://github.com/Logimetriq/zahlen-die-stimmen/archive/refs/heads/main.zip)** – entpacken, dann weiter mit „Einrichtung“.

Unter Windows am besten in einen kurzen Ordner entpacken, etwa `C:\zds`. Sehr lange Ordnerpfade können die Installation der Python-Pakete scheitern lassen.

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

## Werkzeuge installieren

Sie brauchen nur die Werkzeuge der Kapitel, die Sie nachvollziehen möchten:

| Werkzeug | Bezugsquelle | Hinweis |
| --- | --- | --- |
| PostgreSQL 16 | [postgresql.org/download](https://www.postgresql.org/download/) | Der Windows-Installer enthält `psql` und pgAdmin. Merken Sie sich das Kennwort des Benutzers `postgres`. |
| Python 3.14 | [python.org/downloads](https://www.python.org/downloads/) | Bei der Installation „Add python.exe to PATH“ anhaken. |
| SQLite | [sqlite.org/download.html](https://www.sqlite.org/download.html) | Nur für Kapitel 11: die „command-line tools“ entpacken. Alternativ jedes SQLite-Programm, etwa DB Browser for SQLite. |
| Power BI Desktop | Microsoft Store | Nur für Kapitel 13 bis 15, nur unter Windows. |

Findet die Eingabeaufforderung `psql` nicht, liegt das Programm unter Windows meist in `C:\Program Files\PostgreSQL\16\bin`. Sie können diesen Ordner zur Umgebungsvariablen `PATH` hinzufügen oder die SQL-Dateien stattdessen in pgAdmin öffnen und ausführen.

## Einrichtung

Alle Befehle werden im Hauptordner des Materials ausgeführt.

**1. PostgreSQL (Kapitel 4, 5, 6, 12 und Power BI)**

```text
createdb -U postgres zahlen_die_stimmen
psql -U postgres -d zahlen_die_stimmen -f einrichtung/postgresql-setup.sql
```

Beide Befehle fragen nach dem Kennwort des Benutzers `postgres`. Wer mit einem eigenen PostgreSQL-Benutzer arbeitet, setzt dessen Namen hinter `-U`. In pgAdmin: Datenbank `zahlen_die_stimmen` anlegen, dann das **Query Tool** öffnen, die Datei laden und ausführen.

Die Tabellen liegen im Schema `b2b`; die Datenbank findet sie automatisch, Sie können also wie im Buch `FROM orders` schreiben. Danach lässt sich jede Datei eines Kapitels ausführen, zum Beispiel:

```text
psql -U postgres -d zahlen_die_stimmen -f kapitel-04-sql-grundlagen/04-07-on-versus-where-paarbildung-und.sql
```

Sie können die Dateien ebenso in pgAdmin oder DBeaver öffnen und dort ausführen.

**2. Python (Kapitel 7 bis 10)**

Windows (PowerShell):

```text
python -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
jupyter lab
```

macOS und Linux:

```text
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
jupyter lab
```

Meldet PowerShell beim Aktivieren, dass Skripte deaktiviert sind, hilft einmalig `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`. Alternativ funktioniert in der klassischen Eingabeaufforderung (cmd) `.venv\Scripts\activate.bat`.

In Jupyter das Notebook im Ordner des Kapitels öffnen und die Zellen von oben nach unten ausführen. Zellen, die im Buch absichtlich einen Fehler zeigen, fangen diesen Fehler ab und geben ihn aus.

**3. SQLite (Kapitel 11)**

Im Ordner `kapitel-11-datenmodelle` zuerst das Modell anlegen, dann die beiden Abfragen ausführen:

```text
sqlite3 modell.db ".read 11-00-modell.sql"
sqlite3 modell.db ".read 11-01-den-falschen-direktjoin-nachvollziehen.sql"
sqlite3 modell.db ".read 11-02-getrennt-aggregieren-und-erst-danach.sql"
```

Diese Schreibweise funktioniert in PowerShell, cmd und unter macOS/Linux. Je nach SQLite-Version erscheinen Summen als `300.0` statt `300`; der Wert ist derselbe.

**4. Power BI (Kapitel 13 bis 15)**

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
