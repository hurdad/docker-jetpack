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

Both images are defined as stages in `Dockerfile.jetpack6`. Build must run on an aarch64 host (Jetson).

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

## CI

Images are built automatically via GitHub Actions on a self-hosted `jetson6` runner and pushed to GHCR on every push to `main` and on version tags.
