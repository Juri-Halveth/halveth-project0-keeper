$ErrorActionPreference='Stop'
$Repo=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Tool=Join-Path $Repo 'scripts/Import-TriadTraffic.ps1'
$Temp=Join-Path ([IO.Path]::GetTempPath()) ('triad-traffic-fixture-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $Temp -Force | Out-Null
function Assert-Traffic([bool]$condition,[string]$message){
    if(-not $condition){throw ('TRIAD traffic test failed: '+$message)}
}
try {
    $tokens=$null;$errors=$null
    [System.Management.Automation.Language.Parser]::ParseFile(
        $Tool,[ref]$tokens,[ref]$errors
    ) | Out-Null
    Assert-Traffic ($errors.Count -eq 0) 'PowerShell parser found errors'

    $base='www.example.test'
    $rows=@(
        [pscustomobject][ordered]@{Seq='1';UTC='2026-11-09T21:00:00.000Z';Kind='DOCUMENT';Route="$base/";HTTP='200';Method='GET';LoginMarker='';CORS='not-seen';SetCookieFlags='';Note='SECRET_COOKIE_VALUE'},
        [pscustomobject][ordered]@{Seq='2';UTC='2026-11-09T21:00:00.075Z';Kind='AUTH_CHANGE';Route="$base/login";HTTP='200';Method='GET';LoginMarker='anonymous-marker';CORS='not-seen';SetCookieFlags='';Note=''},
        [pscustomobject][ordered]@{Seq='3';UTC='2026-11-09T21:00:00.500Z';Kind='XHR';Route="$base/login/index?oauth_code=LEAKME";HTTP='200';Method='POST';LoginMarker='';CORS='not-seen';SetCookieFlags='iggm_token[Secure=False,HttpOnly=False]';Note='LEAKME'},
        [pscustomobject][ordered]@{Seq='4';UTC='2026-11-09T21:00:00.505Z';Kind='COOKIE_FLAGS';Route="$base/login/index";HTTP='200';Method='POST';LoginMarker='';CORS='wildcard';SetCookieFlags='SESS_ID[Secure=False,HttpOnly=False,SameSite=unspecified]';Note='SESSIONVALUE_SHOULD_NEVER_APPEAR'},
        [pscustomobject][ordered]@{Seq='5';UTC='2026-11-09T21:00:00.515Z';Kind='AUTH_CHANGE';Route="$base/private/SECRETUSER";HTTP='200';Method='GET';LoginMarker='email-populated-marker';CORS='not-seen';SetCookieFlags='';Note='PRIVATE_EMAIL_SHOULD_NEVER_APPEAR'}
    )
    $CsvPath=Join-Path $Temp 'LIVE_V2_SYNTHETIC_EVENTS.csv'
    $OutputDir=Join-Path $Temp 'safe-output'
    $rows | Export-Csv -LiteralPath $CsvPath -NoTypeInformation -Encoding UTF8
    $inputSha=(Get-FileHash $CsvPath -Algorithm SHA256).Hash
    & $Tool -CsvPath $CsvPath -AllowedHost $base -OutputDirectory $OutputDir
    $SummaryFile=Get-ChildItem $OutputDir -Filter '*SUMMARY.json' | Select-Object -First 1
    $Events=Get-ChildItem $OutputDir -Filter '*EVENTS.jsonl' | Select-Object -First 1
    Assert-Traffic ($null -ne $SummaryFile -and $null -ne $Events) 'output missing'
    $SummaryData=Get-Content -LiteralPath $SummaryFile.FullName -Raw | ConvertFrom-Json
    $eventData=@(Get-Content -LiteralPath $Events.FullName | ForEach-Object {$_ | ConvertFrom-Json})
    Assert-Traffic ($SummaryData.Events -eq 5 -and $eventData.Count -eq 5) 'event counts'
    Assert-Traffic ($eventData[1].GapMs -eq 75) '75ms inter-event gap not preserved'
    Assert-Traffic ($eventData[4].ElapsedMs -eq 515) 'elapsed millisecond clock inaccurate'
    Assert-Traffic ($SummaryData.LastAuthMarker -eq 'email-populated-marker') 'auth marker not recorded'
    Assert-Traffic ($eventData[3].TTPs -contains 'TTP-009') 'CORS signal tag missing'
    Assert-Traffic ($null -eq $eventData[3].RequestLatencyMs) 'request latency must remain unknown'
    Assert-Traffic ($eventData[4].Route -match '\[segment\]') 'unknown path segment was not sanitized'
    $outText=(Get-Content -LiteralPath $Events.FullName -Raw)+(Get-Content -LiteralPath $SummaryFile.FullName -Raw)
    foreach($secret in @('SECRET_COOKIE_VALUE','LEAKME','SESSIONVALUE_SHOULD_NEVER_APPEAR','PRIVATE_EMAIL_SHOULD_NEVER_APPEAR','SECRETUSER','SESS_ID','iggm_token')){
        Assert-Traffic (-not $outText.Contains($secret)) ('unredacted field: '+$secret)
    }
    Assert-Traffic ((Get-FileHash $CsvPath -Algorithm SHA256).Hash -eq $inputSha) 'original CSV was modified'
    # Verify that one running importer notices a NEW sensor file by filename,
    # processes it once, and resets per-file gaps without spilling secrets.
    $WatchDir=Join-Path $Temp 'rotating-sources'
    $AutoOutput=Join-Path $Temp 'auto-output'
    New-Item -ItemType Directory -Path $WatchDir,$AutoOutput -Force | Out-Null
    $FirstFile=Join-Path $WatchDir 'LIVE_V2_20261109_220000_EVENTS.csv'
    $SecondFile=Join-Path $WatchDir 'LIVE_V2_20261109_220100_EVENTS.csv'
    $rows[0..1] | Export-Csv -LiteralPath $FirstFile -NoTypeInformation -Encoding UTF8
    $FirstSha=(Get-FileHash -LiteralPath $FirstFile -Algorithm SHA256).Hash
    $AutoJob=Start-Job -ScriptBlock {
        param($ScriptPath,$InputDir,$OutputDir,$Domain)
        & $ScriptPath -AutoSwitch -Follow -InputDirectory $InputDir `
            -AllowedHost $Domain -OutputDirectory $OutputDir `
            -PollMilliseconds 250 -MaxEvents 5
    } -ArgumentList $Tool,$WatchDir,$AutoOutput,$base
    try {
        $Ready=$false
        for($attempt=0;$attempt -lt 80;$attempt++){
            Start-Sleep -Milliseconds 250
            $FirstSummary=Get-ChildItem -LiteralPath $AutoOutput `
                -Filter '*SUMMARY.json' -File | Select-Object -First 1
            if($null -ne $FirstSummary){
                try {
                    $check=Get-Content -LiteralPath $FirstSummary.FullName -Raw | ConvertFrom-Json
                    if($check.Events -eq 2 -and $check.SourceFile -eq [IO.Path]::GetFileName($FirstFile)){
                        $Ready=$true
                        break
                    }
                }catch{ # May catch an in-progress JSON file write; retry until complete.
                }
            }
            if($AutoJob.State -in @('Failed','Stopped','Completed')){break}
        }
        Assert-Traffic $Ready 'AutoSwitch did not ingest first sensor file'
        $rows[2..4] | Export-Csv -LiteralPath $SecondFile -NoTypeInformation -Encoding UTF8
        $SecondSha=(Get-FileHash -LiteralPath $SecondFile -Algorithm SHA256).Hash
        $done=Wait-Job -Job $AutoJob -Timeout 20
        Assert-Traffic ($null -ne $done) 'AutoSwitch did not detect second sensor file'
        Receive-Job -Job $AutoJob -ErrorAction Stop | Out-Host
        Assert-Traffic ($AutoJob.State -eq 'Completed') 'AutoSwitch job failed'
        $AutoSummary=Get-Content -LiteralPath $FirstSummary.FullName -Raw | ConvertFrom-Json
        Assert-Traffic ($AutoSummary.Events -eq 5) 'AutoSwitch lost or duplicated events'
        Assert-Traffic ($AutoSummary.SourceGeneration -eq 2) 'AutoSwitch did not increment source generation'
        Assert-Traffic ($AutoSummary.SourceFile -eq [IO.Path]::GetFileName($SecondFile)) 'AutoSwitch current source incorrect'
        Assert-Traffic ($AutoSummary.LastAuthMarker -eq 'email-populated-marker') 'AutoSwitch did not process new auth marker'
        Assert-Traffic ($AutoSummary.SourceHistory.Count -eq 2) 'AutoSwitch did not retain filename history'
        $AutoEvents=Get-ChildItem -LiteralPath $AutoOutput -Filter '*EVENTS.jsonl' -File | Select-Object -First 1
        $Joined=@(Get-Content -LiteralPath $AutoEvents.FullName | ForEach-Object {$_ | ConvertFrom-Json})
        Assert-Traffic ($Joined.Count -eq 5) 'AutoSwitch JSONL event count mismatch'
        Assert-Traffic ($null -eq $Joined[2].GapMs) 'New source inherited inter-event time from old file'
        $AutoText=(Get-Content -LiteralPath $FirstSummary.FullName -Raw)+(Get-Content -LiteralPath $AutoEvents.FullName -Raw)
        foreach($secret in @('SECRET_COOKIE_VALUE','LEAKME','SESSIONVALUE_SHOULD_NEVER_APPEAR','PRIVATE_EMAIL_SHOULD_NEVER_APPEAR','SECRETUSER','SESS_ID','iggm_token')){
            Assert-Traffic (-not $AutoText.Contains($secret)) ('AutoSwitch unredacted field: '+$secret)
        }
        Assert-Traffic ((Get-FileHash -LiteralPath $FirstFile -Algorithm SHA256).Hash -eq $FirstSha) 'AutoSwitch modified first CSV'
        Assert-Traffic ((Get-FileHash -LiteralPath $SecondFile -Algorithm SHA256).Hash -eq $SecondSha) 'AutoSwitch modified second CSV'
        Write-Host 'AUTO SOURCE SWITCH    : PASS' -ForegroundColor Green
    }finally{
        if($null -ne $AutoJob){
            if($AutoJob.State -eq 'Running'){Stop-Job -Job $AutoJob -ErrorAction SilentlyContinue}
            Remove-Job -Job $AutoJob -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Host 'TRIAD TRAFFIC PARSER : PASS' -ForegroundColor Green
    Write-Host 'RELATIVE TIMING      : PASS' -ForegroundColor Green
    Write-Host 'AUTH/TTP SIGNALS     : PASS' -ForegroundColor Green
    Write-Host 'SECRET REDACTION     : PASS' -ForegroundColor Green
    Write-Host 'READ-ONLY INPUT      : PASS' -ForegroundColor Green
}finally{
    Remove-Item -LiteralPath $Temp -Recurse -Force -ErrorAction SilentlyContinue
}