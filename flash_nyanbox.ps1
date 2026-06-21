# flash_nyanbox.ps1
# PowerShell script to download and flash nyanBOX firmware using esptool.py with safe DIO flash mode.

$ProgressPreference = 'SilentlyContinue'

# 1. Get COM Port
$ports = [System.IO.Ports.SerialPort]::GetPortNames()
Write-Host "Available Serial Ports:" -ForegroundColor Cyan
if ($ports.Count -eq 0) {
    Write-Host "  No COM ports found! Plug in your ESP32 board." -ForegroundColor Yellow
} else {
    foreach ($p in $ports) {
        Write-Host "  - $p" -ForegroundColor Green
    }
}

$comPort = Read-Host "`nEnter your ESP32 COM Port (e.g., COM3)"
if ([string]::IsNullOrEmpty($comPort)) {
    Write-Host "Error: COM port is required." -ForegroundColor Red
    exit 1
}

# 2. Check for esptool
Write-Host "`nChecking if esptool.py is installed..." -ForegroundColor Cyan
$esptoolExists = $false
try {
    $null = Get-Command esptool.py -ErrorAction Stop
    $esptoolExists = $true
    Write-Host "Found esptool.py on your system!" -ForegroundColor Green
} catch {
    Write-Host "esptool.py not found in PATH." -ForegroundColor Yellow
    Write-Host "Attempting to install esptool via pip..." -ForegroundColor Cyan
    try {
        pip install esptool
        $null = Get-Command esptool.py -ErrorAction Stop
        $esptoolExists = $true
        Write-Host "Successfully installed esptool!" -ForegroundColor Green
    } catch {
        Write-Host "Failed to install esptool via pip. Please make sure Python and pip are installed." -ForegroundColor Red
        exit 1
    }
}

# 3. Download Files
$tempDir = Join-Path $PSScriptRoot "nyan_flash_temp"
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

$files = @(
    @{ name = "bootloader.bin"; url = "https://raw.githubusercontent.com/jbohack/nyanBOX/main/firmware-files/bootloader.bin" },
    @{ name = "partitions.bin"; url = "https://raw.githubusercontent.com/jbohack/nyanBOX/main/firmware-files/partitions.bin" },
    @{ name = "firmware.bin"; url = "https://raw.githubusercontent.com/jbohack/nyanBOX/main/firmware-files/firmware.bin" }
)

Write-Host "`nDownloading latest nyanBOX files from GitHub..." -ForegroundColor Cyan
foreach ($f in $files) {
    $dest = Join-Path $tempDir $f.name
    Write-Host "Downloading $($f.name)..."
    Invoke-WebRequest -Uri $f.url -OutFile $dest -UseBasicParsing
}
Write-Host "Downloads completed!" -ForegroundColor Green

# 4. Flash Device using esptool
# We use --flash_mode dio which is standard, safe, and prevents boot loops/burnout crashes.
Write-Host "`nFlashing nyanBOX to $comPort..." -ForegroundColor Yellow
Write-Host "If the flash fails to connect, hold the BOOT button on your ESP32 board now." -ForegroundColor Magenta

$bootloader = Join-Path $tempDir "bootloader.bin"
$partitions = Join-Path $tempDir "partitions.bin"
$firmware = Join-Path $tempDir "firmware.bin"

$command = "esptool.py --chip esp32 --port $comPort --baud 921600 --before default_reset --after hard_reset write_flash -z --flash_mode dio --flash_freq 40m --flash_size detect 0x1000 `"$bootloader`" 0x8000 `"$partitions`" 0x10000 `"$firmware`""

Write-Host "Executing command: $command" -ForegroundColor Cyan
Invoke-Expression $command

Write-Host "`nFlash attempt finished!" -ForegroundColor Green
Write-Host "You can close this window now." -ForegroundColor Yellow
