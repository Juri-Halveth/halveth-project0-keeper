# HALVETH TRIAD Traffic · AutoSwitch auf Windows gestartet

**Beleg-ID:** HALVETH-AUTOSWITCH-20261109-233806  
**Zeit laut Nutzerkonsole:** 2026-11-09, 23:38:06 Europe/Berlin  
**Quelle:** vom Projektinhaber zur Verfügung gestellte PowerShell-Ausgabe; nachträglich redigiert und versioniert  
**Ideenimpuls / Projektintegration:** Juri Janovski / Juri-Halveth  
**Code, Implementierung und Testausarbeitung:** KI-unterstützt; die GitHub-CI auf synthetischen Daten war zuvor erfolgreich  
**Evidenzstatus:** `OBSERVED_IN_USER_CONSOLE`, keine unabhängige Lektüre der lokalen CSV/JSONL

## Beobachteter Windows-Ablauf

1. Lokale Working Copy `HALVETH_PROJECT0_TRAFFIC` auf Branch `codex/triad-traffic-20261109` wurde per `git pull --ff-only` von `3222d3e` nach `b7aae4b` aktualisiert.
2. Es wurden neun Dateien verändert oder neu angelegt, darunter die neue `-AutoSwitch`-Implementierung und Regressionstests.
3. Der Nutzer startete die TRIAD Traffic-Funktion mit `-AllowedHost www.iggm.com -AutoSwitch -Follow -InputDirectory "$HOME\HALVETH_IGGM_LIVE" -PollMilliseconds 1000`.
4. Konsole: `HALVETH TRIAD AUTO-SWITCH AKTIV` und `TRIAD TRAFFIC | local/offline | 20261109T223808333Z-72b43d`.
5. `AutoSwitch watches local folder: ...\HALVETH_IGGM_LIVE`.
6. `SOURCE_SWITCH -> LIVE_V2_20261109_232020_EVENTS.csv` bestätigt, dass der neue dateibasierte Modus die bereits vorhandene jüngste Quelle auswählte.
7. Sichtbare Ausgabe des normalisierten Importers:
   - `93 AUTH_CHANGE +2ms www.iggm.com/`
   - `142 ERROR +2,511ms www.iggm.com/login`
   - `180 AUTH_CHANGE +1,127ms www.iggm.com/`
8. Benannte Ausgabedatei: `.triad-runtime/traffic/TRIAD_TRAFFIC_20261109T223808333Z-72b43d_EVENTS.jsonl`; deren vollständiger Inhalt wurde hier nicht separat geprüft.

## Genauigkeit der Aussage

- **Bestätigt:** Der aktualisierte AutoSwitch-Code läuft auf Windows, erkennt die vorhandene jüngste V2-CSV und importiert mindestens bis zum gezeigten Event-Index 180.
- **Nicht durch diesen Konsolenausschnitt bestätigt:** automatischer Wechsel *nach* dem Start zu einer zusätzlich neu angelegten CSV; tatsächlicher Zuwachs nach neuen Browseraktivitäten; Langzeitstabilität.
- **CI-Gegenprobe:** Der Wechsel zwischen zwei künstlichen Dateien wurde im Windows-Actions-Test bereits bestanden. Das bleibt von der vorliegenden realen Ein-Datei-Beobachtung getrennt.
- Die Zahlen `2ms`, `2,511ms` und `1,127ms` sind Zeitabstände zu den **jeweils vorherigen Logeinträgen**, nicht zwischen den drei ausgegebenen Zeilen und nicht HTTP-Anfragelaufzeiten. Das ausgegebene Komma ist numerische Formatierung; die interne Lücke wird in `GapMs` gespeichert.
- `AUTH_CHANGE` ist ein HTML-Zustandsmarker, kein serverseitiger Autorisierungsnachweis. `ERROR` kann ein Browser-/Navigationsabbruch sein, keine Sicherheitslücke.
- Keine Cookies, OAuth-Codes, Zugangsdaten oder Rohantworten in diesem Git-Dokument.

## Nächste Gegenprobe

(1) Summary `Events` und `SourceHistory` prüfen. (2) Normale Interaktion im eigenen Test-Chrome durchführen, erneut `Events` prüfen. (3) Für eine unabhängige Dateiwechselprüfung den Browser-Sensor lokal kontrolliert neu starten und `SOURCE_SWITCH` für eine **neue** V2-Datei beobachten. Kein aktives Fuzzing/Replay gegen fremde Systeme.

**Status:** dokumentierter Start und Altdatei-Import; noch kein Ende-zu-Ende-Nachweis für das dynamische Wechselereignis nach Start.
