# Hackbox

Welcome to the **Hackbox** repository! This is a consolidated workspace containing firmware binaries and a custom web flasher interface for the most popular ESP32-based wireless auditing and multi-tool suites.

## ⚡ Web Flasher Page
We host a premium custom web-serial flasher directly from this repository. You can access it via GitHub Pages:
**[Launch Hackbox Web Flasher](index.html)**

---

## 💾 Stored Firmware Binary Directory

All binaries listed below are stored inside the **`firmware/`** directory. These are unified merged binaries, meaning they contain the bootloader, partition maps, and application code. They should be flashed directly to address **`0x0`**:

1. **RF-Clown (v2.0.0)**
   * **`RFclown_v2.0.0_MERGED.bin`**: A Sub-GHz RF analysis tool designed to scan, copy, transmit, and experiment with RF frequencies using a CC1101 module.
2. **nRFBox (v2.7.2)**
   * **`NRFBox_v2.7.2_MERGED.bin`**: A 2.4GHz testing suite designed for NRF24L01+ signal sniffing, packet decoding, and jamming/spoofing exercises.
   * **`nyanbox_merged.bin`**: A dynamic wireless multi-tool for ESP32 platforms. Pre-merged with bootloader, partition table, and latest firmware for one-step flashing.
4. **BWifiKill-ESP32**
   * **`Bwifikill_MERGED.bin`**: A WiFi security testing and packet manipulation suite. (The web flasher queries the GitHub Releases API for dynamic version upgrades, falling back to this precompiled package when offline).
5. **Hackbox CK42X**
   * **`hackbox-main-merged.bin`**: Precompiled merged binary of the [lordbuffcloud/hackbox_ck42x](https://github.com/lordbuffcloud/hackbox_ck42x) project, optimized for wireless auditing.

---

## 🛠️ Flashing Manually

If you prefer to flash using standard command-line tools instead of the Web Flasher:

### Requirements
Ensure you have `esptool.py` installed:
```bash
pip install esptool
```

### Flash Command
Run the following command (substituting `[PORT]` with your serial port name and `[FILE]` with the binary path):
```bash
esptool.py --chip esp32 --port [PORT] write_flash 0x0 [FILE]
```
Example:
```bash
esptool.py --chip esp32 --port COM3 write_flash 0x0 firmware/hackbox-main-merged.bin
```
