<#
.SYNOPSIS
  Fix Apple Studio Display XDR (2026) detection on Windows with NVIDIA GPUs.

.DESCRIPTION
  Recent NVIDIA drivers fail to parse the Studio Display XDR's 768-byte EDID (DisplayID 2.x extension blocks).
  Windows then shows "Generic Non-PnP Monitor" at 640x480 with no modes. Setting the NVIDIA driver registry
  value DISABLE_NATIVE_DISPLAYID2X_SUPPORT=1 makes the driver fall back to its legacy EDID path, which parses
  the display correctly (verified: with the flag removed the display drops to Generic Monitor / 0-byte EDID
  immediately; restoring it brings back 5120x2880 and HDR).

  Actions:
    status   - show GPU keys, flag state, monitors and EDID size (no changes)
    apply    - back up the NVIDIA GPU class key(s), set the flag, optionally restart the GPU to apply now
    restore  - remove the flag (or re-import the backup) and optionally restart the GPU

.PARAMETER Action
  status | apply | restore
.PARAMETER RestartGpu
  Restart the NVIDIA GPU device via pnputil so the change applies without a reboot (screen blanks ~5 s).
.PARAMETER BackupDir
  Where to write .reg backups (default: alongside this script in .\backups).

.EXAMPLE
  .\Fix-StudioDisplayXDR.ps1 status
  .\Fix-StudioDisplayXDR.ps1 apply -RestartGpu
  .\Fix-StudioDisplayXDR.ps1 restore -RestartGpu

.NOTES
  Requires an elevated PowerShell for apply/restore. Windows 11, NVIDIA GPU, display connected over
  DisplayPort -> USB-C (bidirectional cable) or any DisplayPort path. MIT license.
#>
[CmdletBinding()]
param(
  [ValidateSet('status','apply','restore')] [string]$Action = 'status',
  [switch]$RestartGpu,
  [string]$BackupDir = ''
)
$ErrorActionPreference = 'Stop'
if (-not $BackupDir) { $root = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }; $BackupDir = Join-Path $root 'backups' }
$ClassRoot = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
$FlagName  = 'DISABLE_NATIVE_DISPLAYID2X_SUPPORT'

function Test-Admin { ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) }

function Get-NvidiaClassKeys {
  Get-ChildItem $ClassRoot -ErrorAction SilentlyContinue | ForEach-Object {
    $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
    if ($p.DriverDesc -match 'NVIDIA') {
      [PSCustomObject]@{ Key = $_.PSChildName; Path = $_.PSPath; Desc = $p.DriverDesc; Driver = $p.DriverVersion; Flag = $p.$FlagName; Instance = $p.MatchingDeviceId }
    }
  }
}

function Get-NvidiaGpuInstanceIds { Get-PnpDevice -Class Display -PresentOnly | Where-Object { $_.InstanceId -like 'PCI\VEN_10DE*' } | Select-Object -ExpandProperty InstanceId }

function Show-Monitors {
  Get-PnpDevice -PresentOnly -Class Monitor | ForEach-Object {
    $edid = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Enum\$($_.InstanceId)\Device Parameters" -ErrorAction SilentlyContinue).EDID
    $name = ''
    if ($edid -and $edid.Length -ge 128) {
      for ($d = 54; $d -le 108; $d += 18) { if ($edid[$d] -eq 0 -and $edid[$d+3] -eq 0xFC) { $name = (-join ($edid[($d+5)..($d+17)] | ForEach-Object { [char]$_ })).Trim() } }
    }
    [PSCustomObject]@{ Monitor = $_.FriendlyName; EdidBytes = $(if ($edid) { $edid.Length } else { 0 }); EdidName = $name; InstanceId = $_.InstanceId }
  }
}

function Restart-NvidiaGpu {
  if (-not (Test-Admin)) { throw 'GPU restart requires an elevated PowerShell.' }
  foreach ($id in Get-NvidiaGpuInstanceIds) { Write-Host "Restarting GPU $id (screen will blank briefly)..."; pnputil /restart-device "$id" | Out-Null }
  Start-Sleep -Seconds 12
}

$keys = @(Get-NvidiaClassKeys)
if (-not $keys) { Write-Warning 'No NVIDIA display adapter class key found. This fix targets NVIDIA GPUs only.'; }

switch ($Action) {
  'status' {
    Write-Host "NVIDIA GPU class keys:"; $keys | Format-Table Key, Desc, Driver, Flag -AutoSize
    Write-Host "Monitors:"; Show-Monitors | Format-Table -AutoSize
    $generic = Show-Monitors | Where-Object { $_.EdidBytes -eq 0 }
    if ($generic) { Write-Host "A monitor with no EDID is present. If it is a Studio Display XDR on an NVIDIA GPU, run: .\Fix-StudioDisplayXDR.ps1 apply -RestartGpu  (elevated)" -ForegroundColor Yellow }
  }
  'apply' {
    if (-not (Test-Admin)) { throw 'Run this from an elevated PowerShell (Run as administrator).' }
    New-Item -ItemType Directory -Force $BackupDir | Out-Null
    foreach ($k in $keys) {
      $regPath = "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\$($k.Key)"
      $bak = Join-Path $BackupDir ("nvidia-class-$($k.Key)-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.reg')
      reg export $regPath $bak /y | Out-Null
      Write-Host "Backed up $regPath -> $bak"
      if ($null -ne $k.Flag -and $k.Flag -ne 1) { Write-Warning "$FlagName already exists on $($k.Key) with value $($k.Flag); overwriting with 1." }
      New-ItemProperty -Path $k.Path -Name $FlagName -PropertyType DWord -Value 1 -Force | Out-Null
      Write-Host "Set $FlagName=1 on $($k.Key) ($($k.Desc), driver $($k.Driver))"
    }
    if ($RestartGpu) { Restart-NvidiaGpu; Write-Host "Monitors after restart:"; Show-Monitors | Format-Table -AutoSize }
    else { Write-Host "Restart Windows (or re-run with -RestartGpu) for the change to take effect." }
  }
  'restore' {
    if (-not (Test-Admin)) { throw 'Run this from an elevated PowerShell (Run as administrator).' }
    foreach ($k in $keys) {
      Remove-ItemProperty -Path $k.Path -Name $FlagName -ErrorAction SilentlyContinue
      Write-Host "Removed $FlagName from $($k.Key)"
    }
    if ($RestartGpu) { Restart-NvidiaGpu; Show-Monitors | Format-Table -AutoSize }
    else { Write-Host "Restart Windows (or re-run with -RestartGpu) for the change to take effect." }
  }
}
