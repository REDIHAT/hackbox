# flash_nyanbox.ps1
# Advanced PowerShell script to download and flash nyanBOX firmware using esptool.py.
# Includes full flash erase, flash mode override (DOUT/DIO), and merged vs 3-part options.

$ProgressPreference = 'SilentlyContinue'

# 1. Get COM Port
$ports = [System.IO.Ports.SerialPort]::GetPortNames()
Write-Host "==============================================" -ForegroundColor Green
Write-Host "   REDIHAT LABS - HACKBOX NYANBOX FLASHER     " -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green
Write-Host "`nAvailable Serial Ports:" -ForegroundColor Cyan
if ($ports.Count -eq 0) {
    Write-Host "  No COM ports found! Please plug in your ESP32 board." -ForegroundColor Yellow
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

# 2. Check for esptool.py
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

# 3. Flashing Options Menu
Write-Host "`n==============================================" -ForegroundColor Cyan
Write-Host "Select Flashing Option:" -ForegroundColor Cyan
Write-Host "1) Flash 3-Part dynamic files (Bootloader + Partition + Firmware from GitHub)"
Write-Host "2) Flash Merged Binary (Single file NYANBOX_v4.40.17-MERGED.bin)"
Write-Host "==============================================" -ForegroundColor Cyan
$option = Read-Host "Enter option (1 or 2, default is 1)"
if ([string]::IsNullOrEmpty($option)) { $option = "1" }

# 4. Flash Mode Menu
Write-Host "`nSelect SPI Flash Mode (DOUT is highly recommended to prevent pin conflicts/bootloops):" -ForegroundColor Cyan
Write-Host "1) DOUT (Dual Output - Safest, bypasses GPIO 9/10 conflicts)"
Write-Host "2) DIO  (Dual I/O)"
Write-Host "3) QIO  (Quad I/O)"
$flashModeOpt = Read-Host "Enter option (1, 2 or 3, default is 1)"
$flashMode = "dout"
if ($flashModeOpt -eq "2") { $flashMode = "dio" }
if ($flashModeOpt -eq "3") { $flashMode = "qio" }

# 5. Full Erase Confirmation
$eraseConfirm = Read-Host "`nDo you want to perform a FULL FLASH ERASE first? (Highly recommended when switching firmware) (y/n, default is y)"
if ([string]::IsNullOrEmpty($eraseConfirm)) { $eraseConfirm = "y" }

# 6. Baud Rate Selection
$baudRate = Read-Host "`nEnter Baud Rate (default is 115200 for maximum stability)"
if ([string]::IsNullOrEmpty($baudRate)) { $baudRate = "115200" }

# 7. Download Files
$tempDir = Join-Path $PSScriptRoot "nyan_flash_temp"
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

if ($option -eq "1") {
    # 3-Part download
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
} else {
    # Merged download from local or backup url
    $mergedUrl = "https://raw.githubusercontent.com/REDIHAT/hackbox/main/firmware/NYANBOX_v4.40.17-MERGED.bin"
    $dest = Join-Path $tempDir "NYANBOX_v4.40.17-MERGED.bin"
    Write-Host "`nDownloading merged binary..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $mergedUrl -OutFile $dest -UseBasicParsing
}
Write-Host "Download completed successfully!" -ForegroundColor Green

# 8. Erase Flash if requested
if ($eraseConfirm -eq "y" -or $eraseConfirm -eq "Y") {
    Write-Host "`nPerforming full flash erase on $comPort..." -ForegroundColor Yellow
    Write-Host "If it fails to connect, hold the BOOT button on your ESP32 board now." -ForegroundColor Magenta
    esptool.py --chip esp32 --port $comPort erase_flash
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erase failed! Exiting." -ForegroundColor Red
        exit 1
    }
    Write-Host "Flash erase successful!" -ForegroundColor Green
}

# 9. Flash Device
Write-Host "`nFlashing nyanBOX to $comPort in $flashMode mode..." -ForegroundColor Yellow
Write-Host "If it fails to connect, hold the BOOT button on your ESP32 board now." -ForegroundColor Magenta

if ($option -eq "1") {
    $bootloader = Join-Path $tempDir "bootloader.bin"
    $partitions = Join-Path $tempDir "partitions.bin"
    $firmware = Join-Path $tempDir "firmware.bin"
    $command = "esptool.py --chip esp32 --port $comPort --baud $baudRate --before default_reset --after hard_reset write_flash -z --flash_mode $flashMode --flash_freq 40m --flash_size detect 0x1000 `"$bootloader`" 0x8000 `"$partitions`" 0x10000 `"$firmware`""
} else {
    $merged = Join-Path $tempDir "NYANBOX_v4.40.17-MERGED.bin"
    $command = "esptool.py --chip esp32 --port $comPort --baud $baudRate --before default_reset --after hard_reset write_flash -z --flash_mode $flashMode --flash_freq 40m --flash_size detect 0x0 `"$merged`""
}

Write-Host "Executing command: $command" -ForegroundColor Cyan
Invoke-Expression $command

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n==============================================" -ForegroundColor Green
    Write-Host "  SUCCESS: nyanBOX flashed successfully!" -ForegroundColor Green
    Write-Host "==============================================" -ForegroundColor Green
} else {
    Write-Host "`n==============================================" -ForegroundColor Red
    Write-Host "  FAILURE: Flashing failed. Check connections and try again." -ForegroundColor Red
    Write-Host "==============================================" -ForegroundColor Red
}

Write-Host "`nFlash process completed. Press enter to exit." -ForegroundColor Yellow
Read-Host
