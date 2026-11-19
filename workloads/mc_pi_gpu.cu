// Monte Carlo estimate of pi on the Jetson GPU (CUDA).
// Build: nvcc -O3 -arch=sm_87 -o mc_pi_gpu mc_pi_gpu.cu
// Run:   ./mc_pi_gpu [total_samples]
#include <cstdio>
#include <cstdlib>
#include <curand_kernel.h>

#define CHECK(call)                                                        \
    do {                                                                   \
        cudaError_t err = (call);                                          \
        if (err != cudaSuccess) {                                          \
            fprintf(stderr, "CUDA error %s at %s:%d\n",                    \
                    cudaGetErrorString(err), __FILE__, __LINE__);          \
            return 1;                                                      \
        }                                                                  \
    } while (0)

__global__ void mc_pi(unsigned long long n_per_thread, unsigned long long seed,
                      unsigned long long *hits) {
    unsigned long long id = blockIdx.x * (unsigned long long)blockDim.x + threadIdx.x;
    curandStatePhilox4_32_10_t state;
    curand_init(seed, id, 0, &state);

    unsigned long long local = 0;
    for (unsigned long long i = 0; i < n_per_thread; i++) {
        float x = curand_uniform(&state);
        float y = curand_uniform(&state);
        if (x * x + y * y <= 1.0f) local++;
    }
    atomicAdd(hits, local);
}

int main(int argc, char **argv) {
    unsigned long long total = argc > 1 ? strtoull(argv[1], NULL, 10) : 1000000000ULL;
    const int threads = 256;
    const int blocks = 1024;
    const unsigned long long n_threads = (unsigned long long)threads * blocks;
    unsigned long long n_per_thread = total / n_threads;
    if (n_per_thread == 0) n_per_thread = 1;

    unsigned long long *d_hits;
    unsigned long long h_hits = 0;
    CHECK(cudaMalloc(&d_hits, sizeof(unsigned long long)));
    CHECK(cudaMemset(d_hits, 0, sizeof(unsigned long long)));

    cudaEvent_t start, stop;
    CHECK(cudaEventCreate(&start));
    CHECK(cudaEventCreate(&stop));

    CHECK(cudaEventRecord(start));
    mc_pi<<<blocks, threads>>>(n_per_thread, 12345ULL, d_hits);
    CHECK(cudaGetLastError());
    CHECK(cudaEventRecord(stop));
    CHECK(cudaEventSynchronize(stop));

    float ms = 0.0f;
    CHECK(cudaEventElapsedTime(&ms, start, stop));
    CHECK(cudaMemcpy(&h_hits, d_hits, sizeof(unsigned long long), cudaMemcpyDeviceToHost));

    unsigned long long used = n_per_thread * n_threads;
    printf("samples=%llu pi=%.8f gpu_time=%.3fs\n", used, 4.0 * (double)h_hits / used, ms / 1000.0);

    cudaFree(d_hits);
    return 0;
}
