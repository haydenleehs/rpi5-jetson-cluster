#!/bin/bash
#SBATCH --job-name=mc-pi-gpu
#SBATCH --partition=jetson
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gres=gpu:1
#SBATCH --mem=2G
#SBATCH --output=mc-pi-gpu-%j.out

# Compiles on the Jetson (Orin GPU = sm_87), then runs.
cd "$SLURM_SUBMIT_DIR"
export PATH=/usr/local/cuda/bin:$PATH

nvcc -O3 -arch=sm_87 -o mc_pi_gpu mc_pi_gpu.cu || exit 1
./mc_pi_gpu 1000000000
./mc_pi_gpu 10000000000
