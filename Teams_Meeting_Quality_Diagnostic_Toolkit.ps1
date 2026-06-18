#requires -Version 5.1
<#
.SYNOPSIS
    Teams Meeting Quality Diagnostic Toolkit.
.DESCRIPTION
    Read-only Teams meeting quality support context reporter.
#>
[CmdletBinding()]
param([string]$OutputPath)
$RunStamp=Get-Date -Format 'yyyyMMdd_HHmmss'
if([string]::IsNullOrWhiteSpace($OutputPath)){$OutputPath=Join-Path ([Environment]::GetFolderPath('Desktop')) 'Teams_Quality_Reports'}
New-Item -Path $OutputPath -ItemType Directory -Force|Out-Null
function New-Check{param($Area,$Name,$Status,$Value,$Recommendation)[PSCustomObject]@{Area=$Area;Name=$Name;Status=$Status;Value=$Value;Recommendation=$Recommendation}}
$checks=@()
foreach($p in 'Teams','ms-teams'){$proc=Get-Process $p -ErrorAction SilentlyContinue;$checks+=New-Check 'Process' $p 'Info' (@($proc).Count) 'Teams process context.'}
$devices=Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue|Where-Object{$_.Name -match 'Camera|Microphone|Audio|Headset|Webcam'}|Select-Object Name,Status,Manufacturer,PNPClass
$devices|Export-Csv (Join-Path $OutputPath "av_devices_$RunStamp.csv") -NoTypeInformation -Encoding UTF8
$nics=Get-NetAdapter -ErrorAction SilentlyContinue|Select-Object Name,Status,LinkSpeed,InterfaceDescription
$nics|Export-Csv (Join-Path $OutputPath "network_adapters_$RunStamp.csv") -NoTypeInformation -Encoding UTF8
foreach($hostName in 'teams.microsoft.com','worldaz.tr.teams.microsoft.com','login.microsoftonline.com'){
try{[void][System.Net.Dns]::GetHostAddresses($hostName);$dns='Resolved'}catch{$dns='DNS failed'}
try{$tcp=Test-NetConnection -ComputerName $hostName -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue}catch{$tcp=$false}
$checks+=New-Check 'Connectivity' $hostName ($(if($tcp){'OK'}else{'Warning'})) "DNS=$dns; TCP443=$tcp" 'Review DNS, proxy, firewall, or internet path.'}
$checks+=New-Check 'Devices' 'Audio/video device count' 'Info' (@($devices).Count) 'Review exported device inventory.'
$checks|Export-Csv (Join-Path $OutputPath "teams_quality_checks_$RunStamp.csv") -NoTypeInformation -Encoding UTF8
$checks|ConvertTo-Json -Depth 5|Set-Content (Join-Path $OutputPath "teams_quality_checks_$RunStamp.json") -Encoding UTF8
$html="<h1>Teams Meeting Quality Diagnostic</h1><p>Generated $(Get-Date)</p><h2>Checks</h2>$($checks|ConvertTo-Html -Fragment)<h2>Devices</h2>$($devices|ConvertTo-Html -Fragment)"
$html|ConvertTo-Html -Title 'Teams Meeting Quality Diagnostic'|Set-Content (Join-Path $OutputPath "teams_quality_$RunStamp.html") -Encoding UTF8
$checks|Format-Table -AutoSize -Wrap
Write-Host "Reports saved to: $OutputPath" -ForegroundColor Green
Start-Process explorer.exe -ArgumentList "`"$OutputPath`"" -ErrorAction SilentlyContinue
