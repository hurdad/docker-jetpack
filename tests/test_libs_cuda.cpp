#include <iostream>
#include <cassert>

#include <arrow/api.h>
#include <arrow/gpu/cuda_api.h>

#define PASS(name) std::cout << "  PASS  " << name << "\n"
#define FAIL(name, msg) std::cout << "  FAIL  " << name << ": " << msg << "\n"; failed++

int main() {
    int failed = 0;
    int total = 1;

    // Arrow CUDA: initialise CUDA memory manager
    try {
        auto mgr = arrow::cuda::CudaDeviceManager::Instance();
        assert(mgr.ok());
        assert(mgr.ValueOrDie()->num_devices() > 0);
        PASS("arrow_cuda_manager");
    } catch (const std::exception& e) { FAIL("arrow_cuda_manager", e.what()); }

    std::cout << "\n" << (total - failed) << "/" << total << " tests passed\n";
    return failed;
}
