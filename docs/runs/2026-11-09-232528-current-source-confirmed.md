# HALVETH TRIAD Traffic · aktuelle CSV-Quelle bestätigt

**Beleg-ID:** TRIAD-LIVE-SOURCE-20261109-232528  
**Beobachtungszeit gemäß Nutzerkonsole:** 2026-11-09, 23:25:28 Europe/Berlin  
**Provenienz:** Vom Nutzer bereitgestellte lokale Windows-PowerShell-Ausgabe; nachträglich versioniert durch ChatGPT.  
**Ursprung der TRIAD-/Live-Traffic-Integration:** Juri Janovski / Juri-Halveth.

## Originale beobachtete Zusammenfassung (nur harmlose Metadaten)

- `SourceFile = LIVE_V2_20261109_232020_EVENTS.csv`
- `Events = 189`
- `LastAuthMarker = email-populated-marker`
- `UpdatedAtUtc = 2026-11-09T22:25:28.1040681+00:00`

**OBSERVED_IN_USER_CONSOLE:** Der Keeper-Importer hat auf die neu gestartete V2-CSV umgeschaltet und 189 lokale Logereignisse in seinem Zustand gezählt. Der `LastAuthMarker` entspricht dem zuvor im Sensorlauf beobachteten befüllten E-Mail-HTML-Marker.

**NOT_PROVEN:** Diese einzelne Momentaufnahme belegt nicht, dass seit 23:25:28 weitere Ereignisse eingetroffen sind, dass Browser-Sensor und Keeper dauernd aktiv bleiben oder dass der Marker eine serverseitige Autorisierung beweist. `UpdatedAtUtc` ist eine Summary-Aktualisierung, nicht automatisch ein neues Browser-Ereignis.

## Gegenprobe

1. Dieselbe Summary zweimal lesen und das Feld `Events` vergleichen.
2. Dazwischen im isolierten Test-Chrome eine gewöhnliche Navigation auf dem eigenen Testkonto durchführen.
3. Nur ein Zuwachs der Event-Anzahl zusammen mit einer aktualisierten Quell-CSV belegt fortlaufenden Import tatsächlich neuer Ereignisse.

## Defizit

Der bisherige `-Follow`-Modus bindet sich an **eine CSV-Datei** und erkennt nach Neustart des Sensors neue Dateien nicht automatisch. Eine sichere lokale Verzeichnis-Watch-Schicht kann diesen operativen Wechsel übernehmen. Sie soll keine Cookies, OAuth-Parameter, Antwortkörper oder Cookie-Werte in Git/Logs schreiben und keine zusätzlichen HTTP-Anfragen an IGGM erzeugen.

**Status:** Messbefund ohne Exploit-/Schwachstellenbehauptung. Git-Commit und Ereigniszeit sind voneinander zu unterscheiden.
