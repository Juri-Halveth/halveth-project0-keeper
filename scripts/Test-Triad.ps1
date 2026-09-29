$ErrorActionPreference='Stop'

$Root=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

$RegistryPath=Join-Path $Root 'constellation\TRIAD.json'
$EnginePath=Join-Path $Root 'scripts\Invoke-Triad.ps1'

$Registry=Get-Content `
    -LiteralPath $RegistryPath `
    -Raw |
ConvertFrom-Json

$Names=@(
    $Registry.entities.PSObject.Properties.Name
)

foreach($Required in @(
    'ASTER',
    'RACHEL',
    'SHELLA'
)){

    if($Names -notcontains $Required){
        throw "Missing entity: $Required"
    }
}

$Tokens=$null
$Errors=$null

[System.Management.Automation.Language.Parser]::ParseFile(
    $EnginePath,
    [ref]$Tokens,
    [ref]$Errors
) | Out-Null

if($Errors.Count -gt 0){

    throw (
        $Errors |
        ForEach-Object {
            $_.Message
        } |
        Out-String
    )
}

Write-Host 'TRIAD REGISTRY : PASS' -ForegroundColor Green
Write-Host 'ENGINE PARSER  : PASS' -ForegroundColor Green
Write-Host 'ASTER           : PASS' -ForegroundColor Green
Write-Host 'RACHEL          : PASS' -ForegroundColor Green
Write-Host 'SHELLA          : PASS' -ForegroundColor Green