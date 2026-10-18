<!-- HUB_LANGUAGES_V1 -->
[Original / Deutsch](README.md) · [English](README.en.md) · [Русский](README.ru.md)
<!-- /HUB_LANGUAGES_V1 -->

# HALVETH Project0 Keeper

## Juri Janovski / Juri Halveth – HALVETH VERACHEL STUDIOS

[Öffentliches Werkportfolio: alle elf privaten HALVETH-Werkzertifikate mit vollständigen Namen, Quellständen und SHA-256-Belegen](https://juri-halveth.github.io/werkzertifikate/).

Dieses Repository war im dokumentierten Snapshot vom 28.09.2026 leer und erhält in Ausgabe 1.1 kein Werkzertifikat. Seitdem wurde der lokale TRIAD-Prototyp ergänzt; der historische Zertifikatsstand bleibt davon unberührt.

Die dortigen Zertifikate sind private, mit Codex erstellte Werkdokumentation. Sie verleihen keine ISTQB-Qualifikation oder sonstige Personenzertifizierung.

## Aktueller Prototyp

`scripts/Invoke-Triad.ps1` führt drei benannte Rollen in einer lokalen Prüfschleife aus:

- **ASTER** liest Branch, Commit und geänderte Pfade dieses Repositorys.
- **RACHEL** ergänzt die letzten fünf Commits und feste Gegenlesarten.
- **SHELLA** wählt `OBSERVE` oder bei Änderungen `VERIFY_DIFF` und prüft dann ungestagte sowie gestagte Diffs mit `git diff --check`.

Laufende Beobachtungen landen unter `.triad-runtime/STATE.json` und `.triad-runtime/LEDGER.jsonl`. Das Verzeichnis ist Git-ignoriert. Die versionierten Dateien unter `constellation/` sind Quellen und historische Snapshots, keine automatisch aktualisierte Laufzeitdatenbank. Insbesondere ist `REPOSITORIES.json` kein aktuelles Inventar aller GitHub-Repositories.

Mit PowerShell 7 und Git lokal prüfen:

```powershell
pwsh -NoProfile -File ./scripts/Test-Triad.ps1
pwsh -NoProfile -File ./scripts/Invoke-Triad.ps1 -Intent 'Lokalen Stand prüfen' -Cycles 1
```

Die Schleife liest Git-Daten des Keeper-Repositories und schreibt nur ihren lokalen Laufzeitstand. Sie ändert keinen Quellcode, startet keine anderen Agenten und schreibt nichts auf GitHub. Der [Integrity-Workflow](.github/workflows/triad-integrity.yml) prüft Parser, Rollenregister, drei lokale Zyklen und einen unveränderten Quellbaum. [Rollen und Grenzen](constellation/README.md).
