# TRIAD Traffic · falsche Follow-Quelle im lokalen Lauf bestätigt

**Beleg-ID:** TRIAD-FOLLOW-SOURCE-20261109-232328
**Benutzerzeit laut Konsolenausgabe:** 2026-11-09, 23:23:28 Europe/Berlin
**Quelle:** Vom Nutzer gepostete PowerShell-Ausgabe, nicht unabhängige Prüfung der lokalen Dateien.

## Beobachteter Zustand

Ein lokaler PowerShell-Befehl las die zuletzt veränderte `TRIAD_TRAFFIC_*_SUMMARY.json` und meldete:

- `SourceFile`: `LIVE_V2_20261109_220333_EVENTS.csv`
- `Events`: `209`
- `LastAuthMarker`: `email-populated-marker`
- `UpdatedAtUtc`: `2026-11-09T22:23:06.8288462+00:00`

Der Nutzer zeigte zuvor einen neu gestarteten Live-V2-Sensor mit dem Dateinamen `LIVE_V2_20261109_232020_EVENTS.csv` und neuen `AUTH_CHANGE`-Signalen. Dass der Sensor diese Datei angelegt und zu Beginn beschrieben hat, ist durch dessen Konsole belegt.

## Diagnose

Die TRIAD-Zusammenfassung nennt **explizit die alte Quelle**. `UpdatedAtUtc` dokumentiert die Aktualisierung der Summary, nicht zwingend neue Eingabeereignisse. Der Importer im `-Follow`-Modus liest die über `-CsvPath` einmal ausgewählte Datei fortlaufend; er springt nicht automatisch auf einen später erzeugten Dateinamen um.

Die neue Datei ist somit anhand dieses TRIAD-Summarys **noch nicht als importiert bestätigt**. Das ist eine Synchronisationslücke, keine Sicherheitslücke bei IGGM.

## Sofortige Gegenmaßnahme

Alten Importer mit Ctrl+C stoppen. Den bestehenden Importer erneut mit `-CsvPath "$HOME\HALVETH_IGGM_LIVE\LIVE_V2_20261109_232020_EVENTS.csv"`, `-AllowedHost www.iggm.com`, `-Follow` und `-PollMilliseconds 1000` starten. Browser-Sensor nur weiterlaufen lassen, wenn die neue Datei tatsächlich weiter beschrieben wird.

Danach **eine neue** `TRIAD_TRAFFIC_*_SUMMARY.json` prüfen: `SourceFile` soll auf die neue CSV zeigen und `Events` den enthaltenen Zeilen entsprechen. Für echte Live-Fortsetzung muss die Ereigniszahl bei neuen, regulären Browseraktionen steigen.

## Evidenzgrenzen

Kein neues öffentliches Netzwerktesten, keine Session-Replays, keine Cookie-Werte, keine Token oder OAuth-Codes. Git-Eintrag dokumentiert nachträglich den vom Nutzer beobachteten lokalen Zustand; ein erfolgreicher neuer TRIAD-Import wurde bisher nicht gezeigt.

**Projektursprung:** Die Integration des Keepers als Zentrale mit passivem Browser-Traffic und Git-Stempeln wurde vom Nutzer vorgeschlagen; technische Ausarbeitung mit KI-Unterstützung.
