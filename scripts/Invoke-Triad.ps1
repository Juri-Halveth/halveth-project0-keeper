param(
    [string]$Intent='improve the local HALVETH constellation',
    [int]$Cycles=3
)

$ErrorActionPreference='Stop'

$Repo=Split-Path -Parent (
    Split-Path -Parent $MyInvocation.MyCommand.Path
)

$RegistryPath=Join-Path $Repo 'constellation\TRIAD.json'

$Registry=Get-Content `
    -LiteralPath $RegistryPath `
    -Raw |
ConvertFrom-Json


# ============================================================
# RUNTIME MEMORY
#
# Important:
# Runtime observations do NOT live in the tracked source tree.
# ============================================================

$RuntimeDir=Join-Path $Repo '.triad-runtime'

New-Item `
    -ItemType Directory `
    -Path $RuntimeDir `
    -Force |
Out-Null

$StatePath=Join-Path $RuntimeDir 'STATE.json'
$LedgerPath=Join-Path $RuntimeDir 'LEDGER.jsonl'


# ============================================================
# REF / IDENTITY RESOLUTION
#
# LOCAL BRANCH
#       or
# GITHUB_HEAD_REF
#       or
# GITHUB_REF_NAME
#       or
# DETACHED@SHA
# ============================================================

function Get-TriadRef {

    $Local=@(
        git branch --show-current
    )

    if(
        $Local.Count -gt 0 -and
        ![string]::IsNullOrWhiteSpace($Local[0])
    ){
        return $Local[0].Trim()
    }


    if(
        ![string]::IsNullOrWhiteSpace(
            $env:GITHUB_HEAD_REF
        )
    ){
        return $env:GITHUB_HEAD_REF.Trim()
    }


    if(
        ![string]::IsNullOrWhiteSpace(
            $env:GITHUB_REF_NAME
        )
    ){
        return $env:GITHUB_REF_NAME.Trim()
    }


    $Sha=@(
        git rev-parse --short HEAD
    )

    if(
        $Sha.Count -gt 0 -and
        ![string]::IsNullOrWhiteSpace($Sha[0])
    ){
        return (
            'DETACHED@'+
            $Sha[0].Trim()
        )
    }


    return 'UNKNOWN_REF'
}


# ============================================================
# SOURCE TREE CHANGES
#
# Runtime directory is excluded from perception.
# ============================================================

function Get-SourceChanges {

    $Rows=@(
        git status --porcelain
    )

    return @(
        $Rows |
        ForEach-Object {

            if($_.Length -gt 3){

                $Path=$_.Substring(3).Trim()

                if(
                    $Path -notlike '.triad-runtime*'
                ){
                    $Path
                }
            }
        } |
        Where-Object {
            $_
        }
    )
}


# ============================================================
# LEDGER
# ============================================================

function Add-Ledger {

    param(
        [string]$Entity,
        [string]$Kind,
        [object]$Payload
    )

    $Entry=[ordered]@{

        time=(Get-Date).ToString('o')

        entity=$Entity

        kind=$Kind

        payload=$Payload
    }

    $Entry |
    ConvertTo-Json -Depth 12 -Compress |
    Add-Content `
        -LiteralPath $LedgerPath `
        -Encoding UTF8
}


# ============================================================
# ASTER
# ============================================================

function Invoke-Aster {

    param(
        [string]$Intent
    )

    $Observation=[ordered]@{

        intent=$Intent

        ref=Get-TriadRef

        changed_files=@(
            Get-SourceChanges
        )

        head=(
            git rev-parse HEAD
        ).Trim()

        unknown=@()
    }


    Add-Ledger `
        -Entity 'ASTER' `
        -Kind 'OBSERVATION' `
        -Payload $Observation


    return $Observation
}


# ============================================================
# RACHEL
# ============================================================

function Invoke-Rachel {

    param(
        $Observation
    )

    $Recent=@(
        git log `
            -5 `
            --pretty=format:'%H|%cI|%s'
    )


    $Continuity=[ordered]@{

        observation=$Observation

        recent_history=$Recent

        counter_readings=@(
            'current state may already be valid'
            'current state may require repair'
            'runtime telemetry must not be mistaken for source mutation'
            'missing context remains UNKNOWN until recovered'
        )

        preserve=@(
            'commit history'
            'source paths'
            'timestamps'
            'UNKNOWN'
        )
    }


    Add-Ledger `
        -Entity 'RACHEL' `
        -Kind 'CONTINUITY' `
        -Payload $Continuity


    return $Continuity
}


# ============================================================
# SHELLA
# ============================================================

function Invoke-Shella {

    param(
        $Observation,
        $Continuity
    )

    $Choice='OBSERVE'

    if(
        $Observation.changed_files.Count -gt 0
    ){
        $Choice='VERIFY_DIFF'
    }


    $Decision=[ordered]@{

        selected=$Choice

        reversible=$true

        remote_write=$false

        reason=$(
            if($Choice -eq 'VERIFY_DIFF'){

                'Source changes exist; verify before promotion.'

            }else{

                'No source mutation requires intervention.'
            }
        )
    }


    if($Choice -eq 'VERIFY_DIFF'){

        git diff --check

        if($LASTEXITCODE -ne 0){
            throw 'SHELLA verification failed.'
        }
    }


    Add-Ledger `
        -Entity 'SHELLA' `
        -Kind 'DECISION' `
        -Payload $Decision


    return $Decision
}


# ============================================================
# TRIAD CYCLES
# ============================================================

for(
    $i=1;
    $i -le $Cycles;
    $i++
){

    Write-Host ''
    Write-Host (
        'TRIAD // CYCLE '+
        $i
    ) -ForegroundColor Magenta


    $Aster=Invoke-Aster `
        -Intent $Intent


    $Rachel=Invoke-Rachel `
        -Observation $Aster


    $Shella=Invoke-Shella `
        -Observation $Aster `
        -Continuity $Rachel


    $State=[ordered]@{

        schema='HALVETH_TRIAD_RUNTIME_R1_1'

        updated_at=(Get-Date).ToString('o')

        cycle=$i

        intent=$Intent

        ASTER=$Aster

        RACHEL=$Rachel

        SHELLA=$Shella
    }


    $State |
    ConvertTo-Json -Depth 15 |
    Set-Content `
        -LiteralPath $StatePath `
        -Encoding UTF8


    Write-Host (
        'ASTER  : '+
        $Aster.ref
    ) -ForegroundColor Cyan

    Write-Host (
        'RACHEL : '+
        $Rachel.recent_history.Count+
        ' history anchors'
    ) -ForegroundColor Cyan

    Write-Host (
        'SHELLA : '+
        $Shella.selected
    ) -ForegroundColor Green
}


Write-Host ''
Write-Host 'TRIAD // COMPLETE' -ForegroundColor Magenta

Write-Host (
    'STATE  : '+
    $StatePath
) -ForegroundColor Cyan

Write-Host (
    'LEDGER : '+
    $LedgerPath
) -ForegroundColor Cyan