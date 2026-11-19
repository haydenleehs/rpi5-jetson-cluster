# Part 1 · Stage 1 — Flash & access the Pi 5

## 1.1 Flash Ubuntu Server

In **Raspberry Pi Imager**:

1. Device: **Raspberry Pi 5**
2. OS: *Other general-purpose OS → Ubuntu → **Ubuntu Server 24.04 LTS (64-bit)***
3. Storage: the microSD card
4. **Edit settings (OS customisation): yes, customise.**

| Setting | Value |
|---|---|
| Hostname | `rpi5-login` |
| Username / password | `leecluster` / your password, **the same username you'll use on the Jetson** |
| Wi-Fi | Home Wi-Fi or phone hotspot (WPA2-Personal). Imager can't do eduroam |
| Wireless LAN country | `SG` |
| Locale / time zone | `Asia/Singapore` |
| Services | Enable SSH (password auth) |

> Why the same username? The first user on each board gets UID 1000. Slurm runs your job on the Jetson as the same UID, and NFS file ownership is by UID. If they don't match, jobs fail or you get "permission denied" on `/clusterfs`.
>
> If you skip customisation, Ubuntu's default login is `ubuntu` / `ubuntu`.

## 1.2 First boot

Insert the card, power on, and wait **2–3 minutes**. cloud-init applies your user, Wi-Fi and SSH settings on first boot.

## 1.3 Connect from a Windows laptop

Windows 10/11 has `ssh` built in. Open **PowerShell** or **Terminal**.

> `rpi5-login.local` usually **won't** resolve yet, because Ubuntu Server doesn't ship `avahi-daemon`. Use the IP address (or install avahi, see 1.6).

### Option A — Same Wi-Fi / hotspot

Find the Pi's IP:

- With a monitor on the Pi: `ip -br addr` → IP on the `wlan0` line
- From the laptop: `arp -a` → look for a MAC starting `2c-cf-67` or `d8-3a-dd` (Raspberry Pi)

```powershell
ssh leecluster@<PI_IP>
```

### Option B — Laptop Ethernet cable (Windows ICS)

The laptop gives the Pi an IP **and shares its own internet**, which also works when the laptop is on eduroam.

1. Cable laptop ↔ Pi `eth0` (USB-Ethernet adapter if the laptop has no port).
2. `Win + R` → `ncpa.cpl` → right-click **Wi-Fi** → *Properties* → **Sharing** tab.
3. Tick **Allow other network users to connect through this computer's Internet connection** and choose your **Ethernet** adapter. OK.
4. The laptop's Ethernet becomes `192.168.137.1`. Find the Pi:

```powershell
arp -a -N 192.168.137.1      # ignore .255 and 224.x / 239.x entries
ssh leecluster@192.168.137.x
```

> The Pi 5 has one Ethernet port and it goes to the Jetson in Stage 3. Use Option B for Stages 1–2, then switch to Wi-Fi + Tailscale.

First connection asks *"Are you sure…?"* → type `yes`. Password typing is invisible, which is normal.

## 1.4 Check the network

```bash
ip -br addr          # interfaces: UP + an IP = working
networkctl           # routable = fully working, degraded = no proper IP
ping -c 3 8.8.8.8    # internet
ping -c 3 google.com # DNS
```

Example of a working Pi on the laptop cable:

```
eth0        UP       192.168.137.160/24
wlan0       DOWN                          ← Wi-Fi not connected yet
tailscale0  UNKNOWN  100.x.y.z/32
```

If `wlan0` is `DOWN`, fix Wi-Fi now while the cable gives you internet (1.5).

## 1.5 Configure Wi-Fi (netplan)

From Stage 3 onward the Pi's internet is **Wi-Fi only**, so this must work. Do it over the laptop cable or with a monitor attached, not over Wi-Fi SSH.

**1. Stop cloud-init from rewriting network files and `/etc/hosts` on every boot**, since it has done its job:

```bash
sudo touch /etc/cloud/cloud-init.disabled
```

**2. See which networks the Pi can actually see**:

```bash
sudo apt install -y iw
sudo iw reg get | head -3                       # should say: country SG
sudo iw dev wlan0 scan | grep -E "freq:|SSID:"  # visible networks
```

Pick an SSID **from that list**. 2.4 GHz (`freq: 24xx`) or a phone hotspot is the most reliable.

**3. Edit netplan.** See [`configs/pi5/50-cloud-init.yaml`](../../configs/pi5/50-cloud-init.yaml) for a full example.

```bash
sudo nano /etc/netplan/50-cloud-init.yaml
```

```yaml
network:
  version: 2
  ethernets:
    eth0:
      optional: true
      dhcp4: true
  wifis:
    wlan0:
      optional: true
      dhcp4: true
      regulatory-domain: "SG"
      access-points:
        "YOUR_SSID":
          auth:
            key-management: "psk"
            password: "YOUR_WIFI_PASSWORD"
```

YAML needs **spaces, not tabs**. You can list several access points and netplan joins whichever is in range.

**4. Apply safely:**

```bash
sudo chmod 600 /etc/netplan/*.yaml
sudo netplan try           # auto-reverts after 120 s unless you press Enter
ip -br addr show wlan0     # UP + IP?
iw dev wlan0 link          # which SSID it joined
```

Not working? See [Troubleshooting → Wi-Fi](../troubleshooting.md#wi-fi-wlan0-down).

## 1.6 Update + login-node packages

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y munge slurmctld slurm-client nfs-kernel-server \
  openmpi-bin libopenmpi-dev python3-mpi4py python3-numpy \
  iptables-persistent git avahi-daemon iw
sudo timedatectl set-timezone Asia/Singapore
sudo reboot
```

Clone this repo onto the Pi. Later stages copy config files straight from it:

```bash
git clone https://github.com/haydenleehs/rpi5-jetson-cluster.git ~/rpi5-jetson-cluster
```

When `iptables-persistent` asks to save current rules, answer **Yes** (you'll save again in Stage 3).
With `avahi-daemon` installed, `ssh leecluster@rpi5-login.local` works on the same LAN.

## 1.7 Tailscale (SSH from any network)

Tailscale puts the laptop and Pi on a private network that works wherever each one is.

**Pi** (do this over the laptop cable or a hotspot, because installs have timed out on eduroam before):

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --ssh      # open the printed link and sign in
tailscale ip -4              # 100.x.y.z
```

**Laptop:** install the Tailscale app from <https://tailscale.com/download> and sign in with the **same account**.

```powershell
ssh leecluster@rpi5-login        # or ssh leecluster@100.x.y.z
```

Recommended settings in the admin console (<https://login.tailscale.com>):

- Pi → **⋯ → Disable key expiry**. Otherwise it silently drops off after about 6 months.
- No app on a computer? Pi → **⋯ → SSH to machine** gives a browser terminal (needs `--ssh` above).

Next: [Stage 2 — Flash the Jetson](../part1-setup/stage2-jetson.md)
