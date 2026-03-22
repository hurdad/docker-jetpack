# docker-jetpack6

Docker images for NVIDIA JetPack 6 / L4T R36 / CUDA 12.2 (aarch64).

Includes: CUDA, cuBLAS, cuDNN, TensorRT, jemalloc, Abseil, Protobuf, gRPC, Apache Arrow (CUDA-enabled + PyArrow), OpenTelemetry C++, FlatBuffers.

Pre-built images are published to [GitHub Container Registry](https://github.com/hurdad/docker-jetpack/pkgs/container/docker-jetpack6).

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
