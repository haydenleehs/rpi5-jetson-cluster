# Part 1 · Stage 2 — Flash the Jetson Orin Nano (JetPack 7.2.1)

JetPack 7.2 brought the Orin family onto **Ubuntu 24.04 / kernel 6.8 / CUDA 13**, matching the Pi.

> **No SD-card image any more.** From JetPack 7.2, the Orin Nano dev kit is installed with the **Jetson ISO** written to a **USB stick**, which then installs onto NVMe (or microSD). Don't write the ISO to the microSD.

## 2.0 Already flashed? Check before reflashing

If the Jetson already boots into Ubuntu, log in and run:

```bash
cat /etc/nv_tegra_release    # JetPack / Jetson Linux version
lsb_release -ds              # Ubuntu version
hostname; id                 # name + user/UID
```

| You see | Meaning | Do this |
|---|---|---|
| `R39 (release), REVISION: 2.x` + Ubuntu 24.04 | JetPack 7.2.x ✅ matches the Pi | **Skip to [2.4](#24-verify-update-install-packages)** (fix user/hostname first, see below) |
| `R36 ...` + Ubuntu 22.04 | JetPack 6.x ❌ (Slurm 21.08, too old for the Pi's 23.11) | Reflash: firmware is already new enough, **go straight to 2.2** |
| `R35 ...` or lower + Ubuntu 20.04 | JetPack 5.x ❌ | Reflash: **start at 2.1** (firmware update needed) |

Even on R39, check the user and hostname:

- `id` must show **`uid=1000(leecluster)`**, the same as the Pi. If the first user has a different name, reflashing is the cleanest fix.
- Wrong hostname is an easy fix: `sudo hostnamectl set-hostname orin-node01`

## 2.1 Check the firmware first

JetPack 7.2 needs **JetPack 6-generation UEFI/QSPI firmware (36.x or newer)** on the board.

- Power on with a monitor attached. The **UEFI version is shown on the NVIDIA splash screen**.
- If an OS is already installed: `sudo nvbootctrl dump-slots-info` → `Current version: 36.x.x`

| Firmware | Action |
|---|---|
| 36.x or 39.x | Continue to 2.2 |
| 35.x or older (or blank screen on boot) | Follow NVIDIA's **"JetPack 6.x Update Path"** in the Orin Nano dev kit user guide first. It uses a JetPack 5.1.3 SD card as a bridge to update QSPI |

## 2.2 Make the installer USB

1. Download the **Jetson ISO (r39.2.1)** from the JetPack downloads page: <https://developer.nvidia.com/embedded/jetpack>
2. Write it to the **USB stick** with **Balena Etcher**.

## 2.3 Install

1. Fit the **NVMe SSD** (M.2 slot under the module). Remove any old microSD to avoid boot confusion.
2. Plug in: USB installer, DisplayPort monitor, keyboard, Ethernet or Wi-Fi.
3. Power on and boot from USB (if it doesn't, press **Esc** at the splash → *Boot Manager* → USB).
4. Choose install target **NVMe**. If it prompts for a **firmware update, press `Y`**.
5. Remove the USB stick when told and reboot.
6. First-boot setup:

| Setting | Value |
|---|---|
| Username / password | **`leecluster`**, the same as the Pi |
| Hostname / computer name | `orin-node01` |
| Time zone | Singapore |

## 2.4 Verify, update, install packages

Do the big downloads **now**, using the Jetson's own Wi-Fi/Ethernet. After Stage 3 it gets internet through the Pi.

```bash
cat /etc/nv_tegra_release           # R39 (release), REVISION: 2.x
id                                  # uid=1000(leecluster)

sudo apt update && sudo apt full-upgrade -y
sudo apt install -y nvidia-jetpack  # CUDA, cuDNN, TensorRT (several GB)
sudo apt install -y munge slurmd slurm-client nfs-common \
  openmpi-bin libopenmpi-dev python3-mpi4py python3-numpy
sudo timedatectl set-timezone Asia/Singapore
```

## 2.5 Tune it as a compute node

```bash
sudo nvpmodel -q                                # current power mode
# pick MAXN SUPER: GUI power menu, or `sudo nvpmodel -m <id>` (ids listed in /etc/nvpmodel.conf)
sudo systemctl set-default multi-user.target    # boot headless, frees ~1 GB RAM
sudo reboot
```

Check the GPU after reboot:

```bash
nvidia-smi
/usr/local/cuda/bin/nvcc --version              # CUDA 13.x
```

Next: [Part 2 — Connect the nodes](../part2-network/README.md)
