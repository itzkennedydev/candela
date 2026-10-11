# Candela - Studio Display XDR on Windows. Launch via Candela.cmd (asks for admin once).
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Candela" Width="640" Height="760" MinWidth="560" MinHeight="640" ResizeMode="CanResize"
        WindowStartupLocation="CenterScreen" Background="#1C1C1E" FontFamily="Segoe UI Variable Text, Segoe UI" FontSize="13" Foreground="#F5F5F7"
        UseLayoutRounding="True" SnapsToDevicePixels="True" TextOptions.TextFormattingMode="Ideal" TextOptions.TextRenderingMode="ClearType">
  <Window.Resources>
    <SolidColorBrush x:Key="Panel" Color="#2C2C2E"/>
    <SolidColorBrush x:Key="Separator" Color="#3A3A3C"/>
    <SolidColorBrush x:Key="Secondary" Color="#98989D"/>
    <SolidColorBrush x:Key="Accent" Color="#0A84FF"/>
    <SolidColorBrush x:Key="Green" Color="#30D158"/>
    <SolidColorBrush x:Key="Red" Color="#FF453A"/>
    <SolidColorBrush x:Key="Orange" Color="#FF9F0A"/>

    <Style x:Key="SectionTitle" TargetType="TextBlock">
      <Setter Property="Foreground" Value="{StaticResource Secondary}"/><Setter Property="FontSize" Value="12"/>
      <Setter Property="FontWeight" Value="SemiBold"/><Setter Property="Margin" Value="14,22,0,6"/>
    </Style>
    <Style x:Key="Group" TargetType="Border">
      <Setter Property="Background" Value="{StaticResource Panel}"/><Setter Property="CornerRadius" Value="10"/>
      <Setter Property="BorderBrush" Value="#3A3A3C"/><Setter Property="BorderThickness" Value="1"/>
    </Style>
    <Style x:Key="RowLabel" TargetType="TextBlock">
      <Setter Property="VerticalAlignment" Value="Center"/><Setter Property="FontSize" Value="13"/>
    </Style>
    <Style x:Key="RowValue" TargetType="TextBlock">
      <Setter Property="VerticalAlignment" Value="Center"/><Setter Property="Foreground" Value="{StaticResource Secondary}"/>
      <Setter Property="FontSize" Value="13"/><Setter Property="TextAlignment" Value="Right"/>
    </Style>
    <Style x:Key="RowSep" TargetType="Rectangle">
      <Setter Property="Height" Value="1"/><Setter Property="Fill" Value="{StaticResource Separator}"/><Setter Property="Margin" Value="14,0,0,0"/>
    </Style>

    <!-- Buttons -->
    <Style TargetType="Button">
      <Setter Property="Background" Value="#48484A"/><Setter Property="Foreground" Value="#F5F5F7"/>
      <Setter Property="Padding" Value="12,5"/><Setter Property="FontSize" Value="13"/><Setter Property="Cursor" Value="Hand"/>
      <Setter Property="VerticalAlignment" Value="Center"/><Setter Property="MinWidth" Value="72"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="b" Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Opacity" Value="0.85"/></Trigger>
              <Trigger Property="IsPressed" Value="True"><Setter TargetName="b" Property="Opacity" Value="0.7"/></Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.4"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="Primary" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
      <Setter Property="Background" Value="{StaticResource Accent}"/><Setter Property="FontWeight" Value="SemiBold"/>
    </Style>
    <Style x:Key="Link" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
      <Setter Property="Background" Value="Transparent"/><Setter Property="Foreground" Value="{StaticResource Accent}"/><Setter Property="Padding" Value="4,2"/><Setter Property="MinWidth" Value="0"/>
    </Style>

    <!-- Toggle switch -->
    <Style TargetType="ToggleButton">
      <Setter Property="Width" Value="40"/><Setter Property="Height" Value="24"/><Setter Property="Cursor" Value="Hand"/><Setter Property="VerticalAlignment" Value="Center"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ToggleButton">
            <Grid>
              <Border x:Name="track" CornerRadius="12" Background="#636366"/>
              <Ellipse x:Name="thumb" Width="20" Height="20" Fill="White" HorizontalAlignment="Left" Margin="2,0,0,0">
                <Ellipse.Effect><DropShadowEffect BlurRadius="4" ShadowDepth="1" Opacity="0.3"/></Ellipse.Effect>
              </Ellipse>
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="track" Property="Background" Value="{StaticResource Green}"/>
                <Setter TargetName="thumb" Property="HorizontalAlignment" Value="Right"/>
                <Setter TargetName="thumb" Property="Margin" Value="0,0,2,0"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.4"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Segmented control pieces -->
    <Style x:Key="Seg" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
      <Setter Property="Background" Value="Transparent"/><Setter Property="MinWidth" Value="64"/><Setter Property="Padding" Value="10,3"/><Setter Property="FontSize" Value="12"/>
    </Style>
  </Window.Resources>

  <Grid>
    <ScrollViewer VerticalScrollBarVisibility="Auto">
      <StackPanel Margin="28,26,28,20">

        <!-- Header: display glyph + name + status -->
        <Grid Margin="0,0,0,6">
          <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
          <Grid Width="96" Height="78" Margin="0,0,18,0" VerticalAlignment="Top">
            <Border Width="96" Height="60" VerticalAlignment="Top" CornerRadius="6" BorderThickness="2" BorderBrush="#8E8E93" Background="#0B0B0C">
              <Border Margin="3" CornerRadius="3">
                <Border.Background>
                  <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                    <GradientStop Color="#FF5E8BFF" Offset="0"/><GradientStop Color="#FF9A4DFF" Offset="0.5"/><GradientStop Color="#FFFF6A3D" Offset="1"/>
                  </LinearGradientBrush>
                </Border.Background>
              </Border>
            </Border>
            <Rectangle Width="26" Height="12" Fill="#8E8E93" VerticalAlignment="Top" Margin="0,60,0,0" RadiusX="1" RadiusY="1"/>
            <Rectangle Width="44" Height="4" Fill="#8E8E93" VerticalAlignment="Top" Margin="0,72,0,0" RadiusX="2" RadiusY="2"/>
          </Grid>
          <StackPanel Grid.Column="1" VerticalAlignment="Center">
            <TextBlock x:Name="hTitle" Text="Studio Display XDR" FontSize="24" FontWeight="SemiBold" FontFamily="Segoe UI Variable Display, Segoe UI"/>
            <StackPanel Orientation="Horizontal" Margin="0,6,0,0">
              <Ellipse x:Name="hDot" Width="8" Height="8" Fill="{StaticResource Green}" VerticalAlignment="Center" Margin="0,1,7,0"/>
              <TextBlock x:Name="hStatus" Text="Checking…" Foreground="{StaticResource Secondary}" FontSize="13"/>
            </StackPanel>
            <TextBlock x:Name="hSub" Text="" Foreground="{StaticResource Secondary}" FontSize="12" Margin="0,3,0,0" TextWrapping="Wrap"/>
          </StackPanel>
        </Grid>

        <!-- Detection -->
        <TextBlock Style="{StaticResource SectionTitle}" Text="DETECTION"/>
        <Border Style="{StaticResource Group}">
          <StackPanel>
            <Grid Margin="14,11,12,11">
              <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
              <StackPanel>
                <TextBlock x:Name="dTitle" Style="{StaticResource RowLabel}" Text="Display identification"/>
                <TextBlock x:Name="dSub" Foreground="{StaticResource Secondary}" FontSize="12" Margin="0,2,0,0" TextWrapping="Wrap" Text=""/>
              </StackPanel>
              <Button x:Name="bApply" Grid.Column="1" Style="{StaticResource Primary}" Content="Fix" Margin="16,0,0,0"/>
            </Grid>
            <Rectangle Style="{StaticResource RowSep}"/>
            <Grid Margin="14,10,12,10">
              <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
              <TextBlock Style="{StaticResource RowLabel}" Text="Graphics"/>
              <TextBlock x:Name="dGpu" Grid.Column="1" Style="{StaticResource RowValue}" Text="—"/>
            </Grid>
          </StackPanel>
        </Border>

        <!-- Display -->
        <TextBlock Style="{StaticResource SectionTitle}" Text="DISPLAY"/>
        <Border Style="{StaticResource Group}">
          <StackPanel>
            <Grid Margin="14,10,12,10">
              <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
              <TextBlock Style="{StaticResource RowLabel}" Text="Resolution"/>
              <TextBlock x:Name="vRes" Grid.Column="1" Style="{StaticResource RowValue}" Text="—" Margin="0,0,12,0"/>
              <Button x:Name="bMode" Grid.Column="2" Content="Use best"/>
            </Grid>
            <Rectangle Style="{StaticResource RowSep}"/>
            <Grid Margin="14,10,12,10">
              <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
              <TextBlock Style="{StaticResource RowLabel}" Text="Refresh rate"/>
              <TextBlock x:Name="vHz" Grid.Column="1" Style="{StaticResource RowValue}" Text="—"/>
            </Grid>
            <Rectangle Style="{StaticResource RowSep}"/>
            <Grid Margin="14,10,12,10">
              <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
              <TextBlock Style="{StaticResource RowLabel}" Text="Color depth"/>
              <TextBlock x:Name="vBits" Grid.Column="1" Style="{StaticResource RowValue}" Text="—"/>
            </Grid>
            <Rectangle Style="{StaticResource RowSep}"/>
            <Grid Margin="14,10,12,10">
              <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
              <StackPanel>
                <TextBlock Style="{StaticResource RowLabel}" Text="Text size"/>
                <TextBlock x:Name="vDpi" Foreground="{StaticResource Secondary}" FontSize="12" Margin="0,2,0,0" Text=""/>
              </StackPanel>
              <Border Grid.Column="1" Background="#3A3A3C" CornerRadius="7" Padding="2" VerticalAlignment="Center">
                <StackPanel Orientation="Horizontal">
                  <Button x:Name="bDpiDown" Style="{StaticResource Seg}" Content="Smaller"/>
                  <Button x:Name="bDpiDefault" Style="{StaticResource Seg}" Content="Default"/>
                  <Button x:Name="bDpiUp" Style="{StaticResource Seg}" Content="Larger"/>
                </StackPanel>
              </Border>
            </Grid>
          </StackPanel>
        </Border>

        <!-- Color -->
        <TextBlock Style="{StaticResource SectionTitle}" Text="COLOR"/>
        <Border Style="{StaticResource Group}">
          <StackPanel>
            <Grid Margin="14,10,12,10">
              <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
              <StackPanel>
                <TextBlock Style="{StaticResource RowLabel}" Text="High Dynamic Range"/>
                <TextBlock x:Name="cHdrSub" Foreground="{StaticResource Secondary}" FontSize="12" Margin="0,2,0,0" Text="Up to 2000 nits for HDR video and games." TextWrapping="Wrap"/>
              </StackPanel>
              <ToggleButton x:Name="tHdr" Grid.Column="1" Margin="16,0,0,0"/>
            </Grid>
            <Rectangle Style="{StaticResource RowSep}"/>
            <Grid Margin="14,10,12,10">
              <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
              <StackPanel>
                <TextBlock Style="{StaticResource RowLabel}" Text="Automatic color management"/>
                <TextBlock x:Name="cAcmSub" Foreground="{StaticResource Secondary}" FontSize="12" Margin="0,2,0,0" Text="Accurate sRGB on the P3 panel for apps that are not color managed." TextWrapping="Wrap"/>
              </StackPanel>
              <ToggleButton x:Name="tAcm" Grid.Column="1" Margin="16,0,0,0"/>
            </Grid>
          </StackPanel>
        </Border>

        <!-- Footer -->
        <Grid Margin="4,22,0,0">
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
          <TextBlock x:Name="fNote" Foreground="#6E6E73" FontSize="11" VerticalAlignment="Center" TextWrapping="Wrap" Text=""/>
          <Button x:Name="bRestore" Grid.Column="1" Style="{StaticResource Link}" Content="Restore original…"/>
          <Button x:Name="bDetails" Grid.Column="2" Style="{StaticResource Link}" Content="Details"/>
        </Grid>
        <Border x:Name="LogPanel" Style="{StaticResource Group}" Margin="0,10,0,0" Visibility="Collapsed">
          <TextBox x:Name="Log" Background="Transparent" Foreground="#C7C7CC" BorderThickness="0" FontFamily="Cascadia Mono, Consolas" FontSize="11" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" Height="160" Padding="12,8"/>
        </Border>
      </StackPanel>
    </ScrollViewer>
  </Grid>
</Window>
"@
$reader = New-Object System.Xml.XmlNodeReader $xaml
$win = [Windows.Markup.XamlReader]::Load($reader)
$iconPath = Join-Path $Root 'assets\icon.ico'
if (Test-Path $iconPath) { $win.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create((New-Object System.Uri $iconPath)) }
$ui = @{}; foreach ($n in 'hTitle','hDot','hStatus','hSub','dTitle','dSub','bApply','dGpu','vRes','bMode','vHz','vBits','vDpi','bDpiDown','bDpiDefault','bDpiUp','cHdrSub','tHdr','cAcmSub','tAcm','fNote','bRestore','bDetails','LogPanel','Log') { $ui[$n] = $win.FindName($n) }

function Run-Script([string]$script, [string[]]$scriptArgs) { & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Root $script) @scriptArgs 2>&1 | Out-String }
function LogLine([string]$t) { $ui.Log.AppendText(("[{0}] {1}`r`n" -f (Get-Date -Format 'HH:mm:ss'), $t.TrimEnd())); $ui.Log.ScrollToEnd() }
$script:state = @{}; $script:busy = $false

function Refresh-Status {
  $script:busy = $true
  $win.Cursor = [System.Windows.Input.Cursors]::Wait
  try {
    $mon = Get-PnpDevice -PresentOnly -Class Monitor | Select-Object -First 1
    $edid = $null; if ($mon) { $edid = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Enum\$($mon.InstanceId)\Device Parameters" -ErrorAction SilentlyContinue).EDID }
    $edidLen = if ($edid) { $edid.Length } else { 0 }
    $detected = $edidLen -gt 0
    $name = if ($mon) { ($mon.FriendlyName -replace 'Generic Monitor \((.+)\)', '$1') } else { 'No display' }
    if ($name -match 'Studio XDR') { $name = 'Studio Display XDR' }
    $ui.hTitle.Text = $name

    $gpuKey = Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}' -ErrorAction SilentlyContinue | ForEach-Object { try { $v = Get-ItemProperty $_.PSPath -ErrorAction Stop; if ($v.DriverDesc -match 'NVIDIA') { $v } } catch {} } | Select-Object -First 1
    $flag = if ($gpuKey) { $gpuKey.DISABLE_NATIVE_DISPLAYID2X_SUPPORT } else { $null }
    $drv = if ($gpuKey -and $gpuKey.DriverVersion -match '^\d+\.\d+\.(\d+)\.(\d+)$') { $a = $matches[1]; $b = $matches[2]; "$($a.Substring($a.Length-1))$($b.Substring(0,2)).$($b.Substring(2))" } else { '' }
    $ui.dGpu.Text = if ($gpuKey) { "$($gpuKey.DriverDesc -replace 'NVIDIA GeForce ','GeForce ')  ·  driver $drv" } else { 'No NVIDIA graphics found' }

    $st = Run-Script 'Display-Color.ps1' @('status')
    $kv = @{}; foreach ($line in ($st -split "`r?`n")) { if ($line -match '^\s*(\w+)\s*:\s*(.*)$') { $kv[$matches[1]] = $matches[2].Trim() } }
    $script:state = $kv
    $modes = Run-Script 'Set-DisplayMode.ps1' @('-ListOnly')
    $cur = if ($modes -match 'Current:\s*(\d+)x(\d+) @ (\d+) Hz') { @{ w = $matches[1]; h = $matches[2]; hz = $matches[3] } } else { $null }
    $max5k = if ($modes -match '5120x2880@(\d+)') { [int]$matches[1] } else { 0 }

    # Header status
    if ($detected) {
      $parts = @()
      if ($cur) { $parts += "$($cur.w) × $($cur.h)"; $parts += "$($cur.hz) Hz" }
      if ($kv.BitsPerChannel) { $parts += "$($kv.BitsPerChannel)-bit" }
      if ($kv.ActiveMode -eq 'HDR') { $parts += 'HDR' }
      $ui.hStatus.Text = 'Connected  ·  ' + ($parts -join '  ·  ')
      $ui.hDot.Fill = $win.FindResource('Green')
      $ui.hSub.Text = if ($cur -and [int]$cur.w -lt 5120 -and $max5k -gt 0) { 'The display can run at 5120 × 2880. Choose Use best.' } else { 'Connected over DisplayPort. Running at native resolution.' }
    } else {
      $ui.hStatus.Text = 'Not identified  ·  640 × 480 fallback'
      $ui.hDot.Fill = $win.FindResource('Red')
      $ui.hSub.Text = 'The graphics driver could not read the display identity. Apply the fix below.'
    }
    # Detection row
    if ($detected) { $ui.dTitle.Text = 'Display identified'; $ui.dSub.Text = "EDID read correctly ($edidLen bytes)." + $(if ($flag -eq 1) { ' Fix is applied.' } else { ' Fix not needed on this driver.' }); $ui.bApply.Content = if ($flag -eq 1) { 'Applied' } else { 'Apply fix' }; $ui.bApply.IsEnabled = ($flag -ne 1) -and $IsAdmin }
    else { $ui.dTitle.Text = 'Display not identified'; $ui.dSub.Text = 'NVIDIA driver returned no EDID. The fix switches the driver to its compatible EDID path (backed up, reversible).'; $ui.bApply.Content = 'Fix'; $ui.bApply.IsEnabled = $IsAdmin }
    # Display rows
    $ui.vRes.Text = if ($cur) { "$($cur.w) × $($cur.h)" } else { '—' }
    $ui.bMode.IsEnabled = ($max5k -gt 0) -and -not ($cur -and [int]$cur.w -eq 5120 -and [int]$cur.hz -eq $max5k)
    $ui.bMode.Content = if ($max5k -gt 0) { "Use best (5K $max5k Hz)" } else { 'Use best' }
    $ui.vHz.Text = if ($cur) { "$($cur.hz) Hz" + $(if ($max5k -gt 0 -and [int]$cur.hz -lt $max5k) { "  (up to $max5k Hz)" }) } else { '—' }
    $ui.vBits.Text = if ($kv.BitsPerChannel) { "$($kv.BitsPerChannel)-bit $($kv.Encoding)" } else { '—' }
    $rel = [int]$kv.DpiStepRelToRecommended
    $ui.vDpi.Text = if ($rel -eq 0) { 'Default (recommended for 5K)' } elseif ($rel -gt 0) { "$rel step$(if($rel -ne 1){'s'}) larger than default" } else { "$(-$rel) step$(if($rel -ne -1){'s'}) smaller than default" }
    # Color toggles
    $ui.tHdr.IsChecked = ($kv.ActiveMode -eq 'HDR'); $ui.tHdr.IsEnabled = ($kv.HdrSupported -eq 'True')
    $ui.cHdrSub.Text = if ($kv.HdrSupported -eq 'True') { 'Up to 2000 nits for HDR video and games. 10-bit output.' } else { 'This display or driver does not report HDR support.' }
    $acmOn = ($kv.ActiveMode -match 'WCG')
    $ui.tAcm.IsChecked = $acmOn; $ui.tAcm.IsEnabled = ($kv.AcmSupported -eq 'True') -and ($kv.ActiveMode -ne 'HDR')
    $ui.cAcmSub.Text = if ($kv.ActiveMode -eq 'HDR') { 'Managed by HDR mode. Turn HDR off to use this for SDR work.' } elseif ($kv.AcmSupported -eq 'True') { 'Accurate sRGB on the P3 panel for apps that are not color managed.' } else { 'Requires Windows 11 24H2 or later.' }
    $ui.fNote.Text = if ($IsAdmin) { 'Changes are reversible. The fix backs up the registry key before touching it.' } else { 'Open with Candela.cmd to allow the fix (administrator).' }
    $ui.bRestore.IsEnabled = $IsAdmin -and ($flag -eq 1)
  } catch { LogLine "Status error: $($_.Exception.Message)" }
  $win.Cursor = $null
  $script:busy = $false
}

$ui.bApply.Add_Click({ LogLine 'Applying fix: backup, registry value, GPU restart (screen blanks briefly)…'; $o = Run-Script 'Fix-StudioDisplayXDR.ps1' @('apply','-RestartGpu'); LogLine $o; Refresh-Status })
$ui.bRestore.Add_Click({ LogLine 'Restoring original state and restarting GPU…'; $o = Run-Script 'Fix-StudioDisplayXDR.ps1' @('restore','-RestartGpu'); LogLine $o; Refresh-Status })
$ui.bMode.Add_Click({ $o = Run-Script 'Set-DisplayMode.ps1' @(); LogLine $o; Refresh-Status })
$ui.tHdr.Add_Click({ if ($script:busy) { return }; $v = if ($ui.tHdr.IsChecked) { 'on' } else { 'off' }; Run-Script 'Display-Color.ps1' @('hdr', $v) | Out-Null; LogLine "HDR $v"; Refresh-Status })
$ui.tAcm.Add_Click({ if ($script:busy) { return }; $v = if ($ui.tAcm.IsChecked) { 'on' } else { 'off' }; Run-Script 'Display-Color.ps1' @('acm', $v) | Out-Null; LogLine "Automatic color management $v"; Refresh-Status })
$ui.bDpiUp.Add_Click({ $n = [int]$script:state.DpiStepRelToRecommended + 1; Run-Script 'Display-Color.ps1' @('dpi', "$n") | Out-Null; LogLine "Text size step $n"; Refresh-Status })
$ui.bDpiDown.Add_Click({ $n = [int]$script:state.DpiStepRelToRecommended - 1; Run-Script 'Display-Color.ps1' @('dpi', "$n") | Out-Null; LogLine "Text size step $n"; Refresh-Status })
$ui.bDpiDefault.Add_Click({ Run-Script 'Display-Color.ps1' @('dpi', '0') | Out-Null; LogLine 'Text size default'; Refresh-Status })
$ui.bDetails.Add_Click({ $ui.LogPanel.Visibility = if ($ui.LogPanel.Visibility -eq 'Visible') { 'Collapsed' } else { 'Visible' } })

LogLine "Ready. $(if ($IsAdmin) { 'Administrator.' } else { 'Standard user.' })"
Refresh-Status
$win.ShowDialog() | Out-Null
