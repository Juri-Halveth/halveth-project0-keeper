param(
    [string]$Intent='improve the local HALVETH constellation',
    [ValidateRange(1,100)]
    [int]$Cycles=3
)

$ErrorActionPreference='Stop'

$Repo=Split-Path -Parent (
    Split-Path -Parent $MyInvocation.MyCommand.Path
)

# Git -C selects a working directory, but these variables can still redirect
# repository identity, index or object lookup. Reject their presence explicitly;
# leave the caller's environment unchanged and report names rather than values.
$RepositoryOverrideNames=@(
    'GIT_DIR',
    'GIT_WORK_TREE',
    'GIT_INDEX_FILE',
    'GIT_COMMON_DIR',
    'GIT_OBJECT_DIRECTORY',
    'GIT_ALTERNATE_OBJECT_DIRECTORIES',
    'GIT_NAMESPACE'
)
$ActiveOverrides=@($RepositoryOverrideNames | Where-Object {
    Test-Path -LiteralPath ('Env:'+$_)
})
if($ActiveOverrides.Count -gt 0){
    throw ('Repository override environment variables are set: '+($ActiveOverrides -join ', ')+'. Start the engine in a repository-default environment.')
}

# Every source observation belongs to the repository containing this script,
# independently of the caller's current working directory. Native Git failures
# must stop the run instead of turning an error string into a runtime receipt.
function Invoke-RepoGit {
    param([string[]]$GitArguments)
    $Output=@(& git -C $Repo @GitArguments 2>&1)
    $GitExitCode=$LASTEXITCODE
    if($GitExitCode -ne 0){
        throw ('Repository observation failed (git '+($GitArguments -join ' ')+', exit '+$GitExitCode+').')
    }
    return $Output
}

$GitRoot=(Invoke-RepoGit -GitArguments @('rev-parse','--show-toplevel') | Out-String).Trim()
$ExpectedRoot=[System.IO.Path]::GetFullPath($Repo).TrimEnd([char[]]'\/')
$ActualRoot=[System.IO.Path]::GetFullPath($GitRoot).TrimEnd([char[]]'\/')
if($ActualRoot -ne $ExpectedRoot){
    throw 'The TRIAD engine must run from its own Git repository root.'
}

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
        Invoke-RepoGit -GitArguments @('branch','--show-current')
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
        Invoke-RepoGit -GitArguments @('rev-parse','--short','HEAD')
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
        Invoke-RepoGit -GitArguments @('status','--porcelain=v1','--untracked-files=all','--','.',':(exclude).triad-runtime/')
    )

    return @(
        $Rows |
        ForEach-Object {

            if($_.Length -gt 3){

                $Path=$_.Substring(3).Trim()

                $Path
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
            Invoke-RepoGit -GitArguments @('rev-parse','HEAD')
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
        Invoke-RepoGit -GitArguments @('log','-5','--pretty=format:%H|%cI|%s')
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

        Invoke-RepoGit -GitArguments @('diff','--check') | Out-Null
        Invoke-RepoGit -GitArguments @('diff','--cached','--check') | Out-Null
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
