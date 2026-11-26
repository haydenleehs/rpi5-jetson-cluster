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

Even on R39, check the user, hostname and clock. A board that came **pre-flashed** (e.g. user `jetson`, hostname `localhost.localdomain`) needs the fixes in 2.0a–2.0c before 2.4.

### 2.0a Fix the clock (pre-flashed boards often boot in the wrong year)

Symptoms: `apt update` fails with *"Release file … is not valid yet (invalid for another 20783d)"* and *"certificate … not yet valid"*.

```bash
date                                     # wrong year?
sudo timedatectl set-ntp true
sudo systemctl restart systemd-timesyncd
sleep 15; timedatectl                    # System clock synchronized: yes
# still wrong? set it by hand:
#   sudo timedatectl set-ntp false; sudo date -s "2026-11-26 20:10:00"; sudo timedatectl set-ntp true
sudo hwclock -w                          # save to the hardware clock
```

### 2.0b Rename the user to `leecluster` with UID 1000

`id` must show **`uid=1000(leecluster)`**, exactly like the Pi (Slurm runs jobs by UID; NFS owns files by UID).

You can't rename or re-UID a user while logged in as it, so use a **temporary admin with a fixed UID of 1500**. Don't use plain `adduser`: it takes the first free ID, which may be the 1000 you need.

```bash
# as the old user (e.g. jetson)
sudo groupadd -g 1500 tempfix
sudo useradd -m -u 1500 -g 1500 -G sudo -s /bin/bash tempfix
sudo passwd tempfix
sudo reboot
```

Log in as **`tempfix`** (on the Jetson's own keyboard, or `ssh tempfix@<jetson-ip>`):

```bash
OLD=jetson                                    # the pre-flashed username
OLDUID=$(id -u $OLD)                          # e.g. 1000 or 2002
sudo systemctl isolate multi-user.target      # stop the desktop session
sudo pkill -u $OLD; sleep 2

sudo usermod -l leecluster -d /home/leecluster -m $OLD
sudo groupmod -n leecluster $OLD
sudo chfn -f "leecluster" leecluster          # login-screen display name

# move to UID/GID 1000 if it isn't already
if [ "$OLDUID" != 1000 ]; then
  getent passwd 1000 && echo "STOP: UID 1000 is taken"      # must print nothing
  getent group 1000  && echo "STOP: GID 1000 is taken"      # must print nothing
  sudo groupmod -g 1000 leecluster
  sudo usermod -u 1000 -g 1000 leecluster                   # also re-owns /home/leecluster
  sudo find / -xdev -uid $OLDUID -exec chown -h 1000 {} + 2>/dev/null
  sudo find / -xdev -gid $OLDUID -exec chgrp -h 1000 {} + 2>/dev/null
fi

id leecluster                                 # uid=1000(leecluster) gid=1000(leecluster)
sudo reboot
```

Log in as `leecluster`, then remove the temp user and check auto-login:

```bash
sudo userdel -r tempfix
grep -i AutomaticLogin /etc/gdm3/custom.conf  # if it names the old user, change it to leecluster
```

The password stays the old user's password (change with `passwd`). It doesn't need to match the Pi; only the **username and UID** must.

### 2.0c Fix the hostname

```bash
sudo hostnamectl set-hostname orin-node01
sudo sed -i 's/localhost.localdomain/orin-node01/g' /etc/hosts
hostname                                      # orin-node01
```

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

Connect to Wi-Fi if needed (home Wi-Fi or hotspot; not eduroam):

```bash
nmcli dev wifi list
sudo nmcli dev wifi connect "YOUR_SSID" password "YOUR_WIFI_PASSWORD"
ping -c 3 google.com
```

```bash
cat /etc/nv_tegra_release           # R39 (release), REVISION: 2.x
id                                  # uid=1000(leecluster)

sudo apt update && sudo apt full-upgrade -y   # must finish with no "E:" lines (if it does: 2.0a clock)
sudo apt install -y nvidia-jetpack  # CUDA, cuDNN, TensorRT (several GB)
sudo apt install -y munge slurmd slurm-client nfs-common \
  openmpi-bin libopenmpi-dev python3-mpi4py python3-numpy
sudo timedatectl set-timezone Asia/Singapore
slurmd -V                           # slurm 23.11.x
```

## 2.5 Tune it as a compute node

```bash
sudo nvpmodel -q                                # current power mode
grep -n "POWER_MODEL" /etc/nvpmodel.conf       # find the MAXN SUPER id
sudo nvpmodel -m <id>
sudo systemctl set-default multi-user.target    # boot headless, frees ~1 GB RAM
sudo reboot
```

After the reboot the Jetson shows a **text login** instead of the desktop. That's expected. Check the GPU:

```bash
nvidia-smi
/usr/local/cuda/bin/nvcc --version              # CUDA 13.x
```

Next: [Part 2 — Connect the nodes](../part2-network/README.md)
