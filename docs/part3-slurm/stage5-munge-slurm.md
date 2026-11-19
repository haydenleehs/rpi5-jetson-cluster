# Part 3 · Stage 5 — MUNGE & Slurm

| Node | Runs |
|---|---|
| `rpi5-login` | `munge`, `slurmctld` (controller) |
| `orin-node01` | `munge`, `slurmd` (compute daemon) |

## 5.1 Check versions match

```bash
sinfo -V                    # Pi:     slurm 23.11.x
ssh orin-node01 slurmd -V   # Jetson: slurm 23.11.x
```

## 5.2 Share the MUNGE key

Both nodes need the **same** `/etc/munge/munge.key`.

```bash
# on the Pi
sudo install -m 600 -o $USER /etc/munge/munge.key /tmp/munge.key
scp /tmp/munge.key orin-node01:/tmp/
rm /tmp/munge.key
```

```bash
# on the Jetson
sudo mv /tmp/munge.key /etc/munge/munge.key
sudo chown munge:munge /etc/munge/munge.key
sudo chmod 400 /etc/munge/munge.key
sudo systemctl restart munge
```

Test from the Pi:

```bash
munge -n | ssh orin-node01 unmunge     # STATUS: Success (0)
```

## 5.3 Get the Jetson's hardware values

```bash
ssh orin-node01 slurmd -C
# e.g. NodeName=orin-node01 CPUs=6 ... RealMemory=7620
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

```bash
# on the Pi
scp ~/rpi5-jetson-cluster/configs/jetson/gres.conf orin-node01:/tmp/
ssh -t orin-node01 'sudo mv /tmp/gres.conf /etc/slurm/gres.conf'
```

It contains ([`configs/jetson/gres.conf`](../../configs/jetson/gres.conf)):

```
NodeName=orin-node01 Name=gpu Count=1
```

> This makes Slurm *count* the GPU so jobs can request `--gres=gpu:1`. It doesn't isolate the device, which is fine with one node.

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
srun --gres=gpu:1 nvidia-smi   # GPU visible through Slurm
```

Node shows `down` or `unk`? See [Troubleshooting → Slurm](../troubleshooting.md#slurm).

Next: [Part 4 — Shared storage & workloads](../part4-storage-workloads/README.md)
