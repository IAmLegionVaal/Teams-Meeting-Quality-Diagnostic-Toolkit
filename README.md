# Teams Meeting Quality Diagnostic Toolkit

A PowerShell toolkit for Teams meeting-quality diagnostics and selected guarded local repairs.

## Diagnostic script

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Teams_Meeting_Quality_Diagnostic_Toolkit.ps1
```

## Repair script

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Teams_Meeting_Quality_Repair_Toolkit.ps1 -ClearTeamsCache -DryRun
```

Examples:

```powershell
.\Teams_Meeting_Quality_Repair_Toolkit.ps1 -ClearTeamsCache -RestartTeams
.\Teams_Meeting_Quality_Repair_Toolkit.ps1 -RestartAudioServices
.\Teams_Meeting_Quality_Repair_Toolkit.ps1 -FlushDns
.\Teams_Meeting_Quality_Repair_Toolkit.ps1 -RestartAdapter Wi-Fi
```

## What the repair does

- Closes and restarts Microsoft Teams.
- Clears classic and new Teams cache locations.
- Restarts Windows Audio and Audio Endpoint Builder services.
- Flushes the DNS resolver cache.
- Restarts one explicitly selected network adapter.
- Captures Teams, audio-device, service, adapter and endpoint state before and after repair.
- Supports `-DryRun`, confirmation prompts, logs and clear exit codes.

## Privacy and safety

The tool does not collect meetings, chat, recordings or user files. Cache clearing can require sign-in again, and adapter or audio-service restart can briefly interrupt a meeting.

## Author

Dewald Pretorius — L2 IT Support Engineer
