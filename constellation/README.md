# HALVETH TRIAD

ASTER + RACHEL + SHELLA

```text
ASTER
  |
  v
OBSERVE
  |
  v
RACHEL
  |
  v
CONTINUITY
  |
  v
SHELLA
  |
  v
DECISION
  |
  v
ACTION
  |
  v
VERIFY
  |
  +-------> ASTER
```

## Meaning

ASTER observes.

RACHEL preserves continuity and counter-readings.

SHELLA chooses and executes within delegated authority.

None of the three replaces the others.

Every cycle returns its result to the other two.

## Core invariants

- UNKNOWN != FALSE
- SOURCE != TRUTH
- SIMILARITY != CAUSALITY
- ABBILD != PERSON
- PRESERVE > DESTROY
- VERIFY > ASSUME
- REVERSIBLE > IRREVERSIBLE

## GitHub

This repository acts as the shared public control-plane.

Repository metadata can be refreshed locally with GitHub CLI.

## Local runtime boundary

`scripts/Invoke-Triad.ps1` reads the Git repository that contains the engine,
even when invoked from another directory. It leaves the caller's working
directory unchanged. Native Git errors stop the run before a successful state
receipt is written. Both staged and unstaged diffs are checked; generated
`.triad-runtime/` files remain separate from source observations.

The engine rejects an environment containing `GIT_DIR`, `GIT_WORK_TREE`,
`GIT_INDEX_FILE`, `GIT_COMMON_DIR`, `GIT_OBJECT_DIRECTORY`,
`GIT_ALTERNATE_OBJECT_DIRECTORIES` or `GIT_NAMESPACE` before reading Git or
writing runtime records. These overrides can select a different repository,
index or object source even when the working directory matches. The diagnostic
lists variable names only; the engine leaves the caller's environment intact.
Normal Git configuration remains available.

Cycles are explicitly bounded to 1–100. This engine observes local Git metadata
and selects a local verification step; it does not run a trading service,
connect a wallet, or apply its declared action proposals automatically.

Run the parser/registry check and the isolated runtime regression from PowerShell:

```powershell
./scripts/Test-Triad.ps1
./scripts/Test-TriadRuntime.ps1
```
