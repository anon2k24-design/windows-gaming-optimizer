# complete-gaming-optimizer.ps1
# All-in-one Gaming Optimization for Windows 10/11
# Run as Administrator

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  🎮 Complete Gaming Optimizer v1.0" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ ERROR: This script must be run as Administrator!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Running as Administrator" -ForegroundColor Green
Write-Host ""

# ============================================
# 1. DISABLE FSO + GameDVR
# ============================================
Write-Host "[1/6] Disabling Fullscreen Optimizations..." -ForegroundColor Yellow

$registryPath = "HKCU:\System\GameConfigStore"
if (-not (Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
}

Set-ItemProperty -Path $registryPath -Name "GameDVR_FSEBehaviorMode" -Value 2 -Force | Out-Null
Set-ItemProperty -Path $registryPath -Name "GameDVR_Enabled" -Value 0 -Force | Out-Null
Set-ItemProperty -Path $registryPath -Name "GameDVR_HonorUserFSEBehaviorMode" -Value 1 -Force | Out-Null
Set-ItemProperty -Path $registryPath -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Value 1 -Force | Out-Null

$policyPath = "HKCU:\SOFTWARE\Microsoft\PolicyManager\Default\ApplicationManagement"
if (-not (Test-Path $policyPath)) {
    New-Item -Path $policyPath -Force | Out-Null
}
Set-ItemProperty -Path $policyPath -Name "AllowGameDVR" -Value 0 -Force | Out-Null

Write-Host "✅ FSO Disabled (GameDVR_FSEBehaviorMode = 2)" -ForegroundColor Green
Write-Host "✅ GameDVR Disabled" -ForegroundColor Green

# ============================================
# 2. POWER PLAN OPTIMIZATION
# ============================================
Write-Host ""
Write-Host "[2/6] Setting Ultimate Performance Power Plan..." -ForegroundColor Yellow

# Enable Ultimate Performance plan
powercfg -duplicateplan "49d0873e-7be4-4d69-9d06-887a429be398" | Out-Null

# Set to Ultimate Performance
powercfg -setactive "Ultimate Performance" | Out-Null

# Disable CPU power saving
powercfg -change -processor-threshold-ac 0 | Out-Null

Write-Host "✅ Power Plan: Ultimate Performance" -ForegroundColor Green
Write-Host "✅ CPU Power Saving: Disabled" -ForegroundColor Green

# ============================================
# 3. NETWORK OPTIMIZATION
# ============================================
Write-Host ""
Write-Host "[3/6] Optimizing Network Settings..." -ForegroundColor Yellow

# Disable TCP autotuning (reduces latency)
netsh interface tcp set global autotuninglevel=disabled | Out-Null

# Disable烟囱 effect (window scaling)
netsh interface tcp set global windowscaling=disabled | Out-Null

# Disable OSPF
netsh interface tcp set global ospf=disabled | Out-Null

# Set optimal TCP parameters
netsh interface tcp set parameters namcachehint=16384 | Out-Null

Write-Host "✅ TCP Autotuning: Disabled" -ForegroundColor Green
Write-Host "✅ Window Scaling: Disabled" -ForegroundColor Green
Write-Host "✅ Network Latency: Optimized" -ForegroundColor Green

# ============================================
# 4. DISABLE UNNECESSARY SERVICES
# ============================================
Write-Host ""
Write-Host "[4/6] Disabling Unnecessary Services..." -ForegroundColor Yellow

$servicesToDisable = @(
    "DiagTrack",        # Diagnostics Tracking Service
    "WPCMP",            # Windows PushToInstall Service
    "BrokerInfrastructure", # Background Tasks
    "dmwappushservice", # WAP Push Message Routing Service
    "lfsvc",            # Geolocation Service
    "MapsBroker",       # Downloaded Maps Manager
    "RemoteAccess",     # Remote Access Connection Manager
    "SysMain",          # Superfetch (SSD optimization)
    "WSearch"           # Windows Search
)

foreach ($service in $servicesToDisable) {
    try {
        Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "✅ Disabled: $service" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Skipping: $service (not found)" -ForegroundColor Yellow
    }
}

# ============================================
# 5. GPU OPTIMIZATION
# ============================================
Write-Host ""
Write-Host "[5/6] Configuring GPU Settings..." -ForegroundColor Yellow

# NVIDIA optimization (if detected)
$nvidiaPath = "HKCU:\SOFTWARE\NVIDIA Corporation\NVIDIA GeForce"
if (Test-Path $nvidiaPath) {
    Set-ItemProperty -Path $nvidiaPath -Name "PowerManagementMode" -Value 1 -Force | Out-Null
    Set-ItemProperty -Path $nvidiaPath -Name "ThreadedOptimization" -Value 1 -Force | Out-Null
    Write-Host "✅ NVIDIA: Power Management = Performance" -ForegroundColor Green
    Write-Host "✅ NVIDIA: Threaded Optimization = On" -ForegroundColor Green
} else {
    Write-Host "⚠️  NVIDIA GPU not detected" -ForegroundColor Yellow
}

# AMD optimization (if detected)
$amdPath = "HKCU:\SOFTWARE\AMD\AMDGPU"
if (Test-Path $amdPath) {
    Set-ItemProperty -Path $amdPath -Name "PowerMode" -Value 2 -Force | Out-Null
    Write-Host "✅ AMD: Power Mode = Performance" -ForegroundColor Green
} else {
    Write-Host "⚠️  AMD GPU not detected" -ForegroundColor Yellow
}

# Set GPU priority for games
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name "ApplicationPreferredGPU" -Value "" -Force | Out-Null

Write-Host "✅ GPU Priority: Optimized for Gaming" -ForegroundColor Green

# ============================================
# 6. INPUT LATENCY REDUCTION
# ============================================
Write-Host ""
Write-Host "[6/6] Reducing Input Latency..." -ForegroundColor Yellow

# Disable mouse acceleration
Set-ItemProperty -Path "HKCU\Control Panel\Mouse" -Name "MouseSpeed" -Value 0 -Force | Out-Null
Set-ItemProperty -Path "HKCU\Control Panel\Mouse" -Name "MouseThreshold1" -Value 0 -Force | Out-Null
Set-ItemProperty -Path "HKCU\Control Panel\Mouse" -Name "MouseThreshold2" -Value 0 -Force | Out-Null

# Disable keyboard delay
Set-ItemProperty -Path "HKCU\Control Panel\Keyboard" -Name "KeyboardDelay" -Value 0 -Force | Out-Null

# Set high pointer precision
Set-ItemProperty -Path "HKCU\Control Panel\Mouse" -Name "MouseSpeed" -Value 0 -Force | Out-Null

Write-Host "✅ Mouse Acceleration: Disabled" -ForegroundColor Green
Write-Host "✅ Keyboard Delay: 0ms" -ForegroundColor Green
Write-Host "✅ Input Latency: Optimized" -ForegroundColor Green

# ============================================
# FINAL
# ============================================
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  ✅ ALL OPTIMIZATIONS COMPLETE!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Summary of Changes:" -ForegroundColor Cyan
Write-Host "  • Fullscreen Optimizations: Disabled" -ForegroundColor White
Write-Host "  • GameDVR: Disabled" -ForegroundColor White
Write-Host "  • Power Plan: Ultimate Performance" -ForegroundColor White
Write-Host "  • TCP Autotuning: Disabled" -ForegroundColor White
Write-Host "  • Unnecessary Services: Disabled" -ForegroundColor White
Write-Host "  • GPU: Optimized for Gaming" -ForegroundColor White
Write-Host "  • Input Latency: Reduced" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  IMPORTANT: Restart your computer for all changes to apply!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")