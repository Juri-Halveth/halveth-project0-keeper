[Original / Deutsch](README.md) · [English](README.en.md) · [Русский](README.ru.md)

# HALVETH Project0 Keeper

**Concise project guide · English**

The [German README](README.md) links to the public HALVETH work portfolio. This repository was empty in the documented snapshot of 28 September 2026 and received no work certificate in edition 1.1. A local TRIAD prototype was added later; it does not change that historical certificate snapshot.

`scripts/Invoke-Triad.ps1` reads this repository's Git branch, HEAD, changed paths and recent commits. ASTER records the observation, RACHEL adds fixed counter-readings, and SHELLA checks unstaged and staged diffs when changes exist. Runtime state and ledger entries are written only to the Git-ignored `.triad-runtime/` directory. The tracked `constellation/REPOSITORIES.json` is a historical snapshot, not a live GitHub inventory. The script does not modify source files, run other agents or write to GitHub.

With PowerShell 7 and Git, run `pwsh -NoProfile -File ./scripts/Test-Triad.ps1` and then `pwsh -NoProfile -File ./scripts/Invoke-Triad.ps1 -Cycles 1`. The [Integrity workflow](.github/workflows/triad-integrity.yml) checks the parser, role registry, three local cycles and a clean source tree. See the [role description](constellation/README.md) for the model.

## Start with the sources

- [Current German project guide](README.md)
- [README at the audited commit](https://github.com/Juri-Halveth/halveth-project0-keeper/blob/bbd16f9324dd04b3fc594a349e7c766629c130d4/README.md)
- [Work portfolio](https://juri-halveth.github.io/werkzertifikate/)

## Rights and scope

HALVETH work certificates mentioned in the German guide are private project documentation, not institutional personal qualifications or an ISTQB certification.

Use the original rights and licence notices for the relevant files and versions. This guide grants no additional licence.
