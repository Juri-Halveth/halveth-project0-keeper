# HALVETH · realer Auto-Switch nach Sensor-Neustart bestätigt

**Beleg-ID:** TRIAD-AUTOSWITCH-REAL-20261109-234439  
**Beobachtungsquelle:** vom Projektinhaber bereitgestellte PowerShell-Summary-Tabelle  
**Letzter lokaler Zeitbezug:** 2026-11-09, 23:44:39 Europe/Berlin (entspricht `2026-11-09T22:44:39.6262769+00:00`).  
**Provenienz:** Ideenimpuls zur Keeper-/Live-Telemetrie- und TTP-Integration durch Juri Janovski / Juri-Halveth. KI-unterstützte Codeausarbeitung und spätere Dokumentation.  
**Status:** `OBSERVED_IN_USER_CONSOLE`; keine unabhängige Dateisystemprüfung.

## Vom Nutzer bestätigte Zusammenfassungen

| Quelle | Generation | Gesamtereignisse | UpdatedAtUtc |
| --- | ---: | ---: | --- |
| `LIVE_V2_20261109_234348_EVENTS.csv` | **2** | **399** | `2026-11-09T22:44:39.6262769+00:00` |
| `LIVE_V2_20261109_232020_EVENTS.csv` | nicht ausgegeben | 189 | `2026-11-09T22:44:36.7235031+00:00` |
| `LIVE_V2_20261109_220333_EVENTS.csv` | nicht ausgegeben | 209 | `2026-11-09T22:23:06.8288462+00:00` |

Die Summary mit `SourceGeneration=2` und dem neueren Dateinamen folgt der früher bestätigten `-AutoSwitch -Follow`-Ausführung `20261109T223808333Z-72b43d`, deren Start bei Generation 1 auf `232020_EVENTS.csv` bereits per Konsolenlog dokumentiert wurde.

## Bestätigte Aussage

- **Echter lokaler Dateiwechsel:** Das in GitHub Actions zuvor nur auf synthetischen CSVs geprüfte Auto-Switch-Verhalten ist nun auch durch die Auswertung auf dem Windows-PC des Nutzers belegt. `SourceGeneration=2` in Verbindung mit dem neuen Quellnamen demonstriert den Wechsel auf eine neu angelegte V2-CSV.
- **Fortgesetzte Zählung:** Aus dem vorherigen Laufstand mit 189 Ereignissen und der aktuellen Gesamtzahl von 399 ergibt sich ein Zuwachs um 210 normalisierte Ereignisse innerhalb des neuen Auto-Switch-Laufs.
- **Neue Quelle:** `LIVE_V2_20261109_234348_EVENTS.csv` wurde nach dem Sensor-Neustart erfasst.

## Strikte Aussagegrenzen

- Die 399 sind **normalisierte lokale Logereignisse**, nicht 399 individuelle HTTP-Requests oder Sicherheitsprobleme.
- Der Zuwachs belegt neue importierte Daten aus der neueren CSV, aber nicht zwingend, dass Daten bei jeder beliebigen späteren Browsernavigation ohne Unterbrechung ankommen.
- `UpdatedAtUtc` ist die Summary-Schreibzeit; sie beweist für sich allein keinen zusätzlichen Sensor-Event.
- `GapMs` im Keeper beschreibt Zeit zwischen Logeinträgen, **keine** Anfrage-Latenz.
- Keine Cookies, OAuth-Tokens, Anmeldeadressen, Request-Payloads, Antwortkörper oder vertrauliche Browserprotokolle werden in diesem Beleg veröffentlicht.
- Kein aktives Fuzzing/Replay und kein Exploitnachweis. Der Betrieb des Browser-Sensors erfolgt unabhängig vom passiven Importer.

## Ergebnisstatus

**BESTANDEN (Integration):** Automatischer Übergang von Generation 1 auf Generation 2 nach lokalem Sensor-Neustart und fortgesetzte Ereigniszählung.  
**OFFEN (weiterer Betrieb):** Langzeitstabilität, effizientes Tailen sehr großer Dateien, Speicherrotation, echte CDP-Request-ID-/Latenzkorrelation.

Referenz: [Importer](../../scripts/Import-TriadTraffic.ps1) · [Test](../../scripts/Test-TriadTraffic.ps1) · [TRIAD Traffic Architektur](../TRIAD_TRAFFIC.md).
