# Troubleshooting

## Network checks

```bash
ip -br addr        # UP + IP = working; UP without IP = no address; DOWN = not connected
networkctl         # routable = OK, degraded = no proper IP, no-carrier = unplugged
ping -c 3 8.8.8.8  # internet
ping -c 3 google.com   # DNS (if 8.8.8.8 works but this fails, DNS is the problem)
iw dev wlan0 link  # which Wi-Fi SSID is connected
```

## Wi-Fi: wlan0 DOWN

**Step 1: what's going on?**

```bash
rfkill list                                           # Soft/Hard blocked?
sudo ip link set wlan0 up
sudo iw dev wlan0 scan | grep -E "freq:|SSID:"        # what the Pi can see (sudo apt install iw)
sudo journalctl -u netplan-wpa-wlan0 -n 30 --no-pager
```

**Step 2: match the symptom**

| Symptom | Cause | Fix |
|---|---|---|
| `Soft blocked: yes` | Radio off | `sudo rfkill unblock wifi && sudo netplan apply` |
| Log repeats `Failed to initiate sched scan` | Pi **can't find** the SSID (the password hasn't been tried yet) | Check the scan list. Use an SSID that appears there |
| SSID missing from scan | 5 GHz channel the Pi can't use, wrong region, or hidden network | Use 2.4 GHz or 5 GHz channel 36–48; check `iw reg get` says `SG`; hidden → add `hidden: true` under the SSID |
| `iw reg get` shows `country 00` | Region not applied | `sudo sed -i 's/$/ cfg80211.ieee80211_regdom=SG/' /boot/firmware/cmdline.txt && sudo reboot` |
| `WRONG_KEY` / `4-Way Handshake failed` | Wrong password, or router is WPA3-only | Retype password; set the router to WPA2/WPA3 mixed |
| `No such unit netplan-wpa-wlan0` | netplan never started Wi-Fi | Check YAML indentation (spaces only), `sudo netplan apply` |

**Switching SSID:** edit the `access-points:` entry in `/etc/netplan/50-cloud-init.yaml`, then `sudo netplan try`.

**eduroam (WPA2-Enterprise):** Raspberry Pi Imager can't set it up. Add it in netplan:

```yaml
        "eduroam":
          auth:
            key-management: eap
            method: peap
            phase2-auth: MSCHAPV2
            identity: "YOUR_EDUROAM_LOGIN"
            password: "YOUR_EDUROAM_PASSWORD"
```

> Passwords sit in plain text in netplan files. Keep them `chmod 600` and **never commit the real file**.

## Jetson setup

| Symptom | Fix |
|---|---|
| `apt update`: *"Release file … is not valid yet (invalid for another 20783d)"*, *"certificate … not yet valid"* | Clock is in the wrong year. See [Stage 2.0a](part1-setup/stage2-jetson.md#20a-fix-the-clock-pre-flashed-boards-often-boot-in-the-wrong-year), then `sudo hwclock -w` |
| Pre-flashed board: user `jetson`, hostname `localhost.localdomain` | Rename to `leecluster` / UID 1000 and set the hostname. See [Stage 2.0b/2.0c](part1-setup/stage2-jetson.md#20b-rename-the-user-to-leecluster-with-uid-1000) |
| `usermod: user … is currently used by process …` | You're logged in as that user somewhere (desktop/SSH). `sudo systemctl isolate multi-user.target && sudo pkill -9 -u <user>` from the temp admin |
| Temp admin got UID/GID 1000 and blocks the change | Recreate it with a fixed ID: `groupadd -g 1500 tempfix && useradd -m -u 1500 -g 1500 -G sudo tempfix` |
| Login screen still shows the old name | Display name only: `sudo chfn -f "leecluster" leecluster` |
| Number keys type letters on one keyboard | Keyboard's Fn/Num-Lock layer or Win/Mac mode, not the Jetson. Use another keyboard or toggle Fn-lock/Num Lock |

## Pi setup

| Symptom | Fix |
|---|---|
| `/etc/hosts` changes disappear after reboot | cloud-init `manage_etc_hosts`. Run `sudo touch /etc/cloud/cloud-init.disabled` and re-edit |
| `sudo netfilter-persistent save`: *command not found* | `sudo apt install -y iptables-persistent` (answer **Yes** to save IPv4 rules) |
| `cp: … rpi5-jetson-cluster/configs/…: No such file` | Repo not cloned: `git clone https://github.com/haydenleehs/rpi5-jetson-cluster.git ~/rpi5-jetson-cluster` |

## SSH

| Problem | Fix |
|---|---|
| `rpi5-login.local` not found | `sudo apt install avahi-daemon` on the Pi, or use the IP / Tailscale name |
| `REMOTE HOST IDENTIFICATION HAS CHANGED` after reflashing | `ssh-keygen -R <host-or-ip>` on the laptop |
| Can't find Pi's IP on hotspot | `arp -a`, look for MAC `2c-cf-67-…` or `d8-3a-dd-…` |
| Tailscale install times out on eduroam | Install over hotspot or laptop ICS; it usually runs fine on eduroam afterwards |
| `ssh-copy-id orin-node01`: *Could not resolve hostname* | `/etc/hosts` on the **Pi** is missing the cluster lines (Stage 3.4) |
| Need to reach the Jetson before it has 10.0.0.11 | From the Pi: `ssh leecluster@orin-node01.local`, or `ping -6 -c 2 ff02::1%eth0` then `ssh leecluster@fe80::…%eth0` |
| SSH froze at `nmcli con up cluster` | Expected. Reconnect with `ssh leecluster@10.0.0.11` |
| Asked for the sudo password on every `ssh -t` | Normal (new terminal each time). Optional passwordless sudo: Stage 4.1 |

## Slurm

```bash
sinfo -R                                       # reason a node is down
sudo tail -n 30 /var/log/slurm/slurmctld.log   # Pi
ssh orin-node01 sudo tail -n 30 /var/log/slurm/slurmd.log
```

| Symptom | Fix |
|---|---|
| `sinfo -V`: *"Could not establish a configuration source"* | No `slurm.conf` yet. Use `slurmctld -V` / `slurmd -V` to check versions |
| `squeue` shows `(InvalidAccount)` | Cosmetic with accounting off. The job starts within ~30 s. Check `scontrol show job <id> \| grep JobState` |
| `munge … unmunge` shows `UID: ??? (1000)` | The Jetson has no UID-1000 user. Fix the UID ([Stage 2.0b](part1-setup/stage2-jetson.md#20b-rename-the-user-to-leecluster-with-uid-1000)) |
| `mv: cannot stat '/tmp/munge.key'` on the Jetson | The `scp` never ran or failed. Redo 5.2 and check with `ssh orin-node01 ls -l /tmp/munge.key` |
| Node `down` / `not responding` | Check `munge -n \| ssh orin-node01 unmunge`, clocks (`timedatectl`), identical `slurm.conf`, then `sudo scontrol update nodename=orin-node01 state=resume` |
| `Protocol version` / authentication errors | Versions differ. Both must be 23.11.x (Ubuntu 24.04 on both) |
| Node `inval` | `CPUs`/`RealMemory` in `slurm.conf` higher than `slurmd -C` reports. Lower them, copy to both nodes, restart daemons |
| `Invalid generic resource (gres) specification` | `gres.conf` missing on the Jetson, or `GresTypes=gpu` missing in `slurm.conf` |
| Node `inval`, `sinfo -R` says `gres/gpu count reported lower` | `gres.conf` has no `File=`. Slurm ignores file-less GPUs (`slurmd -G` → *Ignoring file-less GPU*). Use `File=/dev/nvidia0`, restart slurmd, then `scontrol update nodename=orin-node01 state=resume` |
| GPU job fails: `NvRmMemInitNvmap failed: Permission denied`, `No devices were found` | Job ran without the Jetson's `video`/`render` groups (Slurm 23.11 sends the controller's group list). Add `LaunchParameters=disable_send_gids` to `slurm.conf` on both nodes, restart both daemons. Check with `srun id` |
| `sudo: a terminal is required` over SSH | Use `ssh -t orin-node01 'sudo …'` |
| Jetson `id` shows a UID other than 1000 | Change it from a temporary admin with a fixed UID (e.g. 1500): `groupmod -g 1000 leecluster && usermod -u 1000 -g 1000 leecluster`, then chown leftover files |
| Job fails with permission/user errors | `leecluster` UID differs between nodes (`id` on both) |
| After editing `slurm.conf` | Copy to both nodes, then `sudo systemctl restart slurmctld` (Pi) and `slurmd` (Jetson) |

## NFS

| Symptom | Fix |
|---|---|
| `mount.nfs: access denied` | `/etc/exports` subnet must be `10.0.0.0/24`; `sudo exportfs -ra` |
| Hangs at boot on the Jetson | Ensure `_netdev` in fstab; check cable/`ping rpi5-login` |
| Files owned by `nobody` | UID mismatch, see Stage 4.2 |
