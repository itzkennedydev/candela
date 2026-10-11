# Run after reboot: reports how Windows now sees the Studio Display XDR.
"NVIDIA driver: $((Get-CimInstance Win32_VideoController | Where-Object Name -match 'NVIDIA').DriverVersion)"
"--- Monitors ---"
Get-PnpDevice -PresentOnly -Class Monitor | ForEach-Object {
  $k = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($_.InstanceId)\Device Parameters"
  $edid = (Get-ItemProperty $k -ErrorAction SilentlyContinue).EDID
  "$($_.FriendlyName)  [$($_.InstanceId)]  EDID bytes: $(if ($edid) { $edid.Length } else { 0 })"
}
Add-Type -AssemblyName System.Windows.Forms
"--- Current mode ---"
[System.Windows.Forms.Screen]::AllScreens | ForEach-Object { "$($_.DeviceName) $($_.Bounds.Width)x$($_.Bounds.Height) primary=$($_.Primary)" }
$src = @'
using System; using System.Runtime.InteropServices;
public static class DC2 {
 [StructLayout(LayoutKind.Sequential)] public struct LUID { public uint L; public int H; }
 [StructLayout(LayoutKind.Sequential)] public struct PATH_SRC { public LUID a; public uint id; public uint mode; public uint st; }
 [StructLayout(LayoutKind.Sequential)] public struct PATH_TGT { public LUID a; public uint id; public uint mode; public uint tech; public uint rot; public uint scal; public uint rrN; public uint rrD; public uint so; public uint avail; public uint st; }
 [StructLayout(LayoutKind.Sequential)] public struct PATH { public PATH_SRC s; public PATH_TGT t; public uint flags; }
 [StructLayout(LayoutKind.Sequential, Size=64)] public struct MODE { public uint type; public uint id; public LUID a; }
 [DllImport("user32.dll")] public static extern int GetDisplayConfigBufferSizes(uint f, out uint np, out uint nm);
 [DllImport("user32.dll")] public static extern int QueryDisplayConfig(uint f, ref uint np, [Out] PATH[] p, ref uint nm, [Out] MODE[] m, IntPtr cur);
}
'@
Add-Type -TypeDefinition $src
$np=0;$nm=0; [DC2]::GetDisplayConfigBufferSizes(2,[ref]$np,[ref]$nm) | Out-Null
$paths = New-Object DC2+PATH[] $np; $modes = New-Object DC2+MODE[] $nm
[DC2]::QueryDisplayConfig(2,[ref]$np,$paths,[ref]$nm,$modes,[IntPtr]::Zero) | Out-Null
foreach ($p in $paths) { "Target $($p.t.id): refresh = $($p.t.rrN)/$($p.t.rrD) Hz, tech code $($p.t.tech) (10 = DisplayPort)" }
"--- Advanced color (HDR / ACM) keys for present displays ---"
Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\MonitorDataStore' -ErrorAction SilentlyContinue | ForEach-Object {
  $v = Get-ItemProperty $_.PSPath
  "$($_.PSChildName): AutoColorManagementEnabled=$($v.AutoColorManagementEnabled) AdvancedColorEnabled=$($v.AdvancedColorEnabled)"
}
"--- DISABLE_NATIVE_DISPLAYID2X_SUPPORT ---"
Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}' -ErrorAction SilentlyContinue | ForEach-Object { try { $v = Get-ItemProperty $_.PSPath -ErrorAction Stop; if ($v.DriverDesc -match 'NVIDIA') { "$($_.PSChildName) $($v.DriverDesc): $($v.DISABLE_NATIVE_DISPLAYID2X_SUPPORT)" } } catch {} }
