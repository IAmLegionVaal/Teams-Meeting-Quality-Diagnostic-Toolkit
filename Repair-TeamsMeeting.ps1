[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$ClearTeamsCache,
    [switch]$ResetAudioService,
    [switch]$ResetNetwork,
    [switch]$Force,
    [string]$OutputPath="$env:USERPROFILE\Desktop\TeamsMeetingRepair"
)
$ErrorActionPreference='Stop'
New-Item -ItemType Directory -Path $OutputPath -Force|Out-Null
$Log=Join-Path $OutputPath ("repair-{0:yyyyMMdd-HHmmss}.log"-f(Get-Date))
function L($m){"$(Get-Date -Format s) $m"|Tee-Object -FilePath $Log -Append}
if(-not($ClearTeamsCache-or$ResetAudioService-or$ResetNetwork)){throw'Choose at least one repair action.'}
Get-NetAdapter|Select Name,Status,LinkSpeed|Export-Csv (Join-Path $OutputPath 'network-before.csv') -NoTypeInformation
if($ClearTeamsCache){
    $p=Get-Process ms-teams,Teams -ErrorAction SilentlyContinue
    if($p-and-not$Force){throw'Close Teams or use -Force.'}
    if($p){$p|Stop-Process -Force}
    foreach($x in @("$env:APPDATA\Microsoft\Teams","$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams")){
        if(Test-Path $x){if($PSCmdlet.ShouldProcess($x,'Clear Teams cache')){Get-ChildItem $x -Force -ErrorAction SilentlyContinue|Remove-Item -Recurse -Force -ErrorAction SilentlyContinue}}
    }
    L'Teams cache cleared.'
}
if($ResetAudioService-and$PSCmdlet.ShouldProcess('Windows Audio services','Restart')){Restart-Service AudioEndpointBuilder -Force;Restart-Service Audiosrv -Force;L'Audio services restarted.'}
if($ResetNetwork-and$PSCmdlet.ShouldProcess('Network stack','Flush DNS and reset Winsock')){Clear-DnsClientCache;netsh winsock reset|Tee-Object -FilePath $Log -Append;L'Network reset completed; reboot may be required.'}
Get-CimInstance Win32_SoundDevice|Select Name,Status|Export-Csv (Join-Path $OutputPath 'audio-after.csv') -NoTypeInformation
L'Repair workflow finished.'
