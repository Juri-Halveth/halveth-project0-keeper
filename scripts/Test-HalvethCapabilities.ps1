# HALVETH Capability Atlas: deterministic offline contract checks
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$path = Join-Path $root 'catalog/HALVETH_CAPABILITIES.json'
$show = Join-Path $root 'scripts/Show-HalvethCapabilities.ps1'

function Assert-Atlas([bool]$ok, [string]$description) {
    if (-not $ok) { throw ('CAPABILITY ATLAS FAIL: ' + $description) }
}

Assert-Atlas (Test-Path -LiteralPath $path -PathType Leaf) 'manifest missing'
Assert-Atlas (Test-Path -LiteralPath $show -PathType Leaf) 'read-only viewer missing'

$before = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
$atlas = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
Assert-Atlas ($atlas.schema -eq 'HALVETH_CAPABILITY_ATLAS_V1') 'schema mismatch'
Assert-Atlas ($atlas.capturedAt -eq '2026-11-09') 'snapshot date mismatch'
Assert-Atlas ($atlas.securityPolicy.noSecretCapture -eq $true) 'secret protection missing'
Assert-Atlas ($atlas.securityPolicy.noThirdPartyReplay -eq $true) 'third-party replay protection missing'
Assert-Atlas ($atlas.securityPolicy.publicRegistryExcludesPrivateRepositories -eq $true) 'private source restriction missing'

$items = @($atlas.capabilities)
Assert-Atlas ($items.Count -eq 8) 'expected eight grounded public modules'
$ids = @($items | ForEach-Object { $_.id })
Assert-Atlas ((@($ids | Select-Object -Unique)).Count -eq $items.Count) 'duplicate capability ID'

$allowedModes = @('LOCAL', 'LOCAL_SYNTHETIC', 'READ_ONLY', 'LOCAL_LAB')
foreach ($item in $items) {
    Assert-Atlas (-not [string]::IsNullOrWhiteSpace([string]$item.id)) 'blank capability ID'
    Assert-Atlas ([string]$item.repo -match '^Juri-Halveth/[A-Za-z0-9._-]+$') 'unexpected source repository'
    Assert-Atlas ([string]$item.commit -match '^[0-9a-f]{40}$') 'source commit not pinned'
    Assert-Atlas (([string]$item.path -ne '') -and ([string]$item.path -notmatch '^[/\\]|\.\.|[?#]')) 'unsafe source path'
    Assert-Atlas ([string]$item.mode -in $allowedModes) 'unsupported execution mode'
    Assert-Atlas ([string]$item.license -ne '') 'missing rights status'
    Assert-Atlas ([string]$item.status -eq 'SOURCE_READ') 'unreviewed evidence status'
    Assert-Atlas ([string]$item.role -ne '') 'missing bounded purpose'
}

$jsonText = & $show -Json
$again = ($jsonText | Out-String) | ConvertFrom-Json
Assert-Atlas (@($again.capabilities).Count -eq $items.Count) 'viewer JSON roundtrip'
Assert-Atlas ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -eq $before) 'viewer modified manifest'

Write-Host 'CAPABILITY ATLAS JSON     : PASS' -ForegroundColor Green
Write-Host 'SOURCES AND RIGHTS        : PASS' -ForegroundColor Green
Write-Host 'PRIVATE SOURCE EXCLUSION  : PASS' -ForegroundColor Green
Write-Host 'READ ONLY ROUNDTRIP       : PASS' -ForegroundColor Green
