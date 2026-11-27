# HALVETH · Capability Atlas: vorhandene Arbeit als gebundene Fähigkeiten

**Stand:** 2026-11-09, selektive Sichtung der verknüpften GitHub-Quellen.  
**Ursprung der Integrationsidee:** Juri Janovski / Juri-Halveth: bestehende Repositories als sich ergänzende Fähigkeiten wiederfinden und unter Provenienz zu einer lokalen Arbeitskette verbinden, statt alles neu zu schreiben.  
**Sichtung und Umsetzung:** mit ChatGPT-Unterstützung.  
**Status:** Review-Branch, noch kein laufender plattformübergreifender Gesamtservice.

## Verifizierte Bausteine

Die maschinenlesbare, **ausschließlich öffentliche** Liste liegt in [`catalog/HALVETH_CAPABILITIES.json`](../catalog/HALVETH_CAPABILITIES.json). Pro Eintrag sind Repository, festgestellter Git-Commit, Quellpfad, Rechtekarte, Funktion und Integrationsgrenze gebunden.

| Schicht | Vorhandener Baustein | Nachgewiesene Quelle | Integrationsstatus |
| --- | --- | --- | --- |
| Lokale Steuerung | Project0 Keeper / TRIAD: ASTER, RACHEL, SHELLA, Git-Zustände und lokales Ledger | [Keeper README](https://github.com/Juri-Halveth/halveth-project0-keeper/blob/main/README.md) | Existierender lokaler Kern |
| Passive Telemetrie | TRIAD Traffic: normalisierte lokale Browser-CSV mit Auth-Markern und Millisekunden-Ereignisabständen | [Review-PR #10](https://github.com/Juri-Halveth/halveth-project0-keeper/pull/10) | Getestet auf synthetischen Windows-Quellen, Nutzerlauf und AutoSwitch im Review-Branch bestätigt; **nicht** in `main` |
| Sicherheit im eigenen Labor | Forschungslabor Security Workbench: synthetische Alice/Bob-Identitätsbindung und lokaler HTTP-Labordienst | [Security Workbench](https://github.com/Juri-Halveth/halveth-forschungslabor/blob/main/branches/security-workbench/README.md) | Bereits dokumentierte Testumgebung; keine Fremdsitzungen |
| Prüfplanung | Security Research Hub: 18 Methoden, 13 Werkzeugprofile und Gegenproben | [Security Research Hub](https://github.com/Juri-Halveth/halveth-forschungslabor/blob/main/branches/security-research-hub/README.md) | Vorhandener Methoden-/Planungskatalog |
| Herkunft/Zustand | ASTER Source Lens und FEGEFEUER: Quelle vs. Darstellung, Ereignisidentität und Zustandsübergänge | [ASTER](https://github.com/Juri-Halveth/halveth-forschungslabor/blob/main/branches/aster-source-lens/README.md) · [FEGEFEUER](https://github.com/Juri-Halveth/halveth-forschungslabor/blob/main/branches/fegefeuer-provenance-transducer/README.md) | Lokale Modelle, **noch nicht** direkt an Browser-Traffic angeschlossen |
| Wissen und Wiederaufnahme | LUCINET / NOVA: Quellen indexieren, frühere/korrigierte Lesarten und Receipts bewahren | [NOVA](https://github.com/Juri-Halveth/lucinet-seedspace/blob/main/nova/README.md) | Bereits ausgeführte lokale Software mit eigenem Workspace, Integration als Referenz/Export noch offen |
| Protokollforschung | TRON Research Fork: java-tron Quell- und Transaktionszustände, explizit kein Sicherheitsimpact behauptet | [TRON Lab](https://github.com/Juri-Halveth/halveth-tron-security-lab/blob/develop/README.md) | Separate Forschungsumgebung, kein allgemeines Angriffswerkzeug |
| Gegenmodell | Field Difference Lab: identischer Ausgangszustand und alternative Regeln | [Field Difference](https://github.com/Juri-Halveth/halveth-field-difference-lab/blob/main/README.md) | Lokale Modell-/Negativkontrollen |

**Private Forschungsarchive gehören nicht in dieses öffentliche Verzeichnis.** Ein optionaler Import darf deren Quellen nur in einem lokal kontrollierten, explizit ausgewählten Workspace adressieren. Private Pfade, Dokumentinhalte und Ergebnisse werden nicht rückwirkend öffentlich gemacht.

## Das Pollen-Protokoll

```text
Eigener Browser / eigene synthetische Konten
     |
     v
Lokaler Beobachter   →  redigierte Ereignisse + Session-Grenzen
     |
     v
TRIAD Traffic        →  Event-IDs, Zeitpunkte, TTP-Labels, offene Prüffragen
     |                                |
     v                                v
NOVA Quellenindex             Security Workbench localhost
     |                        (Alice/Bob, negative controls)
     v                                |
Herkunft/Revision/Status              v
     +--------------------------> Befundprüfung
                                       |
                                       v
                           redigierte Git-Commits + PRs
```

Die Pfeile beschreiben die **vorgesehene** Verbindung der Module. Heute existieren nur einzelne, jeweils belegte Programme, nicht eine fertig verdrahtete Gesamtplattform.

### Schnittstellenvertrag (Vorschlag)

Ein zukünftiger lokaler Event-Adapter gibt **nur** freigegebene Metadaten weiter:

```json
{
  "schema": "HALVETH_AUTH_OBSERVATION_V0",
  "source_revision": "PINNED_COMMIT",
  "source_event_id": "LOCAL_EPHEMERAL_ID",
  "observed_utc": "2026-11-09T22:00:00Z",
  "kind": "AUTH_DECISION_OBSERVED_IN_LOCAL_FIXTURE",
  "principal_kind": "OWN_SYNTHETIC_TEST_ACCOUNT",
  "route_template": "/lab/document",
  "request_id_scope": "LOCAL_RUN_ONLY",
  "credential_payload": "NEVER_CAPTURED",
  "auth_outcome": "UNKNOWN",
  "evidence": "SYNTHETIC_FIXTURE",
  "next_check": "COMPARE_OWNER_BINDING"
}
```

Dieses JSON ist ein **Datenvertrag**, kein Screenshot eines echten Login-Passworts und kein Beleg eines bereits integrierten Dienstes.

## Was wir nicht verwechseln

- **Passwortfluss** ist nicht `Passwort lesen`. Ein sicherer Beobachter erfasst die beteiligten Stationen, Metadaten und Vertrauensgrenzen, niemals den eingegebenen Geheimwert.
- **Google-OAuth:** Google authentifiziert die Person an Google; die fremde Website erhält normalerweise Autorisierungs-/Identitätssignale, nicht das Google-Passwort. Die genauen Serverentscheidungen können wir aus dem Browser allein nicht sehen.
- **Eigener Login** zeigt nur Daten, auf die die eigene Browserinstanz Zugriff hat. Fremde Sitzungen bleiben eine getrennte, nicht durch Beobachtung delegierte Sicherheitsdomäne.
- **Browser-CDP** beobachtet angebundene Ziele. Andere Tabs, Browserprofile, Service Worker, Backends, IdPs und serverinterne Prüfungen sind damit **nicht automatisch vollständig sichtbar**.
- **Ereigniszeit** (`GapMs`) ist nicht HTTP-Antwortzeit. Letztere erfordert Request-ID und monotone Start-/Endmesspunkte.
- **Static sink != XSS**, **CORS wildcard != fremder Datenzugriff**, **Hash-Dump != Auth-Bypass**. Ein Log-Signal braucht kontrollierbaren Ursprung, nachweisbaren Effekt und negative Gegenprobe.
- **Git-Commit** dokumentiert eine Version und behauptet keine weltweite Priorität oder automatisch Patentrechte.

## Kontrollierte Tests vor Fremdsystemen

Das Forschungslabor besitzt ein eigenes negatives Authentifizierungsbeispiel:

```powershell
# im bewusst lokal geklonten, geprüften Forschungslabor-Repo:
node branches/security-workbench/cli.mjs runtime --require-patch
node branches/security-workbench/cli.mjs selftest
```

Dabei werden zwei eigene Loopback-Listener für synthetische Alice-/Bob-Objektbindungen verwendet; der absichtlich fehlerhafte Pfad und die korrekt abweisende Variante lassen sich vergleichen. Es werden keine fremden Konten, fremde Cookies oder öffentliche Produktionssysteme geprüft.

## Lizenz- und Rechtekarte

Ein öffentliches Repository ist nicht automatisch gemeinschaftlich unter einer einzigen Open-Source-Lizenz nutzbar.

- **Project0 Keeper:** Im gesichteten Root fehlte eine `LICENSE`-Datei; eine Open-Source-Lizenz für neue Gesamtkombinationen muss ausdrücklich entschieden werden.
- **Forschungslabor:** Code unter MIT, Daten unter CC0, eigene Erläuterungen unter CC BY 4.0 gemäß `LICENSES.md`.
- **NOVA:** wesentliche Kernmodule unter HALVETH PIRL 2.0 (*source-available*, nicht pauschal als OSI-Open-Source zu behandeln); daneben ausgewiesene MIT-/Fremdmaterial-Ausnahmen.
- **TRON Fork:** enthält Upstream-Quellen unter LGPL 3; eigene Beiträge und Originalrechte nicht miteinander vermischen.
- **Field Difference Lab:** Apache 2.0 laut eigener README/Lizenz.

**Konsequenz:** Vor einer Codeübernahme Lizenzprüfung pro Datei; vorerst nur **Schnittstellen, Links und Quell-Hashes** verbinden, keine pauschale Kopie aller Projekte.

## Nächste Version

1. Einen **lokalen, synthetischen Auth-Flow** von Eingabeereignis über Serverprüfung bis Session-Ausgabe mit klaren Trust-Boundaries anzeigen. Passwort selbst bleibt unsichtbar.
2. TRIAD Traffic um lokale Request-ID-Korrelation ergänzen, ohne Geheimwerte zu speichern.
3. Nur ausgewählte, bytegebundene Berichte aus TRIAD nach NOVA exportieren und im Workspace auf Korrekturen / offene Fragen prüfen.
4. Für echten Ein-Klick-Betrieb explizite Profile, vorab festgelegte Testziele, Abbruch-, Datenlösch- und Quellkontrollen definieren. Keine beliebigen URL-Eingaben als Scanauftrag.

Das Verzeichnis ist eine **belegte Architekturkarte und ein erster lesender Adapter**, noch keine vollständig ausgeführte Multi-Repository-Plattform.
