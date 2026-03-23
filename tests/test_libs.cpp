#include <iostream>
#include <cassert>

// Arrow
#include <arrow/api.h>

// gRPC / Protobuf
#include <grpcpp/grpcpp.h>
#include <google/protobuf/descriptor.h>

// OpenTelemetry
#include <opentelemetry/sdk/trace/tracer_provider_factory.h>
#include <opentelemetry/sdk/metrics/meter_provider_factory.h>
#include <opentelemetry/sdk/logs/logger_provider_factory.h>

// FlatBuffers
#include <flatbuffers/flatbuffers.h>

// jemalloc
#include <jemalloc/jemalloc.h>

// nats.c
#include <nats/nats.h>

// nats-cpp
#include <natscpp/natscpp.hpp>

#define PASS(name) std::cout << "  PASS  " << name << "\n"
#define FAIL(name, msg) std::cout << "  FAIL  " << name << ": " << msg << "\n"; failed++

int main() {
    int failed = 0;
    int total = 10;

    // Arrow: build a simple int32 array
    try {
        arrow::Int32Builder builder;
        assert(builder.AppendValues({1, 2, 3, 4, 5}).ok());
        std::shared_ptr<arrow::Array> arr;
        assert(builder.Finish(&arr).ok());
        assert(arr->length() == 5);
        PASS("arrow_array");
    } catch (const std::exception& e) { FAIL("arrow_array", e.what()); }

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

    // jemalloc: allocate via malloc (jemalloc is LD_PRELOADed); verify active via mallctl
    try {
        void* p = malloc(1024);
        assert(p != nullptr);
        free(p);
        size_t epoch = 1;
        size_t sz = sizeof(epoch);
        int ret = mallctl("epoch", &epoch, &sz, &epoch, sz);
        assert(ret == 0);
        PASS("jemalloc_alloc");
    } catch (const std::exception& e) { FAIL("jemalloc_alloc", e.what()); }

    // nats.c: library version and compatibility
    try {
        const char* ver = nats_GetVersion();
        std::cout << "    nats.c version: " << ver << "\n";
        assert(nats_GetVersionNumber() >= 0x030C00); // >= 3.12.0
        assert(nats_CheckCompatibility() == NATS_OK);
        PASS("natsc_version");
    } catch (const std::exception& e) { FAIL("natsc_version", e.what()); }

    // nats-cpp: default options instantiation
    try {
        natscpp::connection_options opts;
        PASS("natscpp_options");
    } catch (const std::exception& e) { FAIL("natscpp_options", e.what()); }

    // OpenTelemetry: tracer provider
    try {
        auto provider = opentelemetry::sdk::trace::TracerProviderFactory::Create();
        assert(provider != nullptr);
        PASS("otel_tracer_provider");
    } catch (const std::exception& e) { FAIL("otel_tracer_provider", e.what()); }

    // OpenTelemetry: meter provider
    try {
        auto provider = opentelemetry::sdk::metrics::MeterProviderFactory::Create();
        assert(provider != nullptr);
        PASS("otel_meter_provider");
    } catch (const std::exception& e) { FAIL("otel_meter_provider", e.what()); }

    // OpenTelemetry: logger provider
    try {
        auto provider = opentelemetry::sdk::logs::LoggerProviderFactory::Create();
        assert(provider != nullptr);
        PASS("otel_logger_provider");
    } catch (const std::exception& e) { FAIL("otel_logger_provider", e.what()); }

    std::cout << "\n" << (total - failed) << "/" << total << " tests passed\n";
    return failed;
}
