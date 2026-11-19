#!/bin/bash
#SBATCH --job-name=mc-pi-cpu
#SBATCH --partition=jetson
#SBATCH --nodes=1
#SBATCH --ntasks=6
#SBATCH --mem=2G
#SBATCH --output=mc-pi-cpu-%j.out

# Submit from the workloads folder on /clusterfs: sbatch mc_pi_cpu.sbatch
cd "$SLURM_SUBMIT_DIR"
mpirun -np "$SLURM_NTASKS" python3 mc_pi.py 60000000
