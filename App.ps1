# Candela - Studio Display XDR on Windows. Launch via Candela.cmd (asks for admin once).
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Candela" Width="640" Height="840" MinWidth="560" MinHeight="640" ResizeMode="CanResize"
        WindowStartupLocation="CenterScreen" Background="#141518" FontFamily="Segoe UI Variable Text, Segoe UI" FontSize="13" Foreground="#ECEBE7"
        Typography.NumeralAlignment="Tabular"
        UseLayoutRounding="True" SnapsToDevicePixels="True" TextOptions.TextFormattingMode="Ideal" TextOptions.TextRenderingMode="ClearType">
  <Window.Resources>
    <!-- Graphite and ink (Kennedy Maombi's design language, dark theme): ground rgb(20 21 24), ink rgb(236 235 231),
         secondary rgb(141 144 150), hairline rgb(42 44 49). No filled panels: each section is a keyline row on the
         ground, a rule across the window with its index and label on the left and its rows on the right. -->
    <SolidColorBrush x:Key="Ground" Color="#141518"/>
    <SolidColorBrush x:Key="Ink" Color="#ECEBE7"/>
    <SolidColorBrush x:Key="Secondary" Color="#8D9096"/>
    <SolidColorBrush x:Key="Tertiary" Color="#63666C"/>
    <SolidColorBrush x:Key="Line" Color="#2A2C31"/>
    <SolidColorBrush x:Key="Rule" Color="#3A3C41"/>
    <SolidColorBrush x:Key="Edge" Color="#4A4D53"/>
    <SolidColorBrush x:Key="Chip" Color="#212226"/>
    <SolidColorBrush x:Key="Night" Color="#0E0F11"/>
    <!-- The only colour in the window: the status mark, identified or not. -->
    <SolidColorBrush x:Key="Green" Color="#7DBA8C"/>
    <SolidColorBrush x:Key="Red" Color="#E2674F"/>
    <FontFamily x:Key="Figures">Bahnschrift, Segoe UI</FontFamily>

    <Style x:Key="Keyline" TargetType="Border">
      <Setter Property="BorderBrush" Value="{StaticResource Rule}"/><Setter Property="BorderThickness" Value="0,1,0,0"/>
      <Setter Property="Margin" Value="0,32,0,0"/>
    </Style>
    <Style x:Key="Index" TargetType="TextBlock">
      <Setter Property="FontFamily" Value="{StaticResource Figures}"/><Setter Property="FontSize" Value="12"/>
      <Setter Property="Foreground" Value="{StaticResource Secondary}"/><Setter Property="Width" Value="30"/>
      <Setter Property="VerticalAlignment" Value="Center"/>
    </Style>
    <Style x:Key="SectionLabel" TargetType="TextBlock">
      <Setter Property="FontSize" Value="13"/><Setter Property="VerticalAlignment" Value="Center"/>
    </Style>
    <Style x:Key="RowLabel" TargetType="TextBlock">
      <Setter Property="VerticalAlignment" Value="Center"/><Setter Property="FontSize" Value="13"/>
    </Style>
    <Style x:Key="RowSub" TargetType="TextBlock">
      <Setter Property="Foreground" Value="{StaticResource Secondary}"/><Setter Property="FontSize" Value="12"/>
      <Setter Property="Margin" Value="0,3,0,0"/><Setter Property="TextWrapping" Value="Wrap"/>
    </Style>
    <Style x:Key="RowValue" TargetType="TextBlock">
      <Setter Property="VerticalAlignment" Value="Center"/><Setter Property="FontSize" Value="13"/><Setter Property="TextAlignment" Value="Right"/>
    </Style>
    <Style x:Key="RowSep" TargetType="Rectangle">
      <Setter Property="Height" Value="1"/><Setter Property="Fill" Value="{StaticResource Line}"/>
    </Style>
    <Style x:Key="Row" TargetType="Grid">
      <Setter Property="Margin" Value="0,13,0,13"/>
    </Style>

    <!-- Buttons: a hairline outline and 3px corners; the one primary action is ink on graphite. -->
    <Style TargetType="Button">
      <Setter Property="Background" Value="Transparent"/><Setter Property="Foreground" Value="{StaticResource Ink}"/>
      <Setter Property="BorderBrush" Value="{StaticResource Edge}"/><Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="12,5"/><Setter Property="FontSize" Value="13"/><Setter Property="Cursor" Value="Hand"/>
      <Setter Property="VerticalAlignment" Value="Center"/><Setter Property="MinWidth" Value="72"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="b" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="3" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Background" Value="{StaticResource Chip}"/></Trigger>
              <Trigger Property="IsPressed" Value="True"><Setter TargetName="b" Property="Opacity" Value="0.75"/></Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter Property="Foreground" Value="{StaticResource Tertiary}"/>
                <Setter TargetName="b" Property="BorderBrush" Value="{StaticResource Line}"/>
                <Setter TargetName="b" Property="Background" Value="Transparent"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="Primary" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
      <Setter Property="Background" Value="{StaticResource Ink}"/><Setter Property="BorderBrush" Value="{StaticResource Ink}"/>
      <Setter Property="Foreground" Value="{StaticResource Ground}"/><Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="b" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="1" CornerRadius="3" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Opacity" Value="0.88"/></Trigger>
              <Trigger Property="IsPressed" Value="True"><Setter TargetName="b" Property="Opacity" Value="0.75"/></Trigger>
              <!-- Done, or not allowed: it settles into a quiet outlined label. -->
              <Trigger Property="IsEnabled" Value="False">
                <Setter Property="Foreground" Value="{StaticResource Secondary}"/><Setter Property="FontWeight" Value="Normal"/>
                <Setter TargetName="b" Property="Background" Value="Transparent"/>
                <Setter TargetName="b" Property="BorderBrush" Value="{StaticResource Line}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="Link" TargetType="Button">
      <Setter Property="Foreground" Value="{StaticResource Ink}"/><Setter Property="FontSize" Value="12"/><Setter Property="Cursor" Value="Hand"/>
      <Setter Property="VerticalAlignment" Value="Center"/><Setter Property="Margin" Value="20,0,0,0"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border Background="Transparent" Padding="0,3"><ContentPresenter VerticalAlignment="Center"/></Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter Property="Foreground" Value="{StaticResource Secondary}"/></Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter Property="Foreground" Value="{StaticResource Tertiary}"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Toggle: a squared hairline track; on, it fills with ink. -->
    <Style TargetType="ToggleButton">
      <Setter Property="Width" Value="36"/><Setter Property="Height" Value="20"/><Setter Property="Cursor" Value="Hand"/><Setter Property="VerticalAlignment" Value="Center"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ToggleButton">
            <Grid>
              <Border x:Name="track" CornerRadius="3" Background="Transparent" BorderBrush="{StaticResource Edge}" BorderThickness="1"/>
              <Border x:Name="thumb" Width="12" Height="12" CornerRadius="2" Background="{StaticResource Secondary}" HorizontalAlignment="Left" Margin="4,0,0,0"/>
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="track" Property="BorderBrush" Value="{StaticResource Secondary}"/></Trigger>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="track" Property="Background" Value="{StaticResource Ink}"/>
                <Setter TargetName="track" Property="BorderBrush" Value="{StaticResource Ink}"/>
                <Setter TargetName="thumb" Property="Background" Value="{StaticResource Ground}"/>
                <Setter TargetName="thumb" Property="HorizontalAlignment" Value="Right"/>
                <Setter TargetName="thumb" Property="Margin" Value="0,0,4,0"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.35"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Segmented control pieces: one hairline frame, hairlines between. -->
    <Style x:Key="Seg" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
      <Setter Property="BorderThickness" Value="0"/><Setter Property="MinWidth" Value="62"/><Setter Property="Padding" Value="10,4"/><Setter Property="FontSize" Value="12"/>
    </Style>
    <Style x:Key="SegSep" TargetType="Rectangle">
      <Setter Property="Width" Value="1"/><Setter Property="Fill" Value="{StaticResource Edge}"/>
    </Style>

    <!-- Scroll bar: a thin hairline thumb, no arrows. -->
    <Style TargetType="ScrollBar">
      <Setter Property="Width" Value="10"/><Setter Property="MinWidth" Value="10"/><Setter Property="Background" Value="Transparent"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ScrollBar">
            <Track x:Name="PART_Track" IsDirectionReversed="True">
              <Track.Thumb>
                <Thumb>
                  <Thumb.Template>
                    <ControlTemplate TargetType="Thumb"><Border Background="{StaticResource Edge}" CornerRadius="2" Width="4" HorizontalAlignment="Center"/></ControlTemplate>
                  </Thumb.Template>
                </Thumb>
              </Track.Thumb>
            </Track>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Drafting: the outline in ink; dimensions and centre lines in the secondary tone. -->
    <Style x:Key="Dim" TargetType="TextBlock">
      <Setter Property="FontFamily" Value="{StaticResource Figures}"/><Setter Property="FontSize" Value="9"/>
      <Setter Property="Foreground" Value="{StaticResource Secondary}"/><Setter Property="Background" Value="{StaticResource Ground}"/>
      <Setter Property="Padding" Value="3,0"/><Setter Property="HorizontalAlignment" Value="Center"/><Setter Property="VerticalAlignment" Value="Center"/>
    </Style>
  </Window.Resources>

  <Grid>
    <ScrollViewer VerticalScrollBarVisibility="Auto">
      <StackPanel Margin="32,30,32,24">

        <!-- Header: the display, drawn front-on and dimensioned at its native 5120 x 2880; then its name and status -->
        <Grid>
          <Grid.ColumnDefinitions><ColumnDefinition Width="132"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
          <Canvas Width="112" Height="90" HorizontalAlignment="Left" VerticalAlignment="Center">
            <Line X1="3" Y1="41.5" X2="100" Y2="41.5" Stroke="{StaticResource Secondary}" StrokeThickness="1" StrokeDashArray="9 2 1.5 2" Opacity="0.6"/>
            <Line X1="52.5" Y1="11" X2="52.5" Y2="89" Stroke="{StaticResource Secondary}" StrokeThickness="1" StrokeDashArray="9 2 1.5 2" Opacity="0.6"/>
            <Rectangle Canvas.Left="8" Canvas.Top="16" Width="89" Height="51" RadiusX="2" RadiusY="2" Stroke="{StaticResource Ink}" StrokeThickness="1"/>
            <Rectangle Canvas.Left="11" Canvas.Top="19" Width="83" Height="45" Stroke="{StaticResource Secondary}" StrokeThickness="1" Opacity="0.55"/>
            <Path Data="M45.5,67 L45.5,80 M59.5,67 L59.5,80" Stroke="{StaticResource Ink}" StrokeThickness="1"/>
            <Rectangle Canvas.Left="34" Canvas.Top="80" Width="37" Height="5" RadiusX="1" RadiusY="1" Stroke="{StaticResource Ink}" StrokeThickness="1"/>
            <Path Data="M8.5,14 L8.5,4 M96.5,14 L96.5,4 M8.5,8.5 L96.5,8.5" Stroke="{StaticResource Secondary}" StrokeThickness="1"/>
            <Path Data="M8.5,8.5 L15,6.8 L15,10.2 Z M96.5,8.5 L90,6.8 L90,10.2 Z" Fill="{StaticResource Secondary}"/>
            <Grid Canvas.Left="8" Canvas.Top="2" Width="89" Height="13"><TextBlock Style="{StaticResource Dim}" Text="5120"/></Grid>
            <Path Data="M99,16.5 L109,16.5 M99,66.5 L109,66.5 M104.5,16.5 L104.5,66.5" Stroke="{StaticResource Secondary}" StrokeThickness="1"/>
            <Path Data="M104.5,16.5 L102.8,23 L106.2,23 Z M104.5,66.5 L102.8,60 L106.2,60 Z" Fill="{StaticResource Secondary}"/>
            <Grid Canvas.Left="79.5" Canvas.Top="35" Width="50" Height="13" RenderTransformOrigin="0.5,0.5">
              <Grid.RenderTransform><RotateTransform Angle="-90"/></Grid.RenderTransform>
              <TextBlock Style="{StaticResource Dim}" Text="2880"/>
            </Grid>
          </Canvas>
          <StackPanel Grid.Column="1" VerticalAlignment="Center" Margin="0,4,0,0">
            <TextBlock x:Name="hTitle" Text="Studio Display XDR" FontSize="26" FontFamily="Segoe UI Variable Display, Segoe UI"/>
            <StackPanel Orientation="Horizontal" Margin="0,8,0,0">
              <Rectangle x:Name="hDot" Width="7" Height="7" Fill="{StaticResource Green}" VerticalAlignment="Center" Margin="0,1,9,0"/>
              <TextBlock x:Name="hStatus" Text="Checking…" FontSize="13"/>
            </StackPanel>
            <TextBlock x:Name="hSub" Text="" Foreground="{StaticResource Secondary}" FontSize="12" Margin="16,4,0,0" TextWrapping="Wrap"/>
          </StackPanel>
        </Grid>

        <!-- 01 Detection -->
        <Border Style="{StaticResource Keyline}">
          <Grid>
            <Grid.ColumnDefinitions><ColumnDefinition Width="132"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <StackPanel Orientation="Horizontal" Margin="0,14,0,0" VerticalAlignment="Top">
              <TextBlock Style="{StaticResource Index}" Text="01"/><TextBlock Style="{StaticResource SectionLabel}" Text="Detection"/>
            </StackPanel>
            <StackPanel Grid.Column="1">
              <Grid Style="{StaticResource Row}">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <StackPanel>
                  <TextBlock x:Name="dTitle" Style="{StaticResource RowLabel}" Text="Display identification"/>
                  <TextBlock x:Name="dSub" Style="{StaticResource RowSub}" Text=""/>
                </StackPanel>
                <Button x:Name="bApply" Grid.Column="1" Style="{StaticResource Primary}" Content="Fix" Margin="20,0,0,0"/>
              </Grid>
              <Rectangle Style="{StaticResource RowSep}"/>
              <Grid Style="{StaticResource Row}">
                <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                <TextBlock Style="{StaticResource RowLabel}" Foreground="{StaticResource Secondary}" Text="Graphics"/>
                <TextBlock x:Name="dGpu" Grid.Column="1" Style="{StaticResource RowValue}" Text="—" TextWrapping="Wrap" Margin="16,0,0,0"/>
              </Grid>
            </StackPanel>
          </Grid>
        </Border>

        <!-- 02 Display -->
        <Border Style="{StaticResource Keyline}">
          <Grid>
            <Grid.ColumnDefinitions><ColumnDefinition Width="132"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <StackPanel Orientation="Horizontal" Margin="0,14,0,0" VerticalAlignment="Top">
              <TextBlock Style="{StaticResource Index}" Text="02"/><TextBlock Style="{StaticResource SectionLabel}" Text="Display"/>
            </StackPanel>
            <StackPanel Grid.Column="1">
              <Grid Margin="0,8,0,8">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <TextBlock Style="{StaticResource RowLabel}" Foreground="{StaticResource Secondary}" Text="Resolution"/>
                <TextBlock x:Name="vRes" Grid.Column="1" Style="{StaticResource RowValue}" Text="—" Margin="0,0,14,0"/>
                <Button x:Name="bMode" Grid.Column="2" Content="Use best"/>
              </Grid>
              <Rectangle Style="{StaticResource RowSep}"/>
              <Grid Style="{StaticResource Row}">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <TextBlock Style="{StaticResource RowLabel}" Foreground="{StaticResource Secondary}" Text="Refresh rate"/>
                <TextBlock x:Name="vHz" Grid.Column="1" Style="{StaticResource RowValue}" Text="—"/>
              </Grid>
              <Rectangle Style="{StaticResource RowSep}"/>
              <Grid Style="{StaticResource Row}">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <TextBlock Style="{StaticResource RowLabel}" Foreground="{StaticResource Secondary}" Text="Color depth"/>
                <TextBlock x:Name="vBits" Grid.Column="1" Style="{StaticResource RowValue}" Text="—"/>
              </Grid>
              <Rectangle Style="{StaticResource RowSep}"/>
              <Grid Style="{StaticResource Row}">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <StackPanel VerticalAlignment="Center">
                  <TextBlock Style="{StaticResource RowLabel}" Foreground="{StaticResource Secondary}" Text="Text size"/>
                  <TextBlock x:Name="vDpi" FontSize="13" Margin="0,3,0,0" Text=""/>
                </StackPanel>
                <Border Grid.Column="1" BorderBrush="{StaticResource Edge}" BorderThickness="1" CornerRadius="3" VerticalAlignment="Center" Margin="16,0,0,0">
                  <StackPanel Orientation="Horizontal">
                    <Button x:Name="bDpiDown" Style="{StaticResource Seg}" Content="Smaller"/>
                    <Rectangle Style="{StaticResource SegSep}"/>
                    <Button x:Name="bDpiDefault" Style="{StaticResource Seg}" Content="Default"/>
                    <Rectangle Style="{StaticResource SegSep}"/>
                    <Button x:Name="bDpiUp" Style="{StaticResource Seg}" Content="Larger"/>
                  </StackPanel>
                </Border>
              </Grid>
            </StackPanel>
          </Grid>
        </Border>

        <!-- 03 Color -->
        <Border Style="{StaticResource Keyline}">
          <Grid>
            <Grid.ColumnDefinitions><ColumnDefinition Width="132"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <StackPanel Orientation="Horizontal" Margin="0,14,0,0" VerticalAlignment="Top">
              <TextBlock Style="{StaticResource Index}" Text="03"/><TextBlock Style="{StaticResource SectionLabel}" Text="Color"/>
            </StackPanel>
            <StackPanel Grid.Column="1">
              <Grid Style="{StaticResource Row}">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <StackPanel>
                  <TextBlock Style="{StaticResource RowLabel}" Text="High Dynamic Range"/>
                  <TextBlock x:Name="cHdrSub" Style="{StaticResource RowSub}" Text="Up to 2000 nits for HDR video and games."/>
                </StackPanel>
                <ToggleButton x:Name="tHdr" Grid.Column="1" Margin="20,0,0,0"/>
              </Grid>
              <Rectangle Style="{StaticResource RowSep}"/>
              <Grid Style="{StaticResource Row}">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <StackPanel>
                  <TextBlock Style="{StaticResource RowLabel}" Text="Automatic color management"/>
                  <TextBlock x:Name="cAcmSub" Style="{StaticResource RowSub}" Text="Accurate sRGB on the P3 panel for apps that are not color managed."/>
                </StackPanel>
                <ToggleButton x:Name="tAcm" Grid.Column="1" Margin="20,0,0,0"/>
              </Grid>
            </StackPanel>
          </Grid>
        </Border>

        <!-- Footer -->
        <Border Style="{StaticResource Keyline}">
          <Grid Margin="0,14,0,0">
            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
            <TextBlock x:Name="fNote" Foreground="{StaticResource Secondary}" FontSize="11" VerticalAlignment="Center" TextWrapping="Wrap" Text=""/>
            <Button x:Name="bRestore" Grid.Column="1" Style="{StaticResource Link}" Content="Restore original…"/>
            <Button x:Name="bDetails" Grid.Column="2" Style="{StaticResource Link}" Content="Details"/>
          </Grid>
        </Border>
        <Border x:Name="LogPanel" Background="{StaticResource Night}" BorderBrush="{StaticResource Line}" BorderThickness="1" CornerRadius="3" Margin="0,12,0,0" Visibility="Collapsed">
          <TextBox x:Name="Log" Background="Transparent" Foreground="#B9BBBF" BorderThickness="0" FontFamily="Cascadia Mono, Consolas" FontSize="11" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" Height="160" Padding="12,8"/>
        </Border>
      </StackPanel>
    </ScrollViewer>
  </Grid>
</Window>
"@
$reader = New-Object System.Xml.XmlNodeReader $xaml
$win = [Windows.Markup.XamlReader]::Load($reader)
# Title bar in the window's graphite (Windows 11 draws the caption and border colours; older builds ignore it).
try {
  Add-Type -Namespace Candela -Name Dwm -MemberDefinition '[DllImport("dwmapi.dll")] public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int value, int size);'
  $win.Add_SourceInitialized({
    $h = (New-Object System.Windows.Interop.WindowInteropHelper $win).Handle
    foreach ($a in @(@(20, 1), @(35, 0x00181514), @(34, 0x00312C2A), @(36, 0x00E7EBEC))) { $v = [int]$a[1]; [void][Candela.Dwm]::DwmSetWindowAttribute($h, $a[0], [ref]$v, 4) }
  })
} catch {}
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
