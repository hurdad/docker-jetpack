# docker-jetpack

Docker images for NVIDIA JetPack 6 / L4T R36 / CUDA 12.2 (aarch64).

Pre-built images are published to [GitHub Container Registry](https://github.com/hurdad/docker-jetpack/pkgs/container/docker-jetpack6).

## Libraries

> Sizes measured from the installed builder image. `.so` = largest versioned shared lib; `.a` = largest static archive; Headers = `du -sh /usr/local/include/<dir>`.

| Library | Version | Released | .so | .a | Headers | Description |
|---|---|---|---|---|---|---|
| CUDA | 12.2 | — | — | — | — | Provided by `l4t-jetpack:r36.2.0` base image |
| cuBLAS | 12.2 | — | — | — | — | CUDA Basic Linear Algebra Subroutines |
| cuDNN | 8.x | — | — | — | — | Deep Neural Network primitives |
| TensorRT | 8.x | — | — | — | — | High-performance deep learning inference |
| [jemalloc](https://github.com/jemalloc/jemalloc) | 5.3.0 | May 2019 | 6.7 MB | 44 MB | 20 KB | Memory allocator with profiling and background thread support |
| [Abseil](https://github.com/abseil/abseil-cpp) | 20240116.2 | Apr 2024 | — | ~2.5 MB¹ | 4.4 MB | Google C++ common libraries (static only) |
| [Protobuf](https://github.com/protocolbuffers/protobuf) | v27.3 | Jul 2024 | — | 6.7 MB | ~1 MB² | Protocol Buffers serialization (static only) |
| [gRPC](https://github.com/grpc/grpc) | v1.66.2 | Sep 2024 | — | 32 MB | 2 MB | High-performance RPC framework (static only) |
| [AWS SDK C++](https://github.com/aws/aws-sdk-cpp) | 1.11.350 | Jun 2024 | ~16 MB³ | — | 13 MB | S3, STS, IAM, Cognito, Transfer, Config — required for Arrow S3 support |
| [xsimd](https://github.com/xtensor-stack/xsimd) | 13.2.0 | — | — | — | 1.6 MB | SIMD intrinsics wrapper (Arrow dependency, header-only) |
| [Apache Arrow](https://github.com/apache/arrow) | 23.0.1 | Feb 2025 | 19 MB⁴ | 42 MB⁵ | 4.3 MB + 648 KB⁶ | Columnar in-memory analytics with CUDA and S3 support; includes PyArrow and Parquet |
| [OpenTelemetry C++](https://github.com/open-telemetry/opentelemetry-cpp) | v1.26.0 | Mar 2025 | — | ~5 MB⁷ | 5.1 MB | Observability — traces, metrics, logs with OTLP/gRPC and OTLP/HTTP exporters |
| [FlatBuffers](https://github.com/google/flatbuffers) | v25.12.19 | Dec 2024 | — | 1.1 MB | 528 KB | Memory-efficient serialization library (static only) |
| [nats.c](https://github.com/nats-io/nats.c) | v3.12.0 | Nov 2024 | 573 KB | 1.1 MB | 68 KB | NATS messaging C client with TLS support |
| [nats-cpp](https://github.com/hurdad/nats-cpp) | main | — | — | — | 164 KB | Header-only C++20 wrapper for nats.c |

<details>
<summary>Size footnotes</summary>

¹ Abseil installs ~80 small static archives; largest is `libabsl_strings.a` (215 KB).
² Protobuf headers live under `google/` (4.5 MB total, shared with other Google libs).
³ AWS SDK shared libs: core (2.0 MB), s3 (2.9 MB), config (2.3 MB), iam (2.9 MB), plus CRT layer (s2n 1.4 MB, aws-crt-cpp 879 KB, aws-c-{auth,cal,common,http,io,mqtt,s3,…} ~2.3 MB combined).
⁴ `libarrow.so` 19 MB; `libarrow_compute.so` 15 MB; `libarrow_acero.so` 2.2 MB; `libarrow_dataset.so` 2.7 MB; `libarrow_cuda.so` 279 KB; `libparquet.so` 5.2 MB.
⁵ `libarrow.a` 42 MB; `libarrow_compute.a` 26 MB; `libarrow_dataset.a` 5.9 MB; `libarrow_acero.a` 5.3 MB; `libarrow_cuda.a` 528 KB; `libparquet.a` 12 MB.
⁶ Arrow headers 4.3 MB + Parquet headers 648 KB.
⁷ OpenTelemetry installs ~40 static archives; largest are `libopentelemetry_metrics.a` (3.0 MB) and `libopentelemetry_trace.a` (1.1 MB).

</details>

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

Covers: Arrow (array ops, CUDA), gRPC, Protobuf, FlatBuffers, jemalloc, nats.c, nats-cpp, PyArrow (arrays, Parquet roundtrip, S3 init, CUDA buffer).

### Upstream library test suites

Rebuilds each library with its own test suite enabled and runs `ctest`. This is slower but exercises the full upstream test coverage.

```bash
docker build -f Dockerfile.jetpack6 --target test-libs -t docker-jetpack6:test-libs .
```

Covers: jemalloc (`make check`), Abseil, Protobuf, xsimd, FlatBuffers, Arrow (non-CUDA, S3), OpenTelemetry C++, nats.c.

> Arrow CUDA tests and gRPC tests are excluded from the build-time test suite. Arrow CUDA tests require `--runtime=nvidia` and must be run manually:
> ```bash
> docker run --rm --runtime=nvidia docker-jetpack6:test-libs ctest -R cuda
> ```

## CI

Images are built and tested automatically via GitHub Actions on a self-hosted `jetson6` runner and pushed to GHCR on every push to `main` and on version tags.
