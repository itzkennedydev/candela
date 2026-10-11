<#
.SYNOPSIS
  Query and control Windows display color state (ACM / HDR / bit depth / DPI scale) for the primary display.
.USAGE
  .\display-color.ps1 status
  .\display-color.ps1 acm on|off      # Auto Color Management (SDR wide-gamut color management)
  .\display-color.ps1 hdr on|off      # Windows HDR
  .\display-color.ps1 dpi <rel>       # DPI scale step relative to Windows' recommended (0 = recommended, 1 = one step up)
  No elevation required. Uses DisplayConfigGet/SetDeviceInfo (Windows 11 24H2+ for acm/hdr).
#>
param([string]$Action = 'status', [string]$Value = '')
$src = @'
using System; using System.Runtime.InteropServices;
public static class DCX {
 [StructLayout(LayoutKind.Sequential)] public struct LUID { public uint L; public int H; }
 [StructLayout(LayoutKind.Sequential)] public struct SETV { public uint type; public uint size; public LUID a; public uint id; public uint value; }
 [StructLayout(LayoutKind.Sequential)] public struct ACI2 { public uint type; public uint size; public LUID a; public uint id; public uint flags; public uint colorEncoding; public uint bitsPerChannel; public uint activeColorMode; }
 [StructLayout(LayoutKind.Sequential)] public struct DPIGET { public uint type; public uint size; public LUID a; public uint id; public int minRel; public int curRel; public int maxRel; }
 [StructLayout(LayoutKind.Sequential)] public struct DPISET { public uint type; public uint size; public LUID a; public uint id; public int rel; }
 [DllImport("user32.dll")] public static extern int DisplayConfigSetDeviceInfo(ref SETV h);
 [DllImport("user32.dll")] public static extern int DisplayConfigSetDeviceInfo(ref DPISET h);
 [DllImport("user32.dll")] public static extern int DisplayConfigGetDeviceInfo(ref ACI2 h);
 [DllImport("user32.dll")] public static extern int DisplayConfigGetDeviceInfo(ref DPIGET h);
 [StructLayout(LayoutKind.Sequential)] public struct PATH_SRC { public LUID a; public uint id; public uint mode; public uint st; }
 [StructLayout(LayoutKind.Sequential)] public struct PATH_TGT { public LUID a; public uint id; public uint mode; public uint tech; public uint rot; public uint scal; public uint rrN; public uint rrD; public uint so; public uint avail; public uint st; }
 [StructLayout(LayoutKind.Sequential)] public struct PATH { public PATH_SRC s; public PATH_TGT t; public uint flags; }
 [StructLayout(LayoutKind.Sequential, Size=64)] public struct MODE { public uint type; public uint id; public LUID a; }
 [DllImport("user32.dll")] public static extern int GetDisplayConfigBufferSizes(uint f, out uint np, out uint nm);
 [DllImport("user32.dll")] public static extern int QueryDisplayConfig(uint f, ref uint np, [Out] PATH[] p, ref uint nm, [Out] MODE[] m, IntPtr cur);
}
'@
if (-not ('DCX' -as [type])) { Add-Type -TypeDefinition $src }
$np=0;$nm=0; [DCX]::GetDisplayConfigBufferSizes(2,[ref]$np,[ref]$nm) | Out-Null
$paths = New-Object DCX+PATH[] $np; $modes = New-Object DCX+MODE[] $nm
[DCX]::QueryDisplayConfig(2,[ref]$np,$paths,[ref]$nm,$modes,[IntPtr]::Zero) | Out-Null
$p = $paths[0]
function Get-Status {
  $g = New-Object DCX+ACI2; $g.type = 15; $g.size = [System.Runtime.InteropServices.Marshal]::SizeOf($g); $g.a = $p.t.a; $g.id = $p.t.id
  $rc = [DCX]::DisplayConfigGetDeviceInfo([ref]$g)
  $modeName = @('SDR','WCG (Auto Color Management)','HDR')[$g.activeColorMode]
  $encName = @('RGB','YCbCr 4:4:4','YCbCr 4:2:2','YCbCr 4:2:0','Intensity')[$g.colorEncoding]
  $d = New-Object DCX+DPIGET; $d.type = [uint32]4294967293; $d.size = [System.Runtime.InteropServices.Marshal]::SizeOf($d); $d.a = $p.s.a; $d.id = $p.s.id
  [DCX]::DisplayConfigGetDeviceInfo([ref]$d) | Out-Null
  [PSCustomObject]@{ Refresh = "$($p.t.rrN)/$($p.t.rrD) Hz"; HdrSupported = (($g.flags -band 1) -ne 0); AcmSupported = (($g.flags -band 2) -ne 0); ActiveMode = $modeName; BitsPerChannel = $g.bitsPerChannel; Encoding = $encName; DpiStepRelToRecommended = $d.curRel; DpiRange = "$($d.minRel)..$($d.maxRel)"; rc = $rc }
}
function Set-State([uint32]$type, [uint32]$v) { $s = New-Object DCX+SETV; $s.type = $type; $s.size = [System.Runtime.InteropServices.Marshal]::SizeOf($s); $s.a = $p.t.a; $s.id = $p.t.id; $s.value = $v; return [DCX]::DisplayConfigSetDeviceInfo([ref]$s) }
switch ($Action.ToLower()) {
  'status' { Get-Status | Format-List }
  'acm'    { $rc = Set-State 17 ([uint32]($Value -eq 'on')); "ACM $Value -> rc=$rc"; Start-Sleep 2; Get-Status | Format-List }
  'hdr'    { $rc = Set-State 16 ([uint32]($Value -eq 'on')); "HDR $Value -> rc=$rc"; Start-Sleep 4; Get-Status | Format-List }
  'dpi'    { $s = New-Object DCX+DPISET; $s.type = [uint32]4294967292; $s.size = [System.Runtime.InteropServices.Marshal]::SizeOf($s); $s.a = $p.s.a; $s.id = $p.s.id; $s.rel = [int]$Value; "DPI rel=$Value -> rc=$([DCX]::DisplayConfigSetDeviceInfo([ref]$s))"; Start-Sleep 2; Get-Status | Format-List }
  default  { "Unknown action. Use: status | acm on|off | hdr on|off | dpi <rel>" }
}
