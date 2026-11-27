<#
  HALVETH Capability Atlas
  Reads only local manifest JSON. No network, no execution of other repositories.
#>
[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$IncludeNotes
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$file = Join-Path $root 'catalog/HALVETH_CAPABILITIES.json'
if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
    throw "Atlas manifest missing: $file"
}
$data = Get-Content -LiteralPath $file -Raw -Encoding UTF8 | ConvertFrom-Json
if ($data.schema -ne 'HALVETH_CAPABILITY_ATLAS_V1') {
    throw 'Unrecognized catalog format.'
}
$items = @($data.capabilities)
if ($items.Count -eq 0) { throw 'Atlas is empty.' }

if ($Json) {
    $data | ConvertTo-Json -Depth 12
    return
}

Write-Host ''
Write-Host ('HALVETH CAPABILITY ATLAS | ' + $data.capturedAt + ' | ' + $items.Count + ' source-bound modules') -ForegroundColor Cyan
Write-Host 'Observation != authorization. Metadata != credentials. Source != proven security impact.'
Write-Host 'Read-only index; no scanner, no web requests, no external code execution.'
Write-Host ''

$items | ForEach-Object {
    [pscustomobject]@{
        ID = $_.id
        Mode = $_.mode
        Source = $_.repo
        Role = $_.role
        Rights = $_.license
    }
} | Format-Table -AutoSize -Wrap

if ($IncludeNotes) {
    foreach ($item in $items) {
        Write-Host ''
        Write-Host ('[' + $item.id + '] ' + $item.role) -ForegroundColor Green
        Write-Host ('Source: https://github.com/' + $item.repo + '/blob/' + $item.commit + '/' + $item.path)
        Write-Host ('SHA-256: ' + $item.sourceSha256 + ' (' + $item.sourceBytes + ' bytes)')
    }
}

Write-Host ''
