[Deutsch](README.md) · [English](README.en.md) · [Русский](README.ru.md)

# TRIAD · lokale Projektsteuerung

PowerShell-Werkzeuge und Zustandsdateien für die experimentelle Steuerung von ASTER, RACHEL und SHELLA. Der aktuelle Quellstand dokumentiert Beobachtung, Kontinuität, Entscheidungen und Prüfungen; ein Handels- oder Ertragsdienst ist darin nicht enthalten.

**Direkt ansehen:** [Werkzeuge und Startskripte](scripts/). Dies ist ein lokaler Quellprototyp, kein gehosteter Dienst.

[Konzept und Zustandsdateien](constellation/README.md) · [HALVETH Starship Lab (optional)](https://juri-halveth.github.io/universum/)

![HALVETH / NETZ – TRIAD: drei verknüpfte Zustandsknoten](HALVETH_NETZ_HERO.svg)

## HALVETH Capability Atlas · bestehende Module wiederverwenden

Die [Capability Atlas](docs/HALVETH_CAPABILITY_ATLAS.md) verbindet die bereits dokumentierten Fähigkeiten aus dem Keeper, dem Forschungslabor, LUCINET/NOVA, TRON-Forschung und dem Field Difference Lab über **Quellen, Commits, Rechtezuordnung und Vertrauensgrenzen**. Die öffentliche, versionierte [Maschinenkarte](catalog/HALVETH_CAPABILITIES.json) nennt acht ausgewählte Module. Private Repositories und Browsergeheimnisse sind ausdrücklich nicht enthalten.

Der lokale Navigator ist lesend und benötigt keine Netzwerkverbindung:

```powershell
./scripts/Show-HalvethCapabilities.ps1 -IncludeNotes
./scripts/Test-HalvethCapabilities.ps1
```

Das Atlas-System übernimmt keine fremden Login-Sitzungen und führt keinen Code aus anderen Repositories aus. Für eigene synthetische Alice/Bob-Prüfungen verweist es auf das bereits vorhandene Sicherheitslabor. Open-Source-Lizenzen werden pro Quelle getrennt behandelt. Die Modulverbindung ist eine Architektur- und Datenvertragsbasis, **noch kein vollständig integrierter Laufzeitdienst**.
