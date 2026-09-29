param(
    [string]$Intent='improve the local HALVETH constellation',
    [int]$Cycles=3
)

$ErrorActionPreference='Stop'

$Repo=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

$Registry=Get-Content `
    -LiteralPath (Join-Path $Repo 'constellation\TRIAD.json') `
    -Raw |
ConvertFrom-Json

$StatePath=Join-Path $Repo 'constellation\STATE.json'
$LedgerPath=Join-Path $Repo 'constellation\LEDGER.jsonl'

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
    ConvertTo-Json -Depth 10 -Compress |
    Add-Content `
        -LiteralPath $LedgerPath `
        -Encoding UTF8
}


function Invoke-Aster {

    param(
        [string]$Intent
    )

    $GitStatus=@(
        git status --porcelain
    )

    $Observation=[ordered]@{

        intent=$Intent

        branch=(
            git branch --show-current
        ).Trim()

        changed_files=@(
            $GitStatus |
            ForEach-Object {
                if($_.Length -gt 3){
                    $_.Substring(3).Trim()
                }
            } |
            Where-Object { $_ }
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
            'current state may be valid'
            'current state may require repair'
            'missing context must remain UNKNOWN until recovered'
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


function Invoke-Shella {

    param(
        $Observation,
        $Continuity
    )

    $Choice='OBSERVE'

    if($Observation.changed_files.Count -gt 0){

        $Choice='VERIFY_DIFF'
    }

    $Decision=[ordered]@{

        selected=$Choice

        reversible=$true

        remote_write=$false

        reason=$(
            if($Choice -eq 'VERIFY_DIFF'){
                'Changes exist; verify before promotion.'
            }else{
                'No uncommitted changes require action.'
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


for($i=1;$i -le $Cycles;$i++){

    Write-Host ''
    Write-Host ('TRIAD // CYCLE '+$i) -ForegroundColor Magenta

    $Aster=Invoke-Aster `
        -Intent $Intent

    $Rachel=Invoke-Rachel `
        -Observation $Aster

    $Shella=Invoke-Shella `
        -Observation $Aster `
        -Continuity $Rachel

    $State=[ordered]@{

        schema='HALVETH_TRIAD_RUNTIME_R1'

        updated_at=(Get-Date).ToString('o')

        cycle=$i

        intent=$Intent

        ASTER=$Aster

        RACHEL=$Rachel

        SHELLA=$Shella
    }

    $State |
    ConvertTo-Json -Depth 12 |
    Set-Content `
        -LiteralPath $StatePath `
        -Encoding UTF8

    Write-Host ('ASTER  : '+$Aster.branch) -ForegroundColor Cyan
    Write-Host ('RACHEL : '+$Rachel.recent_history.Count+' history anchors') -ForegroundColor Cyan
    Write-Host ('SHELLA : '+$Shella.selected) -ForegroundColor Green
}

Write-Host ''
Write-Host 'TRIAD // COMPLETE' -ForegroundColor Magenta