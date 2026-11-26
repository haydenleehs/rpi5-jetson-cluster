# Part 3 · Stage 5 — MUNGE & Slurm

| Node | Runs |
|---|---|
| `rpi5-login` | `munge`, `slurmctld` (controller) |
| `orin-node01` | `munge`, `slurmd` (compute daemon) |

## 5.1 Check versions match

```bash
slurmctld -V                # Pi:     slurm 23.11.x
ssh orin-node01 slurmd -V   # Jetson: slurm 23.11.x
```

> Don't use `sinfo -V` yet. Before `slurm.conf` exists it fails with *"Could not establish a configuration source"*.

Not installed? Pi: `sudo apt install -y munge slurmctld slurm-client`. Jetson: `ssh -t orin-node01 'sudo apt install -y munge slurmd slurm-client'`. `slurmctld` may show *failed* right after install; that's normal until 5.6.

## 5.2 Share the MUNGE key

Both nodes need the **same** `/etc/munge/munge.key`.

```bash
# on the Pi
sudo install -m 600 -o $USER /etc/munge/munge.key /tmp/munge.key
ls -l /tmp/munge.key                       # exists, owned by leecluster
scp /tmp/munge.key orin-node01:/tmp/
ssh orin-node01 ls -l /tmp/munge.key       # arrived on the Jetson
rm /tmp/munge.key

ssh -t orin-node01 'sudo mv /tmp/munge.key /etc/munge/munge.key && \
  sudo chown munge:munge /etc/munge/munge.key && sudo chmod 400 /etc/munge/munge.key && \
  sudo systemctl restart munge'
```

No key on the Pi? `sudo mungekey --create && sudo systemctl restart munge`, then repeat.

Test from the Pi:

```bash
munge -n | ssh orin-node01 unmunge     # STATUS: Success (0)  and  UID: leecluster (1000)
```

`UID: ??? (1000)` means the Jetson has no user with UID 1000. Fix with [Stage 2.0b](../part1-setup/stage2-jetson.md#20b-rename-the-user-to-leecluster-with-uid-1000).

## 5.3 Get the Jetson's hardware values

```bash
ssh orin-node01 slurmd -C
# e.g. NodeName=orin-node01 CPUs=6 ... RealMemory=7481
```

Set `RealMemory` in `slurm.conf` **below** that value (e.g. 6500). The CPU and GPU share the same 8 GB.

## 5.4 slurm.conf (identical on both nodes)

Edit `RealMemory`/`CPUs` in [`configs/slurm.conf`](../../configs/slurm.conf) if `slurmd -C` differs, then install it on both nodes:

```bash
# on the Pi
sudo cp ~/rpi5-jetson-cluster/configs/slurm.conf /etc/slurm/slurm.conf
scp /etc/slurm/slurm.conf orin-node01:/tmp/
ssh -t orin-node01 'sudo mv /tmp/slurm.conf /etc/slurm/slurm.conf'
```

## 5.5 gres.conf (Jetson only)

Slurm **ignores a GPU entry that has no device file** (`slurmd -G` prints *"Ignoring file-less GPU"* and the node goes `inval`). Point it at the Jetson's GPU device:

```bash
ssh orin-node01 ls -l /dev/nvidia0        # JetPack 7.2: GPU device file
```

```bash
# on the Pi
scp ~/rpi5-jetson-cluster/configs/jetson/gres.conf orin-node01:/tmp/
ssh -t orin-node01 'sudo mv /tmp/gres.conf /etc/slurm/gres.conf'
ssh -t orin-node01 'sudo slurmd -G'       # should show Name=gpu ... File=/dev/nvidia0
```

It contains ([`configs/jetson/gres.conf`](../../configs/jetson/gres.conf)):

```
NodeName=orin-node01 Name=gpu File=/dev/nvidia0
```

> If `/dev/nvidia0` doesn't exist on your board, use `/dev/nvhost-gpu` instead.

## 5.6 Start the daemons

```bash
# Pi
sudo mkdir -p /var/spool/slurmctld /var/log/slurm
sudo chown slurm:slurm /var/spool/slurmctld /var/log/slurm
sudo systemctl enable --now slurmctld
sudo systemctl status slurmctld --no-pager
```

```bash
# Jetson
sudo mkdir -p /var/spool/slurmd /var/log/slurm
sudo chown slurm:slurm /var/log/slurm
sudo systemctl enable --now slurmd
sudo systemctl status slurmd --no-pager
```

## 5.7 Test (from the Pi)

```bash
sinfo                          # jetson* up ... idle orin-node01
srun hostname                  # orin-node01
srun -n 6 hostname             # 6 lines
srun id                        # groups include 44(video) and render (needed for the GPU)
srun --gres=gpu:1 nvidia-smi   # GPU visible through Slurm
```

The repo's `slurm.conf` has `LaunchParameters=disable_send_gids`. Without it, Slurm 23.11 gives jobs the **Pi's** group list, which lacks `video`, and GPU jobs fail with *"NvRmMemInitNvmap failed: Permission denied … No devices were found"*.

After any `slurm.conf` / `gres.conf` change: copy to the Jetson, restart **both** daemons, then
`sudo scontrol update nodename=orin-node01 state=resume`.

Node shows `down` or `unk`? See [Troubleshooting → Slurm](../troubleshooting.md#slurm).

Next: [Part 4 — Shared storage & workloads](../part4-storage-workloads/README.md)
