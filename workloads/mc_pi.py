"""Monte Carlo estimate of pi, parallelised with MPI (mpi4py + NumPy).

Usage:  mpirun -np 6 python3 mc_pi.py [total_samples]
"""
import sys

import numpy as np
from mpi4py import MPI

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()

total = int(sys.argv[1]) if len(sys.argv) > 1 else 60_000_000
n_local = total // size
rng = np.random.default_rng(seed=12345 + rank)

comm.Barrier()
t0 = MPI.Wtime()

hits = 0
remaining = n_local
chunk = 1_000_000  # keeps memory use small
while remaining > 0:
    m = min(chunk, remaining)
    x = rng.random(m)
    y = rng.random(m)
    hits += int(np.count_nonzero(x * x + y * y <= 1.0))
    remaining -= m

total_hits = comm.reduce(hits, op=MPI.SUM, root=0)
elapsed = MPI.Wtime() - t0

if rank == 0:
    used = n_local * size
    print(
        f"ranks={size} samples={used} pi={4.0 * total_hits / used:.8f} "
        f"time={elapsed:.3f}s host={MPI.Get_processor_name()}"
    )
