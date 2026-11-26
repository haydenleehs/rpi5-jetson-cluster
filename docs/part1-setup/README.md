# Part 1 — Get both boards running

Flash each board, get it online, and install every package the cluster needs **while each board still has its own internet**.

| Stage | Guide | Time |
|---|---|---|
| 0 | [Hardware](stage0-hardware.md) | 5 min |
| 1 | [Flash & access the Pi 5](stage1-pi5.md): Ubuntu Server, SSH from Windows, Wi-Fi, Tailscale | 45 min |
| 2 | [Flash the Jetson](stage2-jetson.md): firmware check, JetPack 7.2.1 ISO, packages | 60–90 min |

## ✅ Checkpoint: before Part 2

**Pi 5 (`rpi5-login`)**

- [ ] `lsb_release -a` → Ubuntu 24.04
- [ ] `id` → `uid=1000(leecluster)`
- [ ] `ip -br addr show wlan0` → **UP with an IP** (Wi-Fi is the Pi's only internet after Part 2)
- [ ] `ssh leecluster@rpi5-login` works from the laptop over Tailscale
- [ ] `slurmctld -V` → slurm 23.11.x
- [ ] Repo cloned to `~/rpi5-jetson-cluster`

**Jetson (`orin-node01`)**

- [ ] `cat /etc/nv_tegra_release` → R39, REVISION 2.x
- [ ] `id` → `uid=1000(leecluster)` (pre-flashed board? see Stage 2.0b)
- [ ] `hostname` → `orin-node01`
- [ ] `timedatectl` → correct year, *synchronized: yes*
- [ ] `nvidia-smi` and `/usr/local/cuda/bin/nvcc --version` work
- [ ] `slurmd -V` → slurm 23.11.x
- [ ] Boots to text console (`multi-user.target`)

Start: [Stage 0 — Hardware](stage0-hardware.md)
