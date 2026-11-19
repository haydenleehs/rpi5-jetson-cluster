# Part 1 · Stage 0 — Hardware

| Item | Notes |
|---|---|
| Raspberry Pi 5 | 4 GB or 8 GB |
| Pi 5 power supply | Official 27 W USB-C |
| microSD card for Pi | 32 GB+ |
| Jetson Orin Nano Super Developer Kit | Includes its own DC power supply |
| NVMe SSD for Jetson (M.2 2280) | Recommended over microSD (faster, more space) |
| USB stick, 16 GB+ | For the Jetson ISO installer (gets erased) |
| Ethernet cable ×1 | Pi `eth0` ↔ Jetson. Direct cable is fine (auto-MDIX) |
| DisplayPort monitor + USB keyboard | Jetson first boot only. **The dev kit has DisplayPort, not HDMI** |
| Micro-HDMI cable (optional) | Pi console if SSH doesn't work |
| USB-to-Ethernet adapter (optional) | Lets the laptop stay cabled to the Pi after `eth0` goes to the Jetson |

## Ports at a glance

- **Pi 5 has one Ethernet port.** In Part 2 (Stage 3) it becomes the cluster link to the Jetson, so after that the Pi gets internet over **Wi-Fi**.
- During Stages 1–2 you can borrow that port for a laptop cable (see [Stage 1](../part1-setup/stage1-pi5.md#option-b--laptop-ethernet-cable-windows-ics)).

Next: [Stage 1 — Flash & access the Pi 5](../part1-setup/stage1-pi5.md)
