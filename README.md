# docker-jetpack6

Docker images for NVIDIA JetPack 6 / L4T R36 / CUDA 12.2 (aarch64).

Pre-built images are published to [GitHub Container Registry](https://github.com/hurdad/docker-jetpack/pkgs/container/docker-jetpack6).

## Libraries

| Library | Version | Released | Description |
|---|---|---|---|
| CUDA | 12.2 | — | Provided by `l4t-jetpack:r36.2.0` base image |
| cuBLAS | 12.2 | — | CUDA Basic Linear Algebra Subroutines |
| cuDNN | 8.x | — | Deep Neural Network primitives |
| TensorRT | 8.x | — | High-performance deep learning inference |
| [jemalloc](https://github.com/jemalloc/jemalloc) | 5.3.0 | May 2019 | Memory allocator with profiling and background thread support |
| [Abseil](https://github.com/abseil/abseil-cpp) | 20240116.2 | Apr 2024 | Google C++ common libraries |
| [Protobuf](https://github.com/protocolbuffers/protobuf) | v27.3 | Jul 2024 | Protocol Buffers serialization |
| [gRPC](https://github.com/grpc/grpc) | v1.66.2 | Sep 2024 | High-performance RPC framework |
| [AWS SDK C++](https://github.com/aws/aws-sdk-cpp) | 1.11.350 | Jun 2024 | S3, STS, IAM, Cognito — required for Arrow S3 support |
| [xsimd](https://github.com/xtensor-stack/xsimd) | 12.1.0 | Dec 2024 | SIMD intrinsics wrapper (Arrow dependency, header-only) |
| [Apache Arrow](https://github.com/apache/arrow) | 23.0.1 | Feb 2025 | Columnar in-memory analytics with CUDA and S3 support; includes PyArrow |
| [OpenTelemetry C++](https://github.com/open-telemetry/opentelemetry-cpp) | v1.26.0 | Mar 2025 | Observability — traces, metrics, logs with OTLP/gRPC and OTLP/HTTP exporters |
| [FlatBuffers](https://github.com/google/flatbuffers) | v25.12.19 | Dec 2024 | Memory-efficient serialization library |
| [nats.c](https://github.com/nats-io/nats.c) | v3.12.0 | Nov 2024 | NATS messaging C client with TLS support |
| [nats-cpp](https://github.com/hurdad/nats-cpp) | main | — | Header-only C++20 wrapper for nats.c |

## Images

| Image | Description |
|---|---|
| `ghcr.io/hurdad/docker-jetpack6:latest` | Runtime — minimal libs only |
| `ghcr.io/hurdad/docker-jetpack6:latest-dev` | Dev — includes build tools and headers |

## Pull

```bash
# Runtime
docker pull ghcr.io/hurdad/docker-jetpack6:latest

# Dev
docker pull ghcr.io/hurdad/docker-jetpack6:latest-dev
```

## Build locally

All images are defined as stages in `Dockerfile.jetpack6`. Build must run on an aarch64 host (Jetson).

```bash
# Runtime
docker build -f Dockerfile.jetpack6 --target runtime -t docker-jetpack6:runtime .

# Dev
docker build -f Dockerfile.jetpack6 --target dev -t docker-jetpack6:dev .

# Both
docker build -f Dockerfile.jetpack6 --target runtime -t docker-jetpack6:runtime . && \
docker build -f Dockerfile.jetpack6 --target dev     -t docker-jetpack6:dev     .
```

## Usage

```bash
# Runtime
docker run --rm --runtime=nvidia ghcr.io/hurdad/docker-jetpack6:latest

# Dev
docker run --rm --runtime=nvidia \
  -v $(pwd):/workspace \
  ghcr.io/hurdad/docker-jetpack6:latest-dev
```

> `--runtime=nvidia` is required to expose CUDA libraries from the Jetson host.

## Testing

Two test stages are available in `Dockerfile.jetpack6`.

### Smoke tests

Builds and runs a small C++ and Python test suite that verifies all built libraries load and function correctly.

```bash
docker build -f Dockerfile.jetpack6 --target test -t docker-jetpack6:test .
```

Covers: Arrow array ops, Arrow CUDA, gRPC, Protobuf, FlatBuffers, jemalloc, PyArrow (arrays, Parquet roundtrip, CUDA buffer).

### Upstream library test suites

Rebuilds each library with its own test suite enabled and runs `ctest`. This is slower but exercises the full upstream test coverage.

```bash
docker build -f Dockerfile.jetpack6 --target test-libs -t docker-jetpack6:test-libs .
```

Covers: jemalloc (`make check`), Abseil, Protobuf, xsimd, FlatBuffers, Arrow (non-CUDA), OpenTelemetry C++.

> Arrow CUDA tests and gRPC tests are excluded from the build-time test suite. Arrow CUDA tests require `--runtime=nvidia` and must be run manually:
> ```bash
> docker run --rm --runtime=nvidia docker-jetpack6:test-libs ctest -R cuda
> ```

## CI

Images are built and tested automatically via GitHub Actions on a self-hosted `jetson6` runner and pushed to GHCR on every push to `main` and on version tags.
