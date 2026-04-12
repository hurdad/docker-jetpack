# docker-jetpack

Docker base images with a curated set of C++ libraries, published for four targets:

|  | CPU (ubuntu:24.04) | CUDA |
|---|---|---|
| **x86 (amd64)** | `jetpack-x86-cpu` | `jetpack-x86-cuda` (CUDA 13.2.0) |
| **arm64 (aarch64)** | `jetpack-arm64-cpu` | `jetpack-arm64-cuda` (JetPack 6 / L4T r36.2.0 / CUDA 12.2) |

Each target publishes a `-dev` image (build tools + headers) and a `-runtime` image (shared libs only).

## Libraries

> Sizes measured from the installed builder image. `.so` = largest versioned shared lib; Headers = `du -sh /usr/local/include/<dir>`.

| Library | Version | Released | .so | Headers | Description |
|---|---|---|---|---|---|
| CUDA | 13.2.0 / 12.2¹ | — | — | — | x86-cuda: `nvidia/cuda:13.2.0-devel-ubuntu24.04`; arm64-cuda: `l4tcuda:r36.2.0` |
| [jemalloc](https://github.com/jemalloc/jemalloc) | 5.3.0 | May 2022 | 6.7 MB | 20 KB | Memory allocator with profiling and background thread support |
| [fmt](https://github.com/fmtlib/fmt) | 12.1.0 | Oct 2025 | 160 KB | 596 KB | Fast, safe C++ formatting library |
| [spdlog](https://github.com/gabime/spdlog) | v1.17.0 | Jan 2026 | 637 KB | 584 KB | Fast C++ logging library (uses fmt) |
| [Abseil](https://github.com/abseil/abseil-cpp) | 20240116.2 | Apr 2024 | 24 KB² | 4.4 MB | Google C++ common libraries |
| [Protobuf](https://github.com/protocolbuffers/protobuf) | v27.3 | Jul 2024 | 4.9 MB³ | 4.5 MB⁴ | Protocol Buffers serialization |
| [gRPC](https://github.com/grpc/grpc) | v1.66.2 | Sep 2024 | 13 MB⁵ | 544 KB | High-performance RPC framework |
| [AWS SDK C++](https://github.com/aws/aws-sdk-cpp) | 1.11.350 | Jun 2024 | 2.9 MB⁵ | 13 MB | S3, STS, IAM, Cognito, Transfer, Config — required for Arrow S3 support |
| [xsimd](https://github.com/xtensor-stack/xsimd) | 13.2.0 | Feb 2025 | — | 1.6 MB | SIMD intrinsics wrapper (Arrow dependency, header-only) |
| [Apache Arrow](https://github.com/apache/arrow) | 23.0.1 | Feb 2026 | 19 MB⁷ | 3.9 MB | Columnar in-memory analytics; CUDA enabled on cuda variants, S3/CSV/JSON on all |
| [OpenTelemetry C++](https://github.com/open-telemetry/opentelemetry-cpp) | v1.26.0 | Mar 2026 | 992 KB⁸ | 5.1 MB | Observability — traces, metrics, logs with OTLP/gRPC and OTLP/HTTP exporters |
| [FlatBuffers](https://github.com/google/flatbuffers) | v25.12.19 | Dec 2025 | 704 KB | 528 KB | Memory-efficient serialization library |
| [nats.c](https://github.com/nats-io/nats.c) | v3.12.0 | Nov 2025 | 577 KB | 452 KB | NATS messaging C client with TLS support |
| [nats-cpp](https://github.com/hurdad/nats-cpp) | main | — | — | 148 KB | Header-only C++20 wrapper for nats.c |
| [GoogleTest](https://github.com/google/googletest) | v1.15.2 | Jul 2024 | — | — | C++ testing and mocking framework (dev image only) |

**SIMD:** x86 images build Arrow with `AVX2`; arm64 images build with `NEON`.

<details>
<summary>Size footnotes</summary>

¹ CUDA 13.2.0 on x86-cuda; CUDA 12.2 on arm64-cuda (JetPack 6).

² Abseil installs 86 small shared libs. Largest: `libabsl_strings.so` 164 KB, `libabsl_time_zone.so` 140 KB, `libabsl_cord.so` 137 KB, `libabsl_str_format_internal.so` 126 KB, `libabsl_time.so` 108 KB, `libabsl_flags_parse.so` 82 KB, `libabsl_cord_internal.so` 79 KB, `libabsl_synchronization.so` 76 KB; remainder < 60 KB each.

³ Protobuf ships 3 shared libs: `libprotoc.so` 4.9 MB (compiler), `libprotobuf.so` 3.6 MB (runtime), `libprotobuf-lite.so` 673 KB (lite runtime).

⁴ Protobuf headers live under `google/` (4.5 MB total, shared with other Google libs).

⁵ gRPC shared libs: `libgrpc.so` 13 MB, `libgrpc_unsecure.so` 8.2 MB, `libgrpc_authorization_provider.so` 3.9 MB, `libgrpc++.so` 1.4 MB, `libgrpc++_unsecure.so` 761 KB, `libgrpcpp_channelz.so` 696 KB, `libgrpc++_reflection.so` 679 KB, `libgrpc_plugin_support.so` 545 KB, `libgrpc++_alts.so` 34 KB, `libgrpc++_error_details.so` 7.6 KB.

⁶ AWS SDK ships 21 shared libs. SDK modules: `libaws-cpp-sdk-s3.so` 2.9 MB, `libaws-cpp-sdk-iam.so` 2.9 MB, `libaws-cpp-sdk-config.so` 2.3 MB, `libaws-cpp-sdk-core.so` 2.0 MB, `libaws-cpp-sdk-cognito-identity.so` 589 KB, `libaws-cpp-sdk-sts.so` 330 KB, `libaws-cpp-sdk-transfer.so` 288 KB, `libaws-cpp-sdk-access-management.so` 286 KB, `libaws-cpp-sdk-identity-management.so` 182 KB. CRT layer: `libaws-crt-cpp.so` 879 KB, `libaws-c-http.so` 453 KB, `libaws-c-mqtt.so` 361 KB, `libaws-c-io.so` 345 KB, `libaws-c-common.so` 319 KB, `libaws-c-auth.so` 256 KB, `libaws-c-s3.so` 252 KB, `libaws-c-sdkutils.so` 123 KB, `libaws-c-event-stream.so` 108 KB, `libaws-c-cal.so` 97 KB, `libaws-checksums.so` 45 KB, `libaws-c-compression.so` 18 KB.

⁷ Arrow shared libs: `libarrow.so` 19 MB, `libarrow_cuda.so` 275 KB (cuda variants only). Compute and Dataset disabled.

⁸ OpenTelemetry ships 33 shared libs. Core: `libopentelemetry_metrics.so` 992 KB, `libopentelemetry_logs.so` 708 KB, `libopentelemetry_proto.so` 459 KB, `libopentelemetry_trace.so` 351 KB, `libopentelemetry_proto_grpc.so` 289 KB, `libopentelemetry_http_client_curl.so` 222 KB, `libopentelemetry_otlp_recordable.so` 179 KB, `libopentelemetry_resources.so` 72 KB, `libopentelemetry_common.so` 65 KB, `libopentelemetry_version.so` 8.4 KB. Exporters: `libopentelemetry_exporter_otlp_http_client.so` 162 KB, `libopentelemetry_exporter_ostream_span.so` 110 KB, `libopentelemetry_exporter_in_memory_metric.so` 93 KB, `libopentelemetry_exporter_in_memory.so` 91 KB, `libopentelemetry_exporter_otlp_grpc_client.so` 81 KB, `libopentelemetry_exporter_ostream_metrics.so` 81 KB, `libopentelemetry_exporter_otlp_grpc_metrics.so` 75 KB, `libopentelemetry_exporter_otlp_grpc_log.so` 75 KB, `libopentelemetry_exporter_otlp_grpc.so` 75 KB, `libopentelemetry_exporter_otlp_http_metric.so` 73 KB, `libopentelemetry_exporter_otlp_http_log.so` 73 KB, `libopentelemetry_exporter_otlp_http.so` 73 KB, `libopentelemetry_exporter_ostream_logs.so` 49 KB; plus 10 builder libs (14–37 KB each).

</details>

## Images

All images are published to GitHub Container Registry under `ghcr.io/hurdad/`.

| Image | Variant | Description |
|---|---|---|
| `jetpack-x86-cpu-dev:latest` | x86 CPU | Build tools + headers, ubuntu:24.04 |
| `jetpack-x86-cpu-runtime:latest` | x86 CPU | Shared libs only, ubuntu:24.04 |
| `jetpack-x86-cuda-dev:latest` | x86 CUDA | Build tools + headers, CUDA 13.2.0 |
| `jetpack-x86-cuda-runtime:latest` | x86 CUDA | Shared libs only, CUDA 13.2.0 runtime |
| `jetpack-arm64-cpu-dev:latest` | arm64 CPU | Build tools + headers, ubuntu:24.04 |
| `jetpack-arm64-cpu-runtime:latest` | arm64 CPU | Shared libs only, ubuntu:24.04 |
| `jetpack-arm64-cuda-dev:latest` | arm64 CUDA (Jetson) | Build tools + headers, JetPack 6 / L4T r36.2.0 |
| `jetpack-arm64-cuda-runtime:latest` | arm64 CUDA (Jetson) | Shared libs only, L4T base r36.2.0 |

## Pull

```bash
# x86 CPU
docker pull ghcr.io/hurdad/jetpack-x86-cpu-runtime:latest
docker pull ghcr.io/hurdad/jetpack-x86-cpu-dev:latest

# x86 CUDA
docker pull ghcr.io/hurdad/jetpack-x86-cuda-runtime:latest
docker pull ghcr.io/hurdad/jetpack-x86-cuda-dev:latest

# arm64 CPU
docker pull ghcr.io/hurdad/jetpack-arm64-cpu-runtime:latest
docker pull ghcr.io/hurdad/jetpack-arm64-cpu-dev:latest

# arm64 CUDA (Jetson)
docker pull ghcr.io/hurdad/jetpack-arm64-cuda-runtime:latest
docker pull ghcr.io/hurdad/jetpack-arm64-cuda-dev:latest
```

## Build locally

```bash
# x86 CPU
docker build -f Dockerfile --target runtime -t jetpack-x86-cpu:runtime .
docker build -f Dockerfile --target dev     -t jetpack-x86-cpu:dev .

# x86 CUDA
docker build -f Dockerfile.cuda --target runtime -t jetpack-x86-cuda:runtime .
docker build -f Dockerfile.cuda --target dev     -t jetpack-x86-cuda:dev .

# arm64 CPU  (run natively on arm64, or use buildx with --platform linux/arm64)
docker build -f Dockerfile --build-arg ARROW_SIMD_LEVEL=NEON \
  --platform linux/arm64 --target runtime -t jetpack-arm64-cpu:runtime .

# arm64 CUDA (Jetson — must run on an aarch64 host or buildx with QEMU)
docker build -f Dockerfile.l4tcuda --target runtime -t jetpack-arm64-cuda:runtime .
docker build -f Dockerfile.l4tcuda --target dev     -t jetpack-arm64-cuda:dev .
```

## Usage

```bash
# x86 CPU
docker run --rm ghcr.io/hurdad/jetpack-x86-cpu-runtime:latest

# x86 CUDA (requires NVIDIA Container Toolkit)
docker run --rm --gpus all ghcr.io/hurdad/jetpack-x86-cuda-runtime:latest

# arm64 CPU
docker run --rm ghcr.io/hurdad/jetpack-arm64-cpu-runtime:latest

# arm64 CUDA / Jetson (requires --runtime=nvidia from the NVIDIA Container Runtime)
docker run --rm --runtime=nvidia ghcr.io/hurdad/jetpack-arm64-cuda-runtime:latest
```

> On Jetson, `--runtime=nvidia` exposes CUDA libraries from the host. On x86, use `--gpus all` with the NVIDIA Container Toolkit.

## Testing

Each Dockerfile has two test stages.

### Smoke tests

Builds and runs a small C++ test suite that verifies all built libraries load and function correctly.

```bash
# x86 CPU
docker build -f Dockerfile --target test .

# x86 CUDA
docker build -f Dockerfile.cuda --target test .

# arm64 CPU
docker build -f Dockerfile --build-arg ARROW_SIMD_LEVEL=NEON \
  --platform linux/arm64 --target test .

# arm64 CUDA (Jetson)
docker build -f Dockerfile.l4tcuda --target test .
```

Covers: Arrow (array ops, S3 init, CUDA on cuda variants), AWS SDK, gRPC, Protobuf, FlatBuffers, jemalloc, nats.c, nats-cpp, OpenTelemetry (trace/metrics/logs).

### Upstream library test suites

Rebuilds each library with its own test suite enabled and runs `ctest`. Slower but exercises full upstream test coverage.

```bash
# x86 CPU
docker build -f Dockerfile --target test-libs .

# arm64 CUDA (Jetson)
docker build -f Dockerfile.l4tcuda --target test-libs .
```

Covers: jemalloc (`make check`), Abseil, Protobuf, xsimd, FlatBuffers, Arrow (non-CUDA, S3), OpenTelemetry C++, nats.c.

> Arrow CUDA tests require a live GPU and must be run manually:
> ```bash
> docker run --rm --gpus all <image>:test-libs ctest -R cuda        # x86
> docker run --rm --runtime=nvidia <image>:test-libs ctest -R cuda  # Jetson
> ```

## CI

Images are built and tested automatically via GitHub Actions and pushed to GHCR on every push to `main` and on version tags.

- x86 variants run on `ubuntu-latest` GitHub-hosted runners.
- arm64 variants run on a self-hosted `jetson6` runner.

The workflow runs smoke tests for all four variants first; build jobs only proceed after all tests pass.
