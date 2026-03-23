#include <iostream>
#include <cassert>

// Arrow
#include <arrow/api.h>
#include <arrow/filesystem/s3fs.h>

// AWS SDK
#include <aws/core/Aws.h>

// gRPC / Protobuf
#include <grpcpp/grpcpp.h>
#include <google/protobuf/descriptor.h>

// OpenTelemetry
#include <opentelemetry/sdk/trace/tracer_provider_factory.h>
#include <opentelemetry/sdk/metrics/meter_provider_factory.h>
#include <opentelemetry/sdk/logs/logger_provider_factory.h>
#include <opentelemetry/sdk/logs/simple_log_record_processor_factory.h>
#include <opentelemetry/exporters/ostream/log_record_exporter_factory.h>

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
    int total = 13;

    // Arrow: build a simple int32 array
    try {
        arrow::Int32Builder builder;
        assert(builder.AppendValues({1, 2, 3, 4, 5}).ok());
        std::shared_ptr<arrow::Array> arr;
        assert(builder.Finish(&arr).ok());
        assert(arr->length() == 5);
        PASS("arrow_array");
    } catch (const std::exception& e) { FAIL("arrow_array", e.what()); }

    // Arrow S3: initialize and finalize (no network required)
    try {
        auto status = arrow::fs::EnsureS3Initialized();
        assert(status.ok());
        PASS("arrow_s3_init");
        arrow::fs::EnsureS3Finalized().ok();
    } catch (const std::exception& e) { FAIL("arrow_s3_init", e.what()); }

    // AWS SDK: init and shutdown
    try {
        Aws::SDKOptions options;
        Aws::InitAPI(options);
        Aws::ShutdownAPI(options);
        PASS("aws_sdk_init");
    } catch (const std::exception& e) { FAIL("aws_sdk_init", e.what()); }

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

    // jemalloc: verify active via mallctl epoch + stats.allocated
    try {
        void* p = malloc(1024);
        assert(p != nullptr);
        free(p);
        size_t epoch = 1, sz = sizeof(epoch);
        assert(mallctl("epoch", &epoch, &sz, &epoch, sz) == 0);
        size_t allocated = 0; sz = sizeof(allocated);
        assert(mallctl("stats.allocated", &allocated, &sz, nullptr, 0) == 0);
        assert(allocated > 0);
        PASS("jemalloc_alloc");
    } catch (const std::exception& e) { FAIL("jemalloc_alloc", e.what()); }

    // nats.c: version and ABI compatibility
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

    // OpenTelemetry: logger provider (requires a processor + exporter)
    try {
        auto exporter = opentelemetry::exporter::logs::OStreamLogRecordExporterFactory::Create();
        auto processor = opentelemetry::sdk::logs::SimpleLogRecordProcessorFactory::Create(std::move(exporter));
        auto provider = opentelemetry::sdk::logs::LoggerProviderFactory::Create(std::move(processor));
        assert(provider != nullptr);
        PASS("otel_logger_provider");
    } catch (const std::exception& e) { FAIL("otel_logger_provider", e.what()); }

    std::cout << "\n" << (total - failed) << "/" << total << " tests passed\n";
    return failed;
}
