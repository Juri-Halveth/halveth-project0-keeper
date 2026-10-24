$ErrorActionPreference='Stop'
$SourceRoot=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$TestRoot=Join-Path ([System.IO.Path]::GetTempPath()) ('halveth-triad-test-'+[guid]::NewGuid().ToString('N'))
$Fixture=Join-Path $TestRoot 'engine-repository'
$Foreign=Join-Path $TestRoot 'caller-repository'
$Shell=(Get-Process -Id $PID).Path

function Assert-Runtime($Condition,[string]$Message){
    if(!$Condition){throw $Message}
}
function Invoke-TestGit([string]$Directory,[string[]]$Arguments){
    $Result=@(& git -C $Directory @Arguments 2>&1)
    if($LASTEXITCODE -ne 0){throw ('Test fixture Git failed: '+($Arguments -join ' '))}
    return $Result
}
function Invoke-TestEngine([string]$Engine,[string]$Log){
    $PreviousErrorActionPreference=$ErrorActionPreference
    try{
        # Windows PowerShell 5.1 converts expected child stderr into an ErrorRecord.
        # Preserve it in the test log and inspect the exit code; the engine itself
        # still fails closed under its own Stop preference.
        $ErrorActionPreference='Continue'
        & $Shell -NoProfile -NonInteractive -File $Engine -Cycles 1 *> $Log
        return $LASTEXITCODE
    }finally{$ErrorActionPreference=$PreviousErrorActionPreference}
}

try{
    New-Item -ItemType Directory -Path (Join-Path $Fixture 'scripts'),(Join-Path $Fixture 'constellation'),$Foreign -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $SourceRoot 'scripts/Invoke-Triad.ps1') -Destination (Join-Path $Fixture 'scripts/Invoke-Triad.ps1')
    Copy-Item -LiteralPath (Join-Path $SourceRoot 'constellation/TRIAD.json') -Destination (Join-Path $Fixture 'constellation/TRIAD.json')
    Set-Content -LiteralPath (Join-Path $Fixture '.gitignore') -Value '.triad-runtime/' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $Foreign 'caller.txt') -Value 'Unrelated caller repository' -Encoding UTF8
    foreach($Directory in @($Fixture,$Foreign)){
        Invoke-TestGit $Directory @('init','-b','main') | Out-Null
        Invoke-TestGit $Directory @('add','.') | Out-Null
        Invoke-TestGit $Directory @('-c','user.name=Local Test','-c','user.email=fixture@example.invalid','commit','-m','Local synthetic fixture') | Out-Null
    }
    $ExpectedHead=(Invoke-TestGit $Fixture @('rev-parse','HEAD') | Out-String).Trim()
    $ForeignHead=(Invoke-TestGit $Foreign @('rev-parse','HEAD') | Out-String).Trim()
    Set-Content -LiteralPath (Join-Path $Fixture '.triad-runtime-notes.txt') -Value 'Source with a similar prefix must remain visible.' -Encoding UTF8
    $Engine=Join-Path $Fixture 'scripts/Invoke-Triad.ps1'
    Push-Location $Foreign
    try{
        $EngineExit=Invoke-TestEngine $Engine (Join-Path $TestRoot 'valid.log')
        Assert-Runtime ($EngineExit -eq 0) 'The bound engine failed from a foreign working directory.'
        Assert-Runtime ((Get-Location).Path -eq $Foreign) 'The engine changed its caller location.'
    }finally{Pop-Location}
    $StatePath=Join-Path $Fixture '.triad-runtime/STATE.json'
    $State=Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json
    Assert-Runtime ($State.ASTER.head -eq $ExpectedHead) 'Runtime HEAD belongs to the caller instead of the engine.'
    Assert-Runtime ($State.ASTER.changed_files -contains '.triad-runtime-notes.txt') 'A source file with a similar runtime prefix was hidden.'
    Assert-Runtime (@($State.ASTER.changed_files | Where-Object {$_ -like '.triad-runtime/*'}).Count -eq 0) 'Generated runtime observations leaked into source changes.'
    Assert-Runtime (@(Invoke-TestGit $Foreign @('status','--porcelain')).Count -eq 0) 'The unrelated caller repository was changed.'

    $Before=(Get-FileHash -LiteralPath $StatePath -Algorithm SHA256).Hash
    $LedgerPath=Join-Path $Fixture '.triad-runtime/LEDGER.jsonl'
    $BeforeLedger=(Get-FileHash -LiteralPath $LedgerPath -Algorithm SHA256).Hash
    $Overrides=@{
        GIT_DIR=(Join-Path $Foreign '.git')
        GIT_WORK_TREE=$Fixture
        GIT_INDEX_FILE=(Join-Path $Foreign '.git/index')
        GIT_COMMON_DIR=(Join-Path $Foreign '.git')
        GIT_OBJECT_DIRECTORY=(Join-Path $Foreign '.git/objects')
        GIT_ALTERNATE_OBJECT_DIRECTORIES=(Join-Path $Foreign '.git/objects')
        GIT_NAMESPACE='synthetic-other-namespace'
    }
    $SavedEnvironment=@{}
    foreach($Name in $Overrides.Keys){
        $SavedEnvironment[$Name]=@{
            Present=(Test-Path -LiteralPath ('Env:'+$Name))
            Value=[Environment]::GetEnvironmentVariable($Name,'Process')
        }
    }
    $Cases=@(@{GIT_DIR=$Overrides.GIT_DIR;GIT_WORK_TREE=$Overrides.GIT_WORK_TREE})
    foreach($Name in ($Overrides.Keys | Sort-Object)){$Cases+=@{$Name=$Overrides[$Name]}}
    try{
        foreach($Case in $Cases){
            foreach($Name in $Overrides.Keys){Remove-Item -LiteralPath ('Env:'+$Name) -ErrorAction SilentlyContinue}
            foreach($Name in $Case.Keys){[Environment]::SetEnvironmentVariable($Name,$Case[$Name],'Process')}
            $OverrideLog=Join-Path $TestRoot 'override-rejected.log'
            $EngineExit=Invoke-TestEngine $Engine $OverrideLog
            $Observed=(Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json).ASTER.head
            Assert-Runtime ($EngineExit -ne 0) ('Repository overrides were accepted: own HEAD '+$ExpectedHead+', foreign HEAD '+$ForeignHead+', runtime HEAD '+$Observed)
            $Rejection=Get-Content -LiteralPath $OverrideLog -Raw
            Assert-Runtime ($Rejection -match 'Repository override environment variables') ('Override rejection was not explicit: '+$Rejection)
            Assert-Runtime ((Get-FileHash -LiteralPath $StatePath -Algorithm SHA256).Hash -eq $Before) 'Rejected overrides changed the prior runtime receipt.'
            Assert-Runtime ((Get-FileHash -LiteralPath $LedgerPath -Algorithm SHA256).Hash -eq $BeforeLedger) 'Rejected overrides changed the prior runtime ledger.'
            foreach($Name in $Case.Keys){Assert-Runtime ([Environment]::GetEnvironmentVariable($Name,'Process') -eq $Case[$Name]) 'The caller override environment changed.'}
        }
    }finally{
        foreach($Name in $Overrides.Keys){
            if($SavedEnvironment[$Name].Present){
                [Environment]::SetEnvironmentVariable($Name,$SavedEnvironment[$Name].Value,'Process')
            }else{Remove-Item -LiteralPath ('Env:'+$Name) -ErrorAction SilentlyContinue}
        }
    }
    Set-Content -LiteralPath (Join-Path $Fixture 'staged.txt') -Value 'Trailing whitespace must fail verification.  ' -Encoding UTF8
    Invoke-TestGit $Fixture @('add','staged.txt') | Out-Null
    $EngineExit=Invoke-TestEngine $Engine (Join-Path $TestRoot 'rejected.log')
    Assert-Runtime ($EngineExit -ne 0) 'Staged whitespace errors were falsely accepted.'
    Assert-Runtime ((Get-FileHash -LiteralPath $StatePath -Algorithm SHA256).Hash -eq $Before) 'A failed native Git check replaced the successful state receipt.'
    Write-Host 'TRIAD RUNTIME BINDING : PASS'
    Write-Host 'NATIVE GIT FAILURE   : PASS'
    Write-Host 'CALLER PRESERVED     : PASS'
    Write-Host 'GIT OVERRIDES REJECTED: PASS'
}finally{
    # The only recursively removed object is this test's fresh, literal temp root.
    $ResolvedTestRoot=[System.IO.Path]::GetFullPath($TestRoot)
    $ResolvedTemp=[System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')
    if(!$ResolvedTestRoot.StartsWith($ResolvedTemp+[System.IO.Path]::DirectorySeparatorChar,[System.StringComparison]::OrdinalIgnoreCase) -or !(Split-Path -Leaf $ResolvedTestRoot).StartsWith('halveth-triad-test-')){
        throw 'Test cleanup target was outside the expected temporary root.'
    }
    if(Test-Path -LiteralPath $ResolvedTestRoot){Remove-Item -LiteralPath $ResolvedTestRoot -Recurse -Force}
}

# Actions' PowerShell wrapper forwards LASTEXITCODE after the script returns.
# All assertions and cleanup succeeded; the intentionally rejected child is not
# the outcome of this test process. Uncaught assertion/cleanup errors never reach here.
exit 0
