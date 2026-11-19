#!/bin/bash
#SBATCH --job-name=speedup
#SBATCH --partition=jetson
#SBATCH --nodes=1
#SBATCH --ntasks=6
#SBATCH --mem=2G
#SBATCH --output=speedup-%j.out

# Same problem size on 1, 2, 4 and 6 cores to show strong scaling.
cd "$SLURM_SUBMIT_DIR"
SAMPLES=60000000
for n in 1 2 4 6; do
    mpirun -np "$n" python3 mc_pi.py "$SAMPLES"
done
