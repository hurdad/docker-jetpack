# docker-jetpack

Docker images for NVIDIA JetPack 6 / L4T R36 / CUDA 12.2 (aarch64).

Pre-built images are published to GitHub Container Registry:
- C++ libs: [docker-jetpack6-runtime](https://github.com/hurdad/docker-jetpack/pkgs/container/docker-jetpack6-runtime) and [docker-jetpack6-dev](https://github.com/hurdad/docker-jetpack/pkgs/container/docker-jetpack6-dev)
- PyArrow CUDA: [docker-jetpack6-pyarrow-cuda](https://github.com/hurdad/docker-jetpack/pkgs/container/docker-jetpack6-pyarrow-cuda)

## Libraries

> Sizes measured from the installed builder image. `.so` = largest versioned shared lib; Headers = `du -sh /usr/local/include/<dir>`.

| Library | Version | Released | .so | Headers | Description |
|---|---|---|---|---|---|
| CUDA | 12.2 | — | — | — | Provided by `l4t-jetpack:r36.2.0` base image |
| cuBLAS | 12.2 | — | — | — | CUDA Basic Linear Algebra Subroutines |
| cuDNN | 8.x | — | — | — | Deep Neural Network primitives |
| TensorRT | 8.x | — | — | — | High-performance deep learning inference |
| [jemalloc](https://github.com/jemalloc/jemalloc) | 5.3.0 | May 2022 | 6.7 MB | 20 KB | Memory allocator with profiling and background thread support |
| [fmt](https://github.com/fmtlib/fmt) | 12.1.0 | Oct 2025 | 160 KB | 596 KB | Fast, safe C++ formatting library |
| [spdlog](https://github.com/gabime/spdlog) | v1.17.0 | Jan 2026 | 637 KB | 584 KB | Fast C++ logging library (uses fmt) |
| [Abseil](https://github.com/abseil/abseil-cpp) | 20240116.2 | Apr 2024 | 24 KB¹ | 4.4 MB | Google C++ common libraries |
| [Protobuf](https://github.com/protocolbuffers/protobuf) | v27.3 | Jul 2024 | 4.9 MB² | 4.5 MB³ | Protocol Buffers serialization |
| [gRPC](https://github.com/grpc/grpc) | v1.66.2 | Sep 2024 | 13 MB⁴ | 544 KB | High-performance RPC framework |
| [AWS SDK C++](https://github.com/aws/aws-sdk-cpp) | 1.11.350 | Jun 2024 | 2.9 MB⁵ | 13 MB | S3, STS, IAM, Cognito, Transfer, Config — required for Arrow S3 support |
| [xsimd](https://github.com/xtensor-stack/xsimd) | 13.2.0 | Feb 2025 | — | 1.6 MB | SIMD intrinsics wrapper (Arrow dependency, header-only) |
| [Apache Arrow](https://github.com/apache/arrow) | 23.0.1 | Feb 2026 | 19 MB⁶ | 3.9 MB | Columnar in-memory analytics with CUDA, S3, CSV and JSON support |
| [OpenTelemetry C++](https://github.com/open-telemetry/opentelemetry-cpp) | v1.26.0 | Mar 2026 | 992 KB⁷ | 5.1 MB | Observability — traces, metrics, logs with OTLP/gRPC and OTLP/HTTP exporters |
| [FlatBuffers](https://github.com/google/flatbuffers) | v25.12.19 | Dec 2025 | 704 KB | 528 KB | Memory-efficient serialization library |
| [nats.c](https://github.com/nats-io/nats.c) | v3.12.0 | Nov 2025 | 577 KB | 452 KB | NATS messaging C client with TLS support |
| [nats-cpp](https://github.com/hurdad/nats-cpp) | main | — | — | 148 KB | Header-only C++20 wrapper for nats.c |
| [GoogleTest](https://github.com/google/googletest) | v1.15.2 | Jul 2024 | — | — | C++ testing and mocking framework (dev image only) |

<details>
<summary>Size footnotes</summary>

¹ Abseil installs 86 small shared libs. Largest: `libabsl_strings.so` 164 KB, `libabsl_time_zone.so` 140 KB, `libabsl_cord.so` 137 KB, `libabsl_str_format_internal.so` 126 KB, `libabsl_time.so` 108 KB, `libabsl_flags_parse.so` 82 KB, `libabsl_cord_internal.so` 79 KB, `libabsl_synchronization.so` 76 KB; remainder < 60 KB each.

² Protobuf ships 3 shared libs: `libprotoc.so` 4.9 MB (compiler), `libprotobuf.so` 3.6 MB (runtime), `libprotobuf-lite.so` 673 KB (lite runtime).

³ Protobuf headers live under `google/` (4.5 MB total, shared with other Google libs).

⁴ gRPC shared libs: `libgrpc.so` 13 MB, `libgrpc_unsecure.so` 8.2 MB, `libgrpc_authorization_provider.so` 3.9 MB, `libgrpc++.so` 1.4 MB, `libgrpc++_unsecure.so` 761 KB, `libgrpcpp_channelz.so` 696 KB, `libgrpc++_reflection.so` 679 KB, `libgrpc_plugin_support.so` 545 KB, `libgrpc++_alts.so` 34 KB, `libgrpc++_error_details.so` 7.6 KB.

⁵ AWS SDK ships 21 shared libs. SDK modules: `libaws-cpp-sdk-s3.so` 2.9 MB, `libaws-cpp-sdk-iam.so` 2.9 MB, `libaws-cpp-sdk-config.so` 2.3 MB, `libaws-cpp-sdk-core.so` 2.0 MB, `libaws-cpp-sdk-cognito-identity.so` 589 KB, `libaws-cpp-sdk-sts.so` 330 KB, `libaws-cpp-sdk-transfer.so` 288 KB, `libaws-cpp-sdk-access-management.so` 286 KB, `libaws-cpp-sdk-identity-management.so` 182 KB. CRT layer: `libaws-crt-cpp.so` 879 KB, `libaws-c-http.so` 453 KB, `libaws-c-mqtt.so` 361 KB, `libaws-c-io.so` 345 KB, `libaws-c-common.so` 319 KB, `libaws-c-auth.so` 256 KB, `libaws-c-s3.so` 252 KB, `libaws-c-sdkutils.so` 123 KB, `libaws-c-event-stream.so` 108 KB, `libaws-c-cal.so` 97 KB, `libaws-checksums.so` 45 KB, `libaws-c-compression.so` 18 KB.

⁶ Arrow shared libs: `libarrow.so` 19 MB, `libarrow_cuda.so` 275 KB. Compute and Dataset disabled (no `libarrow_compute`, `libarrow_acero`, `libarrow_dataset`).

⁷ OpenTelemetry ships 33 shared libs. Core: `libopentelemetry_metrics.so` 992 KB, `libopentelemetry_logs.so` 708 KB, `libopentelemetry_proto.so` 459 KB, `libopentelemetry_trace.so` 351 KB, `libopentelemetry_proto_grpc.so` 289 KB, `libopentelemetry_http_client_curl.so` 222 KB, `libopentelemetry_otlp_recordable.so` 179 KB, `libopentelemetry_resources.so` 72 KB, `libopentelemetry_common.so` 65 KB, `libopentelemetry_version.so` 8.4 KB. Exporters: `libopentelemetry_exporter_otlp_http_client.so` 162 KB, `libopentelemetry_exporter_ostream_span.so` 110 KB, `libopentelemetry_exporter_in_memory_metric.so` 93 KB, `libopentelemetry_exporter_in_memory.so` 91 KB, `libopentelemetry_exporter_otlp_grpc_client.so` 81 KB, `libopentelemetry_exporter_ostream_metrics.so` 81 KB, `libopentelemetry_exporter_otlp_grpc_metrics.so` 75 KB, `libopentelemetry_exporter_otlp_grpc_log.so` 75 KB, `libopentelemetry_exporter_otlp_grpc.so` 75 KB, `libopentelemetry_exporter_otlp_http_metric.so` 73 KB, `libopentelemetry_exporter_otlp_http_log.so` 73 KB, `libopentelemetry_exporter_otlp_http.so` 73 KB, `libopentelemetry_exporter_ostream_logs.so` 49 KB; plus 10 builder libs (14–37 KB each).

</details>

## Images

### C++ libs (`Dockerfile.jetpack6`)

| Image | Size | Description |
|---|---|---|
| `ghcr.io/hurdad/docker-jetpack6-runtime:latest` | ~1.2 GB | Runtime — minimal libs only |
| `ghcr.io/hurdad/docker-jetpack6-dev:latest` | ~13 GB | Dev — includes build tools and headers |

### PyArrow CUDA (`Dockerfile.jetpack6.pyarrow-cuda`)

| Image | Description |
|---|---|
| `ghcr.io/hurdad/docker-jetpack6-pyarrow-cuda:latest` | PyArrow 23.0.1 with CUDA, Parquet, Dataset and Compute — built for Jetson |

## Pull

```bash
# C++ libs — runtime
docker pull ghcr.io/hurdad/docker-jetpack6-runtime:latest

# C++ libs — dev
docker pull ghcr.io/hurdad/docker-jetpack6-dev:latest

# PyArrow CUDA
docker pull ghcr.io/hurdad/docker-jetpack6-pyarrow-cuda:latest
```

## Build locally

Build must run on an aarch64 host (Jetson).

```bash
# C++ libs — runtime
docker build -f Dockerfile.jetpack6 --target runtime -t docker-jetpack6:runtime .

# C++ libs — dev
docker build -f Dockerfile.jetpack6 --target dev -t docker-jetpack6:dev .

# PyArrow CUDA
docker build -f Dockerfile.jetpack6.pyarrow-cuda --target runtime -t docker-jetpack6-pyarrow-cuda .
```

## Usage

```bash
# C++ libs — runtime
docker run --rm --runtime=nvidia ghcr.io/hurdad/docker-jetpack6-runtime:latest

# C++ libs — dev
docker run --rm --runtime=nvidia \
  -v $(pwd):/workspace \
  ghcr.io/hurdad/docker-jetpack6-dev:latest

# PyArrow CUDA
docker run --rm --runtime=nvidia ghcr.io/hurdad/docker-jetpack6-pyarrow-cuda:latest \
  python3 -c "import pyarrow.cuda; print('CUDA OK')"
```

> `--runtime=nvidia` is required to expose CUDA libraries from the Jetson host.

## Testing

Two test stages are available in `Dockerfile.jetpack6`.

### Smoke tests

Builds and runs a small C++ and Python test suite that verifies all built libraries load and function correctly.

```bash
docker build -f Dockerfile.jetpack6 --target test -t docker-jetpack6:test .
```

Covers: Arrow (array ops, S3 init, CUDA), AWS SDK, gRPC, Protobuf, FlatBuffers, jemalloc, nats.c, nats-cpp, OpenTelemetry (trace/metrics/logs). Arrow Compute and Dataset disabled.

### Upstream library test suites

Rebuilds each library with its own test suite enabled and runs `ctest`. This is slower but exercises the full upstream test coverage.

```bash
docker build -f Dockerfile.jetpack6 --target test-libs -t docker-jetpack6:test-libs .
```

Covers: jemalloc (`make check`), Abseil, Protobuf, xsimd, FlatBuffers, Arrow (non-CUDA, S3; Compute and Dataset disabled), OpenTelemetry C++, nats.c.

> Arrow CUDA tests and gRPC tests are excluded from the build-time test suite. Arrow CUDA tests require `--runtime=nvidia` and must be run manually:
> ```bash
> docker run --rm --runtime=nvidia docker-jetpack6:test-libs ctest -R cuda
> ```

## CI

Images are built and tested automatically via GitHub Actions on a self-hosted `jetson6` runner and pushed to GHCR on every push to `main` and on version tags.
