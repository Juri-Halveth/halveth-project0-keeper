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
    Write-Host 'TRIAD TRAFFIC PARSER : PASS' -ForegroundColor Green
    Write-Host 'RELATIVE TIMING      : PASS' -ForegroundColor Green
    Write-Host 'AUTH/TTP SIGNALS     : PASS' -ForegroundColor Green
    Write-Host 'SECRET REDACTION     : PASS' -ForegroundColor Green
    Write-Host 'READ-ONLY INPUT      : PASS' -ForegroundColor Green
}finally{
    Remove-Item -LiteralPath $Temp -Recurse -Force -ErrorAction SilentlyContinue
}