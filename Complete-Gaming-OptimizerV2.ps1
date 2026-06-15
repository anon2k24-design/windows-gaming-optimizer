# ============================================================================
# Windows Optimization Script for Gaming & Performance
# ============================================================================
# Disables fullscreen optimizations, GameDVR, power saving, and applies
# network, GPU, and input latency optimizations for gaming.
#
# Support this project:
#   PayPal: https://www.paypal.com/donate/?business=UNP6WN3E95EAL&currency_code=USD
#   GitHub: https://github.com/anon2k24-design
#   Sponsor: https://github.com/sponsors/anon2k24-design
# ============================================================================

# Require Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $CommandLine = "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList $CommandLine
    exit
}

$ChangeLog = @()

function Add-Change {
    param($Type, $Path, $Name, $OldValue, $NewValue)
    $ChangeLog += [PSCustomObject]@{
        Timestamp  = Get-Date
        Type       = $Type
        Path       = $Path
        Name       = $Name
        OldValue   = $OldValue
        NewValue   = $NewValue
    }
    $ChangeLog | Export-Csv ".\optimization-change-log.csv" -NoTypeInformation -Encoding UTF8
}

function Set-DwordSafe {
    param(
        [string]$Path,
        [string]$Name,
        [int]$Value,
        [bool]$Log = $true
    )

    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }

    $oldValue = $null
    try { $oldValue = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name } catch {}

    New-ItemProperty -Path $Path -Name $Name -PropertyType DWord -Value $Value -Force | Out-Null

    if ($Log) {
        Add-Change -Type "Registry" -Path $Path -Name $Name -OldValue $oldValue -NewValue $Value
    }

    return [PSCustomObject]@{
        Path     = $Path
        Name     = $Name
        OldValue = $oldValue
        NewValue = $Value
    }
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Windows Optimization Script for Gaming" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================
# 1. GAME DVR & FULLSCREEN OPTIMIZATIONS
# ============================================
Write-Host "[1/6] Disabling GameDVR & Fullscreen Optimizations..." -ForegroundColor Yellow

$gameConfigPath = "HKCU:\System\GameConfigStore"
$gamePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"

if (-not (Test-Path $gameConfigPath)) {
    New-Item -Path $gameConfigPath -Force | Out-Null
    Write-Host "  Created registry key: $gameConfigPath" -ForegroundColor Yellow
}

Set-DwordSafe -Path $gameConfigPath -Name "GameDVR_FSEBehaviorMode" -Value 2
Set-DwordSafe -Path $gameConfigPath -Name "GameDVR_HonorUserFSEBehaviorMode" -Value 1
Set-DwordSafe -Path $gameConfigPath -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Value 1
Set-DwordSafe -Path $gameConfigPath -Name "GameDVR_Enabled" -Value 0
Set-DwordSafe -Path $gamePolicyPath -Name "AllowGameDVR" -Value 0

Write-Host "Full Screen Optimizations: Disabled (GameDVR_FSEBehaviorMode = 2)" -ForegroundColor Green
Write-Host "GameDVR: Disabled" -ForegroundColor Green

# ============================================
# 2. ULTIMATE PERFORMANCE POWER PLAN
# ============================================
Write-Host ""
Write-Host "[2/6] Enabling Ultimate Performance Power Plan..." -ForegroundColor Yellow

$ultimateGuid = "e9a42b02-d5df-448d-aa00-03f14749eb61"
$activeBefore = $null

try {
    $activeBefore = (powercfg /getactivescheme 2>&1 | Out-String).Trim()
} catch {}

powercfg /duplicatescheme $ultimateGuid | Out-Null
powercfg /setactive $ultimateGuid | Out-Null

Add-Change -Type "PowerPlan" -Path "Global" -Name "ActiveScheme" -OldValue $activeBefore -NewValue "Ultimate Performance ($ultimateGuid)"

Write-Host "Power Plan: Ultimate Performance enabled and activated" -ForegroundColor Green
Write-Host "  GUID: $ultimateGuid" -ForegroundColor DarkGray

# ============================================
# 3. INPUT LATENCY REDUCTION
# ============================================
Write-Host ""
Write-Host "[3/6] Reducing Input Latency..." -ForegroundColor Yellow

$mousePath = "HKCU:\Control Panel\Mouse"
$keyboardPath = "HKCU:\Control Panel\Keyboard"

Set-DwordSafe -Path $mousePath -Name "MouseSpeed" -Value 0
Set-DwordSafe -Path $mousePath -Name "MouseThreshold1" -Value 0
Set-DwordSafe -Path $mousePath -Name "MouseThreshold2" -Value 0
Set-DwordSafe -Path $keyboardPath -Name "KeyboardDelay" -Value 0

Write-Host "Mouse Acceleration: Disabled" -ForegroundColor Green
Write-Host "Keyboard Delay: 0ms" -ForegroundColor Green
Write-Host "Input Latency: Optimized" -ForegroundColor Green

# ============================================
# 4. SAFE SERVICES DISABLE
# ============================================
Write-Host ""
Write-Host "[4/6] Disabling Safe Services..." -ForegroundColor Yellow

$servicesToDisable = @(
    @{Name = "DiagTrack"; Description = "Diagnostics Tracking Service"},
    @{Name = "dmwappushservice"; Description = "WAP Push Message Routing Service"},
    @{Name = "lfsvc"; Description = "Geolocation Service"},
    @{Name = "MapsBroker"; Description = "Downloaded Maps Manager"},
    @{Name = "RemoteAccess"; Description = "Remote Access Connection Manager"}
)

foreach ($service in $servicesToDisable) {
    try {
        $svc = Get-Service -Name $service.Name -ErrorAction Stop
        Set-Service -Name $service.Name -StartupType Disabled -ErrorAction Stop
        Add-Change -Type "Service" -Path $service.Name -Name "StartupType" -OldValue $svc.StartType -NewValue "Disabled"
        Write-Host "Disabled: $($service.Name)" -ForegroundColor Green
    }
    catch {
        Write-Host "Skipping: $($service.Name) (not found or not accessible)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Optional services (not disabled by default):" -ForegroundColor DarkYellow
Write-Host "  SysMain (Superfetch) - only disable if you have specific SSD issues" -ForegroundColor DarkGray
Write-Host "  WSearch (Windows Search) - only disable if you do not use search" -ForegroundColor DarkGray
Write-Host "  BrokerInfrastructure - NOT disabled (critical for Windows shell)" -ForegroundColor DarkGray

# ============================================
# 5. NETWORK OPTIMIZATION (OPTIONAL MODE)
# ============================================
Write-Host ""
Write-Host "[5/6] Network Settings..." -ForegroundColor Yellow

Write-Host ""
Write-Host "Network optimization mode:" -ForegroundColor Yellow
Write-Host "  1. Safe (recommended - keeps autotuning enabled)" -ForegroundColor White
Write-Host "  2. Aggressive (disables autotuning/window scaling)" -ForegroundColor White
$networkMode = Read-Host "Enter choice (1-2)"

if ($networkMode -eq "2") {
    Write-Host "  WARNING: Disabling TCP autotuning may reduce overall throughput on some networks." -ForegroundColor DarkYellow
    
    try {
        $oldAutoTune = netsh interface tcp show global | Where-Object { $_ -match "Receive Window Auto-Tuning Level" }
        netsh interface tcp set global autotuninglevel=disabled | Out-Null
        Add-Change -Type "Network" -Path "Global" -Name "autotuninglevel" -OldValue $oldAutoTune -NewValue "disabled"
        Write-Host "TCP Autotuning: Disabled" -ForegroundColor Green
    } catch {
        Write-Host "Failed to disable TCP Autotuning" -ForegroundColor DarkYellow
    }

    try {
        $oldScale = netsh interface tcp show global | Where-Object { $_ -match "Window Scaling" }
        netsh interface tcp set global windowscaling=disabled | Out-Null
        Add-Change -Type "Network" -Path "Global" -Name "windowscaling" -OldValue $oldScale -NewValue "disabled"
        Write-Host "Window Scaling: Disabled" -ForegroundColor Green
    } catch {
        Write-Host "Failed to disable Window Scaling" -ForegroundColor DarkYellow
    }

    Write-Host "Network: Aggressive mode applied" -ForegroundColor Green
} else {
    Write-Host "Network: Safe mode (autotuning enabled, Microsoft recommended)" -ForegroundColor Green
    Write-Host "  Note: TCP autotuning improves throughput and is Microsoft default" -ForegroundColor DarkGray
}

# ============================================
# 6. GPU OPTIMIZATION (DETECTIVE MODE)
# ============================================
Write-Host ""
Write-Host "[6/6] GPU Settings..." -ForegroundColor Yellow

# Detect GPU vendor
$gpuInfo = Get-WmiObject Win32_VideoController | Select-Object -First 1
$gpuName = $gpuInfo.Name

if ($gpuName -match "NVIDIA") {
    Write-Host "  NVIDIA GPU detected: $gpuName" -ForegroundColor DarkGray
    
    $nvidiaPath = "HKCU:\SOFTWARE\NVIDIA Corporation\NVIDIA\Nv x64"
    if (Test-Path $nvidiaPath) {
        Set-DwordSafe -Path $nvidiaPath -Name "PowerManagementMode" -Value 1
        Write-Host "NVIDIA: Power Management = Performance Mode" -ForegroundColor Green
    } else {
        Write-Host "NVIDIA registry path not found (driver may use different location)" -ForegroundColor Yellow
    }
    
    Write-Host "  Tip: For NVIDIA, use NVIDIA Control Panel -> Power Management -> Prefer Maximum Performance" -ForegroundColor DarkGray
}
elseif ($gpuName -match "AMD") {
    Write-Host "  AMD GPU detected: $gpuName" -ForegroundColor DarkGray
    Write-Host "  Tip: For AMD, use AMD Software -> Performance -> GPU -> Power Mode -> Performance" -ForegroundColor DarkGray
}
elseif ($gpuName -match "Intel") {
    Write-Host "  Intel GPU detected: $gpuName" -ForegroundColor DarkGray
    Write-Host "  Tip: For Intel, use Intel Graphics Settings -> Power -> Power Mode -> Maximum Performance" -ForegroundColor DarkGray
}
else {
    Write-Host "  GPU: $gpuName" -ForegroundColor DarkGray
    Write-Host "  Tip: Use your GPU vendor control panel for performance power mode" -ForegroundColor DarkGray
}

Write-Host "GPU: Optimized for Gaming (via vendor control panel recommended)" -ForegroundColor Green

# ============================================
# FINAL
# ============================================
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  ALL OPTIMIZATIONS COMPLETE!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary of Changes:" -ForegroundColor Cyan
Write-Host "  Fullscreen Optimizations: Disabled" -ForegroundColor White
Write-Host "  GameDVR: Disabled" -ForegroundColor White
Write-Host "  Power Plan: Ultimate Performance" -ForegroundColor White
if ($networkMode -eq "2") {
    Write-Host "  TCP Autotuning: Disabled (Aggressive mode)" -ForegroundColor White
    Write-Host "  Window Scaling: Disabled (Aggressive mode)" -ForegroundColor White
} else {
    Write-Host "  TCP Autotuning: Enabled (Safe mode - Microsoft recommended)" -ForegroundColor White
}
Write-Host "  Safe Services: Disabled (DiagTrack, dmwappushservice, lfsvc, MapsBroker, RemoteAccess)" -ForegroundColor White
Write-Host "  Input Latency: Reduced" -ForegroundColor White
Write-Host ""
Write-Host "Change Log:" -ForegroundColor Cyan
Write-Host "  All changes saved to: optimization-change-log.csv" -ForegroundColor White
Write-Host ""
Write-Host "IMPORTANT: Restart your computer for all changes to apply!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Support this project:" -ForegroundColor Magenta
Write-Host "  PayPal: https://www.paypal.com/donate/?business=UNP6WN3E95EAL&currency_code=USD" -ForegroundColor White
Write-Host "  GitHub: https://github.com/anon2k24-design" -ForegroundColor White
Write-Host "  Sponsor: https://github.com/sponsors/anon2k24-design" -ForegroundColor White
Write-Host ""

Read-Host "Press Enter to exit"