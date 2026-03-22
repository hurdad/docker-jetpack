#include <iostream>
#include <cassert>

// Arrow
#include <arrow/api.h>
#include <arrow/gpu/cuda_api.h>

// gRPC / Protobuf
#include <grpcpp/grpcpp.h>
#include <google/protobuf/descriptor.h>

// OpenTelemetry
#include <opentelemetry/sdk/trace/tracer_provider.h>

// FlatBuffers
#include <flatbuffers/flatbuffers.h>

// jemalloc
#include <jemalloc/jemalloc.h>

// nats.c
#include <nats/nats.h>

// nats-cpp
#include <nats-cpp/nats.hpp>

#define PASS(name) std::cout << "  PASS  " << name << "\n"
#define FAIL(name, msg) std::cout << "  FAIL  " << name << ": " << msg << "\n"; failed++

int main() {
    int failed = 0;
    int total = 8;

    // Arrow: build a simple int32 array
    try {
        arrow::Int32Builder builder;
        assert(builder.AppendValues({1, 2, 3, 4, 5}).ok());
        std::shared_ptr<arrow::Array> arr;
        assert(builder.Finish(&arr).ok());
        assert(arr->length() == 5);
        PASS("arrow_array");
    } catch (const std::exception& e) { FAIL("arrow_array", e.what()); }

    // Arrow CUDA: initialise CUDA memory manager (skipped if no GPU)
    try {
        auto mgr = arrow::cuda::CudaDeviceManager::Instance();
        if (mgr.ok() && mgr.ValueOrDie()->num_devices() > 0) {
            PASS("arrow_cuda_manager");
        } else {
            std::cout << "  SKIP  arrow_cuda_manager (no GPU)\n";
            total--;
        }
    } catch (const std::exception& e) { FAIL("arrow_cuda_manager", e.what()); }

    // gRPC: create a channel
    try {
        auto ch = grpc::CreateChannel("localhost:50051", grpc::InsecureChannelCredentials());
        assert(ch != nullptr);
        PASS("grpc_channel");
    } catch (const std::exception& e) { FAIL("grpc_channel", e.what()); }

    // Protobuf: descriptor pool lookup
    try {
        auto* pool = google::protobuf::DescriptorPool::generated_pool();
        assert(pool != nullptr);
        PASS("protobuf_pool");
    } catch (const std::exception& e) { FAIL("protobuf_pool", e.what()); }

    // FlatBuffers: builder
    try {
        flatbuffers::FlatBufferBuilder fbb;
        assert(fbb.GetSize() == 0);
        PASS("flatbuffers_builder");
    } catch (const std::exception& e) { FAIL("flatbuffers_builder", e.what()); }

    // jemalloc: allocate and free
    try {
        void* p = je_malloc(1024);
        assert(p != nullptr);
        je_free(p);
        PASS("jemalloc_alloc");
    } catch (const std::exception& e) { FAIL("jemalloc_alloc", e.what()); }

    // nats.c: library version
    try {
        const char* ver = nats_GetVersion();
        std::cout << "    nats.c version: " << ver << "\n";
        assert(nats_GetVersionNumber() >= 0x030C00); // >= 3.12.0
        PASS("natsc_version");
    } catch (const std::exception& e) { FAIL("natsc_version", e.what()); }

    // nats-cpp: default options instantiation
    try {
        nats::ConnectionOptions opts;
        PASS("natscpp_options");
    } catch (const std::exception& e) { FAIL("natscpp_options", e.what()); }

    std::cout << "\n" << (total - failed) << "/" << total << " tests passed\n";
    return failed;
}
