# Part 4 — Shared storage & workloads

Export `/clusterfs` from the Pi over NFS, then run real jobs: Monte Carlo π with MPI on the Jetson's 6 CPU cores and with CUDA on its GPU.

| Stage | Guide | Time |
|---|---|---|
| 6 | [NFS `/clusterfs`](stage6-nfs.md): shared folder on both nodes | 15 min |
| 7 | [Workloads](stage7-workloads.md): CPU (MPI) job, speed-up demo, GPU (CUDA) job | 20 min |

## ✅ Checkpoint: cluster complete

- [ ] `df -h /clusterfs` on the Jetson → `10.0.0.1:/clusterfs`
- [ ] `srun touch /clusterfs/x` → file owned by `leecluster`
- [ ] `sbatch mc_pi_cpu.sbatch` → output with `pi=3.14…` and `host=orin-node01`
- [ ] `sbatch speedup_cpu.sbatch` → time drops as ranks go 1 → 6
- [ ] `sbatch mc_pi_gpu.sbatch` → GPU result, much faster than CPU

Start: [Stage 6 — NFS /clusterfs](stage6-nfs.md)
