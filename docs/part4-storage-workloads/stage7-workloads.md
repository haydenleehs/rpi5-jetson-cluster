# Part 4 · Stage 7 — Workloads: Monte Carlo π on CPU (MPI) and GPU (CUDA)

The same problem, estimating π by throwing random points at a square, runs two ways so you can compare the Jetson's **6 CPU cores** against its **GPU**.

## 7.1 Get the files onto the cluster

```bash
# on the Pi
cd /clusterfs
git clone https://github.com/haydenleehs/rpi5-jetson-cluster.git
cd rpi5-jetson-cluster/workloads
```

## 7.2 CPU — MPI + Python

[`mc_pi.py`](../../workloads/mc_pi.py) splits the samples across MPI ranks and reduces the hit count on rank 0.

```bash
sbatch mc_pi_cpu.sbatch
squeue
cat mc-pi-cpu-*.out
# ranks=6 samples=60000000 pi=3.1415... time=...s host=orin-node01
```

### Speed-up demo (1 → 6 cores)

```bash
sbatch speedup_cpu.sbatch
cat speedup-*.out
```

## 7.3 GPU — CUDA

[`mc_pi_gpu.cu`](../../workloads/mc_pi_gpu.cu) runs the same estimate across ~260k GPU threads.

```bash
sbatch mc_pi_gpu.sbatch       # compiles with nvcc on the Jetson, then runs
cat mc-pi-gpu-*.out
# samples=... pi=3.1415... gpu_time=...s
```

The Orin Nano GPU is compute capability **8.7**, so the script compiles with `-arch=sm_87`.

## 7.4 Reuse picluster workloads

Workloads from [picluster](https://github.com/haydenleehs/picluster) (e.g. `aero_turb`) run the same way: clone into `/clusterfs`, then submit with `#SBATCH -p jetson`. With one compute node, keep `-N 1` and set `-n` up to 6.

## 7.5 Watch the node while a job runs

```bash
ssh orin-node01 tegrastats      # CPU %, GPU %, RAM, power. Ctrl+C to stop
```
