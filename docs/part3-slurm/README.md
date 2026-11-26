# Part 3 — Slurm

Share a MUNGE key so the nodes trust each other, then run the Slurm controller on the Pi and the compute daemon on the Jetson, with the GPU registered as a schedulable resource.

| Stage | Guide | Time |
|---|---|---|
| 5 | [MUNGE & Slurm](stage5-munge-slurm.md): munge key, `slurm.conf`, `gres.conf`, start daemons | 30 min |

## ✅ Checkpoint: before Part 4

- [ ] `munge -n | ssh orin-node01 unmunge` → `STATUS: Success (0)`, `UID: leecluster (1000)`
- [ ] `sinfo` → partition `jetson*`, node `orin-node01`, state **idle**
- [ ] `srun -n 6 hostname` → six lines of `orin-node01`
- [ ] `srun id` → includes `44(video)`
- [ ] `srun --gres=gpu:1 nvidia-smi` → GPU info printed

Start: [Stage 5 — MUNGE & Slurm](stage5-munge-slurm.md)
