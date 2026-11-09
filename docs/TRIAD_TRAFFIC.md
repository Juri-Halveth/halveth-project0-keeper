# TRIAD TRAFFIC · Local observation bridge (proposal)

**Status:** source implementation on a review branch, not a hosted service.  
**Origin:** the project's owner proposed connecting the existing HALVETH browser live monitor and TTP register to the ASTER/RACHEL/SHELLA keeper, with millisecond-level chronological comparisons. Implementation and tests are AI-assisted.  
**Scope:** passive **local** import of a user-owned browser observer's already-redacted CSV. No active remote requests, browser login automation, injection, replay, or scanning.

## Where it fits

```text
Owner's Chrome session
    |
    v
Local browser monitor (separate test profile)
    |   V2 CSV: timestamp, event kind, redacted route, HTTP metadata
    v
scripts/Import-TriadTraffic.ps1
    |   sanitized, time-ordered JSONL and summary
    v
.triad-runtime/traffic/             (ignored by Git)
    |              |               |
    v              v               v
ASTER          RACHEL          SHELLA
observation    provenance       propose verification
    \              |              /
     \------> reviewed commits <---/
                GitHub CI
```

The current TRIAD engine already binds observations to its own Git repo, writes local runtime receipts, and checks its source diff. This is an **adjacent importer**, not a replacement for the engine. Connecting the importer results to an automatic decision loop would require a separate reviewed change.

## One-shot import

From a local clone of `halveth-project0-keeper`:

```powershell
$log = Get-ChildItem "$HOME\HALVETH_IGGM_LIVE" -Filter 'LIVE_V2_*_EVENTS.csv' -File |
  Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $log) { throw 'No V2 CSV found.' }
./scripts/Import-TriadTraffic.ps1 -CsvPath $log.FullName -AllowedHost 'www.iggm.com'
```

For a recording that is currently being appended to, use the same command with `-Follow -PollMilliseconds 1000`. Stop with `Ctrl+C`. The recorder must already be running: the importer does not start a new browser or connect to the website. An incomplete CSV while appending is retried. For large 24/7 recordings, rotate recording files by session; this first version rescans the CSV during follow and is not yet optimized for unbounded volume.

## What it computes

| Field | Meaning | Limit |
| --- | --- | --- |
| `TimeUtc` | Timestamp when the observer wrote the event | Not server clock |
| `GapMs` | Wall-clock interval between successive observed log events | **Not HTTP latency** |
| `ElapsedMs` | Time since first observed log event | Can include pauses and idle time |
| `RequestLatencyMs` | `null` | The current V2 source does not expose reliable request IDs/start-to-finish timing |
| `AuthMarker` | Anonymous or populated HTML marker | Not server-side authorization proof |
| `TTPs` | TTP IDs signaled by event kind/headers | Not a confirmed vulnerability |

Inter-event gaps may legitimately be **0 ms** when timestamps coincide. The run duration is not capped, but local storage and log rotation need management for long-running captures. A future request-duration sensor needs a per-request correlation ID and monotonic timestamps from `Network.requestWillBeSent`, `Network.responseReceived`, `Network.loadingFinished`, and `Network.loadingFailed`. Only then could it compute start-to-finish durations and separate queueing, response wait, and transfer time where supported.

## Security and privacy

- The importer **never** sends HTTP/WebSocket requests or accesses Chrome credentials. It reads an already-produced local CSV.
- The output is written under `.triad-runtime/traffic/`, ignored by `.gitignore`. It is **not uploaded to GitHub**.
- Only the configured `-AllowedHost` is retained in routes; queries and unknown path segments are redacted.
- It does not persist cookie values, cookie names, response bodies, notes, OAuth tokens, referers, or user email addresses. Source CSV is not modified.
- Real browser recordings can contain personal data even after sanitization. Do not commit raw recordings, Chrome profiles, HAR files, or source CSVs. Review all proposed evidence before publication.
- GitHub Actions tests run against **synthetic fixture rows**, never on live user sessions.
- A public repository is not automatically legally open-source without an explicit license. This repository presently has no top-level `LICENSE` file. License choice and third-party compatibility should be reviewed by the owner before declaring a public software license; no license change is made by this bridge.

## Source and validation

- `scripts/Import-TriadTraffic.ps1`: importer and optional follow mode.
- `scripts/Test-TriadTraffic.ps1`: deterministic test fixture verifying event count, timestamp differences, auth-marker labeling, TTP tags, input immutability and protection against secret exposure.
- `.github/workflows/triad-traffic.yml`: Windows PowerShell test on commits and pull requests.

Successful CI validates the synthetic input/output behavior, not any claim about the target website's security.