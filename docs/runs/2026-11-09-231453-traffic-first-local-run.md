# HALVETH TRIAD Traffic · erster vom Nutzer bestätigter Windows-Start

**Beleg-ID:** TRIAD-TRAFFIC-RUN-2026-11-09-231453  
**Lokale Ausführungszeit gemäß Konsole:** 2026-11-09, ca. 23:14:53 Europe/Berlin.  
**Laufkennung gemäß Ausgabe:** `20261109T221454711Z-3599ca` (UTC).  
**Ausführender:** Projektinhaber an eigenem Windows-PC.  
**Erstellung und Analyse des Importers:** ChatGPT, mit GitHub Actions auf künstlichen Daten getestet.  
**Quellcode:** `3222d3e33538dc3b9c49232d8cd11ccb0017bf03` im Branch `codex/triad-traffic-20261109`.

## Beobachtetes Konsolenergebnis

- `git clone --depth 1 --single-branch --branch codex/triad-traffic-20261109` war erfolgreich.
- `git rev-parse --short HEAD` gab `3222d3e` aus.
- `Import-TriadTraffic.ps1 -CsvPath ... -AllowedHost www.iggm.com -Follow -PollMilliseconds 1000` startete ohne sichtbare Fehlermeldung.
- Als Input wurde eine bereits vorhandene V2-CSV `LIVE_V2_20261109_220333_EVENTS.csv` angezeigt.
- Die Ausgabe zeigte:
  - `18 AUTH_CHANGE +1,098ms www.iggm.com/`
  - `200 AUTH_CHANGE +2ms www.iggm.com/`
- Der Prozess war im geposteten Ausschnitt noch im **Follow-Modus**, der Start ist dokumentiert, aber das Ende der Ausführung bzw. die vollständige Schlusszusammenfassung wurde nicht mitgeteilt.
- Lokale Ereignis-Ausgabedatei wurde vom Skript benannt: `.triad-runtime/traffic/TRIAD_TRAFFIC_20261109T221454711Z-3599ca_EVENTS.jsonl`. Dass sie tatsächlich beschrieben wurde, wird durch den erfolgreichen Start nahegelegt, aber hier nicht unabhängig durch Einlesen bestätigt.

## Wichtige Aussagegrenzen

1. **`1,098 ms` und `2 ms` sind Zeitabstände zum jeweils unmittelbar davorliegenden CSV-Ereignis.** Sie sind *keine* HTTP-Latenz und auch nicht zwingend der Abstand zwischen den beiden angezeigten AUTH_CHANGE-Ereignissen. Die zweifache Ausgabe entsteht durch die Konsolenfilterung auf besondere Ereignisarten.
2. **`-Follow` beobachtet die angegebene Datei**, nicht automatisch alle später angelegten `LIVE_V2_*.csv`-Dateien. Neue Ereignisse erscheinen nur, wenn weiterhin dieselbe CSV beschrieben wird.
3. Die Aufgabe **führt keine zusätzlichen HTTP-Anfragen** gegen IGGM aus. Sie verarbeitet vorhandene lokale Daten. Ein erfolgreicher Import ist noch kein neues Live-Netzwerk-Capture.
4. `AUTH_CHANGE` bezeichnet lokale HTML-Marker, nicht zwingend einen serverseitigen Auth- oder Autorisierungsbeweis.
5. Kein neuer Sicherheitsbefund oder Exploit ist durch diesen Lauf nachgewiesen.

## Nächste Prüfung

- Dateizeit und aktuelle CSV-Beschreibung prüfen.
- Bei neuer V2-Live-CSV den Importer für die **neue Dateipfadangabe** starten.
- Für echte Request-Latenzen benötigt der Sensor Request-ID-basierte CDP-`Network.requestWillBeSent`-/`Network.responseReceived`-Zuordnung.
- Sensordaten inklusive Cookies, OAuth-Codes oder Login-Werte bleiben lokal und werden nicht in Git aufgenommen.

**Evidenzstatus:** `USER_SUPPLIED_CONSOLE_OBSERVATION`; Tests in GitHub Actions betreffen ausschließlich synthetische Fixtures.
