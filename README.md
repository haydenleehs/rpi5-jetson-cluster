# rpi5-jetson-cluster

A two-node mini HPC cluster: a **Raspberry Pi 5** as the login node and an **NVIDIA Jetson Orin Nano** as a GPU compute node, scheduled with **Slurm**.

It follows the same staged approach as the [Raspberry Pi 4B cluster](https://github.com/haydenleehs/RaspberryPi_cluster) and reuses workloads from [picluster](https://github.com/haydenleehs/picluster).

```
   Laptop (Windows)
        │  SSH over Tailscale (from anywhere)
        ▼
┌──────────────────────┐   wlan0 ── internet (home Wi-Fi / hotspot)
│  rpi5-login          │
│  Raspberry Pi 5      │   slurmctld · NFS server · NAT gateway
│  Ubuntu Server 24.04 │
└─────────┬────────────┘
          │ eth0  10.0.0.1/24
          │ (direct Ethernet cable)
          │ 10.0.0.11/24
┌─────────┴────────────┐
│  orin-node01         │
│  Jetson Orin Nano    │   slurmd · 6 CPU cores · Ampere GPU (CUDA 13)
│  JetPack 7.2.1       │
└──────────────────────┘
```

## Why these OS versions

Slurm only works when controller and node versions are close. **Both nodes run Ubuntu 24.04**, so `apt` gives them identical versions of everything:

| | rpi5-login | orin-node01 |
|---|---|---|
| OS | Ubuntu Server 24.04 LTS | JetPack 7.2.1 (Jetson Linux r39.2.1, Ubuntu 24.04) |
| Slurm | 23.11.x | 23.11.x |
| OpenMPI / Python | same apt versions | same apt versions |

> ⚠️ Don't use JetPack 6.x on the Jetson. It is Ubuntu 22.04 with Slurm 21.08, which is too old for the Pi's Slurm 23.11 controller.

## Guide

Each Part ends with a ✅ checkpoint. Don't move on until every box is ticked.

### [Part 1 — Get both boards running](docs/part1-setup/README.md)
| Stage | Result |
|---|---|
| 0 · [Hardware](docs/part1-setup/stage0-hardware.md) | Parts list |
| 1 · [Flash & access the Pi 5](docs/part1-setup/stage1-pi5.md) | Pi online, SSH from Windows, Wi-Fi, Tailscale |
| 2 · [Flash the Jetson](docs/part1-setup/stage2-jetson.md) | JetPack 7.2.1 on NVMe, all packages installed |

### [Part 2 — Connect the nodes](docs/part2-network/README.md)
| Stage | Result |
|---|---|
| 3 · [Cluster network](docs/part2-network/stage3-network.md) | Private 10.0.0.0/24 link, Pi shares internet |
| 4 · [SSH keys & users](docs/part2-network/stage4-ssh-users.md) | Passwordless SSH, matching UIDs |

### [Part 3 — Slurm](docs/part3-slurm/README.md)
| Stage | Result |
|---|---|
| 5 · [MUNGE & Slurm](docs/part3-slurm/stage5-munge-slurm.md) | `sinfo` shows the Jetson idle, GPU schedulable |

### [Part 4 — Shared storage & workloads](docs/part4-storage-workloads/README.md)
| Stage | Result |
|---|---|
| 6 · [NFS `/clusterfs`](docs/part4-storage-workloads/stage6-nfs.md) | Shared folder on both nodes |
| 7 · [Workloads](docs/part4-storage-workloads/stage7-workloads.md) | MPI (CPU) and CUDA (GPU) Monte Carlo π jobs |

**[Troubleshooting](docs/troubleshooting.md)**: Wi-Fi, SSH, Slurm and NFS fixes, including problems hit during this build.

## Names used throughout

| Item | Value |
|---|---|
| Username (same on both nodes) | `leecluster` |
| Login node | `rpi5-login`, `10.0.0.1` |
| Compute node | `orin-node01`, `10.0.0.11` |
| Slurm cluster / partition | `orincluster` / `jetson` |
| Shared folder | `/clusterfs` |

## Repo layout

```
configs/
  pi5/        netplan + NFS exports for the login node
  jetson/     gres.conf
  slurm.conf  identical on both nodes
workloads/    mc_pi.py (MPI), mc_pi_gpu.cu (CUDA), sbatch scripts
docs/
  part1-setup/               Stages 0–2
  part2-network/             Stages 3–4
  part3-slurm/               Stage 5
  part4-storage-workloads/   Stages 6–7
  troubleshooting.md
```

## Quick reference

```bash
sinfo                                 # node state
squeue                                # running/queued jobs
sbatch workloads/mc_pi_cpu.sbatch     # submit CPU job
sbatch workloads/mc_pi_gpu.sbatch     # submit GPU job
srun --gres=gpu:1 nvidia-smi          # quick GPU check
ssh -J leecluster@rpi5-login leecluster@10.0.0.11   # reach the Jetson from the laptop
```

> 🔒 This repo is public. Config files use placeholders like `YOUR_WIFI_PASSWORD`. Never commit real passwords or `munge.key`.
