# Sets the primary display to 5120x2880 at the highest refresh Windows offers.
# -ListOnly prints the offered modes and current mode without changing anything.
param([switch]$ListOnly)
$src = @'
using System; using System.Runtime.InteropServices;
public static class DM {
 [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
 public struct DEVMODE {
  [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string dmDeviceName;
  public ushort dmSpecVersion; public ushort dmDriverVersion; public ushort dmSize; public ushort dmDriverExtra; public uint dmFields;
  public int dmPositionX; public int dmPositionY; public uint dmDisplayOrientation; public uint dmDisplayFixedOutput;
  public short dmColor; public short dmDuplex; public short dmYResolution; public short dmTTOption; public short dmCollate;
  [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string dmFormName;
  public ushort dmLogPixels; public uint dmBitsPerPel; public uint dmPelsWidth; public uint dmPelsHeight;
  public uint dmDisplayFlags; public uint dmDisplayFrequency; public uint dmICMMethod; public uint dmICMIntent;
  public uint dmMediaType; public uint dmDitherType; public uint dmReserved1; public uint dmReserved2;
  public uint dmPanningWidth; public uint dmPanningHeight; }
 [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern bool EnumDisplaySettingsW(string dev, int mode, ref DEVMODE dm);
 [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int ChangeDisplaySettingsExW(string dev, ref DEVMODE dm, IntPtr h, uint flags, IntPtr p);
}
'@
if (-not ('DM' -as [type])) { Add-Type -TypeDefinition $src }
Add-Type -AssemblyName System.Windows.Forms
$dev = [System.Windows.Forms.Screen]::PrimaryScreen.DeviceName
$m = New-Object DM+DEVMODE; $m.dmSize = [System.Runtime.InteropServices.Marshal]::SizeOf($m)
[DM]::EnumDisplaySettingsW($dev, -1, [ref]$m) | Out-Null   # ENUM_CURRENT_SETTINGS
"Current: $($m.dmPelsWidth)x$($m.dmPelsHeight) @ $($m.dmDisplayFrequency) Hz"
$best = $null; $i = 0; $modes = @{}
while ([DM]::EnumDisplaySettingsW($dev, $i, [ref]$m)) {
  $k = "$($m.dmPelsWidth)x$($m.dmPelsHeight)"; if (-not $modes[$k] -or $modes[$k] -lt $m.dmDisplayFrequency) { $modes[$k] = $m.dmDisplayFrequency }
  if ($m.dmPelsWidth -eq 5120 -and $m.dmPelsHeight -eq 2880 -and $m.dmBitsPerPel -eq 32 -and ($null -eq $best -or $m.dmDisplayFrequency -gt $best.dmDisplayFrequency)) { $best = $m }
  $i++
}
"Modes offered (max Hz): " + (($modes.GetEnumerator() | Sort-Object { [int]($_.Key -split 'x')[0] } -Descending | Select-Object -First 6 | ForEach-Object { "$($_.Key)@$($_.Value)" }) -join ', ')
if ($ListOnly) { exit 0 }
if ($null -eq $best) { "5120x2880 is not offered. The display is not detected correctly (apply the fix first)."; exit 1 }
$best.dmFields = 0x180000 -bor 0x400000   # PELSWIDTH | PELSHEIGHT | DISPLAYFREQUENCY
$r = [DM]::ChangeDisplaySettingsExW($dev, [ref]$best, [IntPtr]::Zero, 1, [IntPtr]::Zero)  # CDS_UPDATEREGISTRY
"ChangeDisplaySettings result: $r (0 = OK) -> 5120x2880 @ $($best.dmDisplayFrequency) Hz"
