[Deutsch](README.md) · [English](README.en.md) · [Русский](README.ru.md)

# TRIAD · local project control

PowerShell tools and state files for the experimental control plane of ASTER, RACHEL and SHELLA. Current source covers observation, continuity, decisions and checks; it does not contain a trading or yield service.

[**Open project →**](scripts/) · [Concept and state files](constellation/README.md) · [Portfolio](https://juri-halveth.github.io/en/)

- [Tools](scripts/)
- [Concept and state files](constellation/)

## Run one observation cycle

Use Git and PowerShell 7. From the repository, run one local cycle.

```powershell
pwsh -NoProfile -File ./scripts/Invoke-Triad.ps1 -Cycles 1
```

ASTER reads the branch, commit and changed paths. RACHEL compares the commit with the previous saved cycle. SHELLA checks staged and unstaged diffs for changes. A new commit or an unreadable prior state also flags the history for review. Read the decision in `.triad-runtime/STATE.json`.

The [runtime test](scripts/Test-TriadRuntime.ps1) uses two temporary repositories and varies the commit while keeping the changed-file list fixed.

The [local source catalog](catalog/HALVETH_CAPABILITIES.json) lists eight modules, their roles and the exact source files reviewed. Run `./scripts/Show-HalvethCapabilities.ps1 -IncludeNotes` to look up their source links and SHA-256 digests offline.
