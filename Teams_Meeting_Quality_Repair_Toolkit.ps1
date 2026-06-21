[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
param(
 [switch]$ClearTeamsCache,
 [switch]$RestartTeams,
 [switch]$RestartAudioServices,
 [switch]$FlushDns,
 [string]$RestartAdapter,
 [switch]$DryRun,[switch]$Yes,
 [string]$OutputPath=(Join-Path $env:LOCALAPPDATA 'TeamsMeetingRepair')
)
$ErrorActionPreference='Stop';$script:Failures=0;$script:Actions=0
$run=Join-Path $OutputPath (Get-Date -Format yyyyMMdd_HHmmss);New-Item -ItemType Directory $run -Force|Out-Null
$log=Join-Path $run 'repair.log';$before=Join-Path $run 'before.json';$after=Join-Path $run 'after.json'
function Log($m){"$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $m"|Tee-Object -FilePath $log -Append}
function Admin{$p=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent());$p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)}
function State{[pscustomobject]@{Collected=Get-Date;Teams=Get-Process ms-teams,Teams -ErrorAction SilentlyContinue|Select-Object Id,Name,StartTime,Path;Audio=Get-CimInstance Win32_SoundDevice -ErrorAction SilentlyContinue|Select-Object Name,Status,Manufacturer;Services=Get-Service Audiosrv,AudioEndpointBuilder -ErrorAction SilentlyContinue|Select-Object Name,Status,StartType;Adapters=Get-NetAdapter|Select-Object Name,Status,LinkSpeed;TeamsEndpoints=@('teams.microsoft.com','worldaz.tr.teams.microsoft.com')|ForEach-Object{[pscustomobject]@{Host=$_;Dns=[bool](Resolve-DnsName $_ -ErrorAction SilentlyContinue);Https=(Test-NetConnection $_ -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue)}}}}
function Act($d,[scriptblock]$a){$script:Actions++;Log $d;if($DryRun){Log "DRY-RUN: $d";return};try{&$a;Log "SUCCESS: $d"}catch{$script:Failures++;Log "FAILED: $d - $($_.Exception.Message)"}}
State|ConvertTo-Json -Depth 7|Set-Content $before -Encoding UTF8
if(-not($ClearTeamsCache -or $RestartTeams -or $RestartAudioServices -or $FlushDns -or $RestartAdapter)){Write-Error 'Choose at least one repair action.';exit 2}
if(($RestartAudioServices -or $RestartAdapter) -and -not $DryRun -and -not(Admin)){Write-Error 'Run from elevated PowerShell.';exit 4}
if(-not $Yes -and -not $DryRun){if((Read-Host 'Apply selected Teams meeting repairs? Teams may close. Type YES') -ne 'YES'){Log 'Cancelled.';exit 10}}
if($ClearTeamsCache -or $RestartTeams){Act 'Closing Microsoft Teams' {Get-Process ms-teams,Teams -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue}}
if($ClearTeamsCache){foreach($path in @("$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams","$env:APPDATA\Microsoft\Teams")){Act "Clearing Teams cache at $path" {if(Test-Path $path){Get-ChildItem $path -Force -ErrorAction SilentlyContinue|Remove-Item -Recurse -Force -ErrorAction SilentlyContinue}}}}
if($RestartAudioServices){Act 'Restarting Windows Audio services' {Restart-Service AudioEndpointBuilder -Force;Restart-Service Audiosrv -Force}}
if($FlushDns){Act 'Flushing DNS cache' {Clear-DnsClientCache}}
if($RestartAdapter){Get-NetAdapter -Name $RestartAdapter -ErrorAction Stop|Out-Null;Act "Restarting adapter $RestartAdapter" {Restart-NetAdapter -Name $RestartAdapter -Confirm:$false}}
if($RestartTeams){$newTeams=(Get-AppxPackage MSTeams -ErrorAction SilentlyContinue).InstallLocation;if($newTeams){Act 'Starting new Microsoft Teams' {Start-Process 'ms-teams:'}}else{$classic="$env:LOCALAPPDATA\Microsoft\Teams\current\Teams.exe";if(Test-Path $classic){Act 'Starting classic Microsoft Teams' {Start-Process $classic}}else{$script:Failures++;Log 'Teams executable was not found.'}}}
Start-Sleep 3;State|ConvertTo-Json -Depth 7|Set-Content $after -Encoding UTF8
if($script:Failures){Log "Completed with $script:Failures failure(s).";exit 20};Log "Repair completed. Actions: $script:Actions";exit 0
