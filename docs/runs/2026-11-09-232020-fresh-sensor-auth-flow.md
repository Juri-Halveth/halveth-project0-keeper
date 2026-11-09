# HALVETH TRIAD Traffic · frischer V2-Mitschnitt nach Sensor-Neustart

**Beleg-ID:** HALVETH-TRAFFIC-20261109-232020  
**Beobachtete Quelle:** Nutzerseitig kopierte Windows-PowerShell-Ausgabe  
**CSV laut Sensor:** `LIVE_V2_20261109_232020_EVENTS.csv`  
**Ideenimpuls zum TRIAD-Traffic-Verbund:** Juri Janovski / Juri-Halveth  
**Auswertung / Dokumentation:** KI-unterstützt, anhand des bereitgestellten Konsolentextes  
**Status:** OBSERVED_IN_USER_SUPPLIED_CONSOLE, kein unabhängiger Server- oder Dateiabruf

## Beobachtete Abfolge

1. `HALVETH LIVE V2 AKTIV`: V2-Sensor startet im neuen isolierten Browserprofil, keine aktiven Zusatzanfragen.
2. `DOCUMENT HTTP=200 www.iggm.com/`, gefolgt von `AUTH_CHANGE unknown -> anonymous-marker`.
3. Mehrere `CODE_SIGNAL`-Muster in statischen JS-Dateien. Statische Syntax ist kein Exploitnachweis.
4. `COOKIE_FLAGS`-Ereignisse für AJAX- und Loginrouten, ohne Cookie-Werte.
5. `COOKIE_FLAGS HTTP=200 www.iggm.com/login/thirdLoginConnect/google` und `XHR HTTP=200` auf demselben Pfad.
6. `ERROR ... www.iggm.com/login net::ERR_ABORTED`. Ein solcher Browserabbruch kann auch durch Navigation/Kontextwechsel entstehen und beweist keine Sicherheitslücke.
7. `COOKIE_FLAGS HTTP=200 www.iggm.com/login/index` und `XHR HTTP=200` auf diesem Pfad.
8. Erneute Hauptseite `DOCUMENT HTTP=200 www.iggm.com/`, danach `AUTH_CHANGE anonymous-marker -> email-populated-marker`.
9. Anschließend `XHR HTTP=200 www.iggm.com/user/gettimezero` und weitere normale AJAX-Aufrufe.

## Abgrenzungen

- Der HTML-Marker zeigt einen **clientseitig beobachteten Statuswechsel**, nicht allein den serverseitigen Berechtigungsstatus.
- Das gezeigte Fragment enthält keine `DEBUG_SIGNAL`-Meldung oder bcrypt-Ausgabe; das ist kein Nachweis, dass es sie in anderen Läufen nie gab.
- Die Reihenfolge der XHRs belegt noch keine kausale Abhängigkeit zwischen einzelnen Requests.
- Ob der zusätzliche lokale `Import-TriadTraffic.ps1 -Follow` die neue CSV tatsächlich importiert, ist **nicht** durch die hier gepostete Sensor-Konsolenausgabe belegt. Dazu wird der aktuelle TRIAD-Summary-Stand benötigt.
- `COOKIE_FLAGS` beweist keine Session-Rotation, Cookie-Exfiltration oder Authentifizierungsumgehung.
- Keine OAuth-Codes, Cookie-Werte, E-Mail-Adressen, Anfrageparameter oder vollständigen Antworttexte in Git aufgenommen.

## Nächster Messpunkt

Eine lokale `TRIAD_TRAFFIC_*_SUMMARY.json` im TRIAD-Runtime-Verzeichnis prüfen. Sie soll `SourceFile=LIVE_V2_20261109_232020_EVENTS.csv` sowie die wachsende Ereignisanzahl und den letzten `LastAuthMarker=email-populated-marker` zeigen. Erst dann ist das Zusammenspiel von **frischem** Sensor und laufendem Importer über diese CSV verifiziert.

**Kein aktiver Sicherheitstest oder Exploitnachweis.** Git-Commit dokumentiert einen nachträglichen Beleg aus Nutzerkonsole.
