# Studio Display XDR on Windows (NVIDIA) — detection fix and display tools

Apple's **Studio Display XDR (2026)** connected to a Windows PC over a DisplayPort → USB-C cable often shows up as
**"Generic Non-PnP Monitor" at 640x480** with no other resolutions. This repo contains the fix and a few small
PowerShell tools to get the display to its full resolution, 10-bit output, Auto Color Management and HDR.

No Thunderbolt port is needed on the PC. A bidirectional DisplayPort 1.4/2.1 → USB-C cable from the GPU's
DisplayPort output to the display's upstream Thunderbolt port is enough for video.

## The problem

The Studio Display XDR's EDID is 768 bytes (base block + 5 extension blocks, including DisplayID 2.x).
Recent NVIDIA drivers fail to parse it and report **no EDID at all** to Windows, which then creates a fallback
"Default_Monitor" with a single 640x480 mode. Windows' own Basic Display driver (used during Windows setup)
reads the same display fine, so the cable and GPU are not the issue.

## The fix

Set this DWORD on the NVIDIA display adapter's driver key and restart (or restart the GPU device):

```
HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\<000N>
  DISABLE_NATIVE_DISPLAYID2X_SUPPORT  REG_DWORD  1
```

`<000N>` is the subkey whose `DriverDesc` is your NVIDIA GPU. The value makes the driver use its legacy EDID path,
which parses this display correctly. The script does this for you with a registry backup.

**Verified cause and effect** (RTX 4080 SUPER, driver 610.88, Windows 11 25H2 build 26200): removing the value and
restarting the GPU immediately drops the display to "Generic Monitor" with a 0-byte EDID; restoring it brings back
"Generic Monitor (Studio XDR)" with the full 768-byte EDID, 5120x2880, 10-bit and HDR.

Credit: the registry value was first documented for an HDR problem on driver 616.92 by
[yangyinxu/studio-display-xdr-hdr-workaround](https://github.com/yangyinxu/studio-display-xdr-hdr-workaround).
This repo shows it also fixes the *detection* failure (no EDID / 640x480) and adds tooling around it.

## Quick start

Open PowerShell **as administrator** in this folder:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\Fix-StudioDisplayXDR.ps1 status              # see GPU keys, flag, monitors, EDID size
.\Fix-StudioDisplayXDR.ps1 apply -RestartGpu   # back up, set the flag, restart GPU (screen blanks ~5 s)
.\Set-DisplayMode.ps1                           # 5120x2880 at the highest refresh Windows offers
.\Display-Color.ps1 acm on                      # Auto Color Management (10-bit, correct sRGB on the P3 panel)
.\Display-Color.ps1 hdr on                      # Windows HDR (10-bit, up to 2000 nits)
.\Display-Color.ps1 dpi 1                       # scaling one step above recommended (225%); 0 = recommended
.\Display-Color.ps1 status
```

Undo: `.\Fix-StudioDisplayXDR.ps1 restore -RestartGpu` (or import the `.reg` backup from `backups\`).

## What you get, and what you don't

| Item | RTX 40-series (DisplayPort 1.4a) | Notes |
|---|---|---|
| 5120x2880 @ 60 Hz, 10-bit RGB | Yes | Confirmed on RTX 4080 SUPER |
| 3840x2160 @ 120 Hz | Yes | Offered by the driver |
| 5120x2880 @ 120 Hz | Not offered by the Windows driver | Reported working on RTX 50-series (DP 2.1) and on Linux |
| HDR (Windows "Use HDR") | Yes | Run the Windows HDR Calibration app afterwards |
| Auto Color Management (SDR) | Yes | Windows 11 24H2+ |
| Brightness / reference modes / camera / speakers / USB hub | No | Those need macOS or a Thunderbolt host |

The display stays in whatever reference mode was last selected from a Mac. Factory calibration is in the display.
For color-critical work verify with a colorimeter; no software setting can guarantee accuracy.

## Files

- `Fix-StudioDisplayXDR.ps1` — status / apply / restore of the registry fix, with backups and optional GPU restart.
- `Set-DisplayMode.ps1` — enumerates modes and selects 5120x2880 at the highest refresh available.
- `Display-Color.ps1` — status, ACM on/off, HDR on/off, DPI scale step via the Windows display-config API (no admin needed).
- `Verify-Display.ps1` — one-shot report: driver, monitors, EDID size, mode, refresh, advanced-color state.

## Requirements

- Windows 11 (24H2 or later for `Display-Color.ps1` ACM/HDR switching; the registry fix itself works on older builds).
- NVIDIA GPU. (Intel Arc has a similar EDID regression; see the Intel Community thread linked below. AMD untested.)
- DisplayPort → USB-C cable that is **bidirectional** (DP source to USB-C sink). Plain USB-C → DP adapters work the wrong way.

## Caveats

- The flag applies to the whole GPU and may change how other DisplayID 2.x monitors on that GPU are parsed. Check them.
- Clean driver installs (DDU, "clean install" in the NVIDIA installer) can remove the value or renumber the key. Re-run `apply`.
- Keep the `.reg` backup. If you ever get a black screen, remove the value from Safe Mode.

## References

- Apple: [Studio Display XDR tech specs and reference modes](https://support.apple.com/en-gb/126323)
- yangyinxu: [studio-display-xdr-hdr-workaround](https://github.com/yangyinxu/studio-display-xdr-hdr-workaround)
- Intel Community: [Studio Display XDR EDID regression on Arc 140V](https://community.intel.com/t5/Graphics/Apple-Studio-Display-XDR-2026-on-Intel-Arc-140V-Lunar-Lake-over/m-p/1759354)
- Tymscar: [Studio Display XDR on an RTX 4080 PC](https://blog.tymscar.com/posts/studiodisplayxdr/)
- Microsoft: [Auto Color Management](https://devblogs.microsoft.com/directx/auto-color-management)

## License

MIT
