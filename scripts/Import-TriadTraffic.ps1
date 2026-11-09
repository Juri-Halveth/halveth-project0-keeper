<#
.SYNOPSIS
  Locally imports HALVETH V2 browser telemetry into TRIAD's private runtime.
.DESCRIPTION
  Reads an existing CSV; does not connect to a browser, server, or network.
  Produces a redacted event timeline and summary inside .triad-runtime/traffic.
  -Follow refreshes the snapshot periodically until Ctrl+C.
  -AutoSwitch -Follow watches newer LIVE_V2_YYYYMMDD_HHMMSS_EVENTS.csv files
  in a LOCAL directory and resets per-file timing on source changes.
  GapMs is the gap between logger events, NOT HTTP request latency.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [Parameter(Mandatory=$true)][ValidatePattern('^[A-Za-z0-9.-]+$')][string]$AllowedHost,
    [switch]$Follow,
    [ValidateRange(250,60000)][int]$PollMilliseconds=1000,
    [string]$OutputDirectory,
    [switch]$AutoSwitch,
    [string]$InputDirectory,
    [ValidateRange(0,10000000)][int]$MaxEvents=0
)
$ErrorActionPreference='Stop'
$Repo=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if([string]::IsNullOrWhiteSpace($OutputDirectory)){
    $OutputDirectory=Join-Path $Repo '.triad-runtime/traffic'
}
if($AutoSwitch){
    if(-not $Follow){throw '-AutoSwitch needs -Follow.'}
    if(-not [string]::IsNullOrWhiteSpace($CsvPath)){
        throw 'Choose either -AutoSwitch with -InputDirectory or a single -CsvPath.'
    }
    if([string]::IsNullOrWhiteSpace($InputDirectory)){
        $InputDirectory=Join-Path $HOME 'HALVETH_IGGM_LIVE'
    }
    if(-not (Test-Path -LiteralPath $InputDirectory -PathType Container)){
        throw "Local input directory not found: $InputDirectory"
    }
}else{
    if([string]::IsNullOrWhiteSpace($CsvPath) -or
       -not (Test-Path -LiteralPath $CsvPath -PathType Leaf)){
        throw "Input CSV not found: $CsvPath"
    }
}
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

# Generate a fresh isolated receipt for this invocation. Secrets are not copied.
$RunId=[DateTimeOffset]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')+'-'+[guid]::NewGuid().ToString('N').Substring(0,6)
$EventPath=Join-Path $OutputDirectory ("TRIAD_TRAFFIC_${RunId}_EVENTS.jsonl")
$SummaryPath=Join-Path $OutputDirectory ("TRIAD_TRAFFIC_${RunId}_SUMMARY.json")
$script:State=[ordered]@{
    Schema='HALVETH_TRIAD_TRAFFIC_R1'
    RunId=$RunId
    AllowedHost=$AllowedHost.ToLowerInvariant()
    SourceFile=$(if($AutoSwitch){'waiting'}else{[IO.Path]::GetFileName($CsvPath)})
    SourceGeneration=$(if($AutoSwitch){0}else{1})
    SourceHistory=@()
    AutoSwitch=[bool]$AutoSwitch
    RecordedAtUtc=[DateTimeOffset]::UtcNow.ToString('o')
    Events=0
    FirstEventUtc=$null
    LastEventUtc=$null
    LastAuthMarker='unknown'
    Counts=@{}
    TtpCounts=@{}
    TimingDefinition='GapMs = difference between consecutive logger timestamps; not request duration'
    RequestLatencyAvailable=$false
    Redaction='No original Cookie, Set-Cookie, Note, Origin, query string or response body stored'
}
$script:Seen=0
$script:CurrentCsvPath=$CsvPath
$script:FirstTime=$null
$script:LastTime=$null
$script:ClockInvalid=0
$script:Rewinds=0

function Convert-SafeRoute {
    param([string]$Route,[string]$ExpectedHost)
    if([string]::IsNullOrWhiteSpace($Route)){ return '[unknown]' }
    if($Route -notmatch '^[A-Za-z0-9.-]+/'){ return '[invalid-route]' }
    try { $u=[Uri]('https://'+$Route) } catch { return '[invalid-route]' }
    if($u.Scheme -ne 'https' -or $u.Host -ine $ExpectedHost -or $u.UserInfo){ return '[other-host]' }
    $parts=New-Object System.Collections.Generic.List[string]
    foreach($part in @($u.AbsolutePath.Split('/'))){
        if([string]::IsNullOrWhiteSpace($part)){continue}
        if($part -match '(?i)%[0-9a-f]{2}|@|[0-9]|[A-Za-z0-9]{25,}' -or
            $part -notmatch '^[A-Za-z_.-]{1,40}$' -or
            $part -notin @('login','index','user','ajax','static','web','js',
                            'home','google','thirdLogin','thirdLoginConnect','binding',
                            'forgotpwd','resetpwd','gettimezero','search_keyword',
                            'calculateRate','public.js','cmp.js','login.js')){
            $parts.Add('[segment]')
        }else{$parts.Add($part)}
    }
    return ($ExpectedHost.ToLowerInvariant()+'/'+($parts -join '/'))
}
function Get-TtpTags {
    param($Row)
    $tags=New-Object System.Collections.Generic.List[string]
    switch([string]$Row.Kind){
        'AUTH_CHANGE'    {$tags.Add('TTP-001')}
        'REDIRECT'       {$tags.Add('TTP-004')}
        'COOKIE_FLAGS'   {$tags.Add('TTP-005')}
        'REQUEST_COOKIES' {$tags.Add('TTP-006')}
        'DEBUG_SIGNAL'   {$tags.Add('TTP-008')}
        'CODE_SIGNAL'    {$tags.Add('TTP-011')}
        'WS_HANDSHAKE'   {$tags.Add('TTP-012')}
        'ERROR'          {$tags.Add('TTP-013')}
    }
    if([string]$Row.CORS -eq 'wildcard'){$tags.Add('TTP-009')}
    if([string]$Row.Kind -in @('DOCUMENT','XHR','FETCH') -and
        [string]$Row.Route -match '/(login|user)(/|$)'){$tags.Add('TTP-003')}
    return @($tags.ToArray() | Select-Object -Unique)
}
function Write-TrafficSummary {
    $script:State['ClockInvalid']=$script:ClockInvalid
    $script:State['TimestampRewinds']=$script:Rewinds
    $script:State['UpdatedAtUtc']=[DateTimeOffset]::UtcNow.ToString('o')
    $script:State | ConvertTo-Json -Depth 7 |
        Set-Content -LiteralPath $SummaryPath -Encoding UTF8
}
function Add-TrafficEvent {
    param($Row)
    $rawTime=[string]$Row.UTC
    $parsed=[DateTimeOffset]::MinValue
    $valid=[DateTimeOffset]::TryParse(
        $rawTime,[Globalization.CultureInfo]::InvariantCulture,
        [Globalization.DateTimeStyles]::AssumeUniversal,[ref]$parsed
    )
    if(-not $valid){$script:ClockInvalid++}
    $gapMs=$null
    $elapsedMs=$null
    $iso=$null
    if($valid){
        $iso=$parsed.ToUniversalTime().ToString('o')
        if($null -eq $script:FirstTime){$script:FirstTime=$parsed;$script:State.FirstEventUtc=$iso}
        if($null -ne $script:LastTime){
            $gap=($parsed-$script:LastTime).TotalMilliseconds
            $gapMs=[math]::Round($gap,3)
            if($gap -lt 0){$script:Rewinds++}
        }
        $elapsedMs=[math]::Round(($parsed-$script:FirstTime).TotalMilliseconds,3)
        $script:LastTime=$parsed
        $script:State.LastEventUtc=$iso
    }
    $kind=[string]$Row.Kind
    if($kind -notin @('AUTH_CHANGE','REDIRECT','COOKIE_FLAGS','REQUEST_COOKIES',
        'DEBUG_SIGNAL','CODE_SIGNAL','WS_HANDSHAKE','ERROR','DOCUMENT','XHR',
        'FETCH','BODY','SCRIPT')){$kind='OTHER'}
    $login=[string]$Row.LoginMarker
    if($login -notin @('anonymous-marker','email-populated-marker')){$login='unknown'}
    if($kind -eq 'AUTH_CHANGE' -and $login -ne 'unknown'){
        $script:State.LastAuthMarker=$login
    }
    $http='unknown'
    if([string]$Row.HTTP -match '^[1-5][0-9][0-9]$'){$http=[string]$Row.HTTP}
    $method='unknown'
    if([string]$Row.Method -in @('GET','POST','PUT','PATCH','DELETE','OPTIONS','HEAD')){
        $method=[string]$Row.Method
    }
    $cors='unknown'
    if([string]$Row.CORS -in @('wildcard','specific-origin','not-seen')){$cors=[string]$Row.CORS}
    $ttp=@(Get-TtpTags -Row $Row)
    foreach($tag in $ttp){
        if(-not $script:State.TtpCounts.Contains($tag)){$script:State.TtpCounts[$tag]=0}
        $script:State.TtpCounts[$tag]++
    }
    $script:State.Events++
    if(-not $script:State.Counts.Contains($kind)){$script:State.Counts[$kind]=0}
    $script:State.Counts[$kind]++
    $sourceSeq=$null
    if([string]$Row.Seq -match '^[0-9]{1,12}$'){$sourceSeq=[long]$Row.Seq}
    $safe=[ordered]@{
        Schema='HALVETH_TRAFFIC_EVENT_R1'
        EventIndex=$script:State.Events
        SourceSeq=$sourceSeq
        TimeUtc=$iso
        GapMs=$gapMs
        ElapsedMs=$elapsedMs
        RequestLatencyMs=$null
        Kind=$kind
        Route=(Convert-SafeRoute -Route ([string]$Row.Route) -ExpectedHost $AllowedHost)
        Method=$method
        HTTP=$http
        AuthMarker=$login
        CORS=$cors
        TTPs=$ttp
    }
    $safe | ConvertTo-Json -Compress -Depth 5 |
        Add-Content -LiteralPath $EventPath -Encoding UTF8
    if($kind -in @('AUTH_CHANGE','REDIRECT','ERROR','DEBUG_SIGNAL')){
        Write-Host ('{0,6} {1,-14} +{2,10}ms {3}' -f $safe.EventIndex,$kind,
            $(if($null -eq $gapMs){'n/a'}else{$gapMs}),$safe.Route)
    }
}

function Get-LatestLiveFile {
    # Filename includes UTC timestamp; sorting by name avoids an old file
    # becoming the newest source merely because it was appended later.
    $files=@(Get-ChildItem -LiteralPath $InputDirectory -Filter 'LIVE_V2_*_EVENTS.csv' -File |
        Where-Object { $_.Name -match '^LIVE_V2_[0-9]{8}_[0-9]{6}_EVENTS\.csv$' } |
        Sort-Object Name -Descending)
    if($files.Count -eq 0){return $null}
    return $files[0]
}

Write-Host ('TRIAD TRAFFIC | local/offline | '+$RunId) -ForegroundColor Cyan
if($AutoSwitch){
    Write-Host ('AutoSwitch watches local folder: '+$InputDirectory)
}else{
    Write-Host ('Input: '+[IO.Path]::GetFileName($CsvPath))
}
Write-Host ('Event log: '+$EventPath)
Write-Host 'No HTTP requests. No cookie values. Event gaps are NOT request latency.'
try {
    do {
        if($AutoSwitch){
            $fresh=Get-LatestLiveFile
            if($null -eq $fresh){
                Start-Sleep -Milliseconds $PollMilliseconds
                continue
            }
            if($script:CurrentCsvPath -ne $fresh.FullName){
                $script:CurrentCsvPath=$fresh.FullName
                $script:State.SourceFile=$fresh.Name
                $script:State.SourceGeneration=[int]$script:State.SourceGeneration+1
                $script:State.SourceHistory+=@($fresh.Name)
                $script:State.FirstEventUtc=$null
                $script:State.LastEventUtc=$null
                $script:State.LastAuthMarker='unknown'
                $script:Seen=0
                $script:FirstTime=$null
                $script:LastTime=$null
                Write-Host ('SOURCE_SWITCH -> '+$fresh.Name) -ForegroundColor Cyan
            }
        }
        try {
            $rows=@(Import-Csv -LiteralPath $script:CurrentCsvPath -ErrorAction Stop)
            $cols=@()
            if($rows.Count -gt 0){$cols=@($rows[0].PSObject.Properties.Name)}
            foreach($need in @('Seq','UTC','Kind','Route')){
                if($need -notin $cols){throw "CSV is missing required column: $need"}
            }
        } catch {
            if(-not $Follow){throw}
            Write-Warning 'Input snapshot was incomplete; retrying after next polling interval.'
            Start-Sleep -Milliseconds $PollMilliseconds
            continue
        }
        if($rows.Count -lt $script:Seen){
            throw 'CSV was truncated or rotated. Start a new TRIAD invocation for the new file.'
        }
        for($i=$script:Seen;$i -lt $rows.Count;$i++){
            Add-TrafficEvent -Row $rows[$i]
        }
        $script:Seen=$rows.Count
        Write-TrafficSummary
        if($MaxEvents -gt 0 -and $script:State.Events -ge $MaxEvents){break}
        if($Follow){Start-Sleep -Milliseconds $PollMilliseconds}
    } while($Follow)
} finally {
    Write-TrafficSummary
    Write-Host ('TRIAD: '+$script:State.Events+' sanitized events; summary: '+$SummaryPath) -ForegroundColor Green
}