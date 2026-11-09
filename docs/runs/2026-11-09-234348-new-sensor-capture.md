# HALVETH TRAFFIC · V2-Sensorlauf nach Neustart

**Beleg-ID:** HALVETH-V2-SENSOR-20261109-234348  
**Zeitbezug:** 2026-11-09, lokaler Sensorstart gemäß CSV-Dateinamen 23:43:48 Europe/Berlin  
**Quelle:** im Gespräch vom Nutzer eingereichte PowerShell-Konsole  
**Evidenzstatus:** OBSERVED_IN_USER_SUPPLIED_CONSOLE, nicht unabhängig aus den lokalen CSV-Bytes rekonstruiert  
**Ideenimpuls zu TRIAD/TTP/Git-Stempeln:** Juri Janovski / Juri-Halveth; Auswertung und Text KI-unterstützt

## Beobachtungen

Die Konsole meldet `HALVETH LIVE V2 AKTIV | passive Analyse | KEIN F12` und eine **neue** lokale Logdatei:
`LIVE_V2_20261109_234348_EVENTS.csv`.

Die chronologisch angezeigte Auswahl enthält:

1. `DOCUMENT HTTP=200 www.iggm.com/`, danach `AUTH_CHANGE unknown -> anonymous-marker`.
2. Abrufe statischer JavaScript-Dateien und Cookie-Header-Metadaten, keine Werte.
3. `DOCUMENT HTTP=200 www.iggm.com/login`, anschließend weitere statische Scripts.
4. `COOKIE_FLAGS HTTP=200 www.iggm.com/login/index`, danach `XHR HTTP=200 www.iggm.com/login/index`.
5. Erneute Hauptseite `DOCUMENT HTTP=200 www.iggm.com/`, danach `AUTH_CHANGE anonymous-marker -> email-populated-marker`.
6. `XHR HTTP=200 www.iggm.com/user/gettimezero` und normale Ajax-Aufrufe.

**Belegbare Aussage:** Der lokale V2-Sensor wurde nach dem zuvor stagnierenden Lauf neu gestartet, erzeugte eine neue Datei und protokollierte einen HTML-Anmeldemarker-Wechsel. Die gepostete Konsolenausgabe zeigt keinen `DEBUG_SIGNAL`- oder bcrypt-Treffer.

**Noch nicht belegt:** Dass TRIAD AutoSwitch die **neu erzeugte** CSV bereits übernommen hat; hierzu fehlt die Ausgabe des laufenden Keepers oder dessen Summary mit der neuen `SourceFile` und `SourceGeneration`. Auch ein weiterlaufender Datenstrom nach Abschluss des geposteten Ablaufs ist noch nicht separat bestätigt.

**Sicherheitsgrenze:** HTML-Marker sind kein serverseitiger Berechtigungsbeweis. HTTP 200, `COOKIE_FLAGS` oder `CODE_SIGNAL` sind keine Exploitnachweise. Der Verlauf zeigt keinen eindeutig belegten Google-OAuth-Callback, sondern den Pfad `/login/index`. Keine Cookies, Token, E-Mail-Adressen, Anfrageparameter oder Rohantworten im Commit.

## Nächster Kontrollpunkt

Aus der aktuellen TRIAD-JSON-Summary `SourceFile`, `Events`, `SourceGeneration`, `SourceHistory`, `UpdatedAtUtc` auslesen. Erwartete neue Quelle: `LIVE_V2_20261109_234348_EVENTS.csv`. Nur wenn der laufende TRIAD-AutoSwitch diese Datei meldet, ist der reale Dateiwechsel nach dem Neustart bestätigt.

Der Git-Commit belegt die nachträgliche Versionierung des Nutzerprotokolls, nicht eine Originalmessung durch GitHub Actions.
