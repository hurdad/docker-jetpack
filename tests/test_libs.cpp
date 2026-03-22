#include <iostream>
#include <cassert>
#include <string>

// Arrow
#include <arrow/api.h>
#include <arrow/gpu/cuda_api.h>
#include <arrow/io/api.h>
#include <parquet/arrow/writer.h>
#include <parquet/arrow/reader.h>

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

    // Arrow: build a simple int32 array
    try {
        arrow::Int32Builder builder;
        assert(builder.AppendValues({1, 2, 3, 4, 5}).ok());
        std::shared_ptr<arrow::Array> arr;
        assert(builder.Finish(&arr).ok());
        assert(arr->length() == 5);
        PASS("arrow_array");
    } catch (const std::exception& e) { FAIL("arrow_array", e.what()); }

    // Arrow CUDA: initialise CUDA memory manager
    try {
        auto mgr = arrow::cuda::CudaDeviceManager::Instance();
        assert(mgr.ok());
        PASS("arrow_cuda_manager");
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
        int major = 0, minor = 0, patch = 0;
        natsLib_Version(&major, &minor, &patch);
        std::string ver = std::to_string(major) + "." + std::to_string(minor) + "." + std::to_string(patch);
        std::cout << "    nats.c version: " << ver << "\n";
        assert(major >= 3);
        PASS("natsc_version");
    } catch (const std::exception& e) { FAIL("natsc_version", e.what()); }

    // nats-cpp: default options instantiation
    try {
        nats::ConnectionOptions opts;
        PASS("natscpp_options");
    } catch (const std::exception& e) { FAIL("natscpp_options", e.what()); }

    int total = 8;
    std::cout << "\n" << (total - failed) << "/" << total << " tests passed\n";
    return failed;
}
