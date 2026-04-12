# =========================
# Dockerfile — Ubuntu 24.04 (CPU, multi-arch)
# Pass --build-arg ARROW_SIMD_LEVEL=NEON for arm64 builds.
# =========================
ARG ARROW_SIMD_LEVEL=AVX2

# =========================
# Stage: Builder (base for dev)
# =========================
FROM ubuntu:24.04 AS builder

ARG ARROW_SIMD_LEVEL

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    ninja-build \
    git \
    pkg-config \
    autoconf \
    libtool \
    curl \
    unzip \
    ca-certificates \
    libssl-dev \
    zlib1g-dev \
    libzstd-dev \
    libsnappy-dev \
    liblz4-dev \
    libbrotli-dev \
    libutf8proc-dev \
    libcurl4-openssl-dev && \
    rm -rf /var/lib/apt/lists/*

ENV LD_LIBRARY_PATH=/usr/local/lib

WORKDIR /opt/build

# -------------------------
# jemalloc 5.3.0
# -------------------------
RUN curl -fsSL https://github.com/jemalloc/jemalloc/archive/refs/tags/5.3.0.tar.gz | tar -xz && \
    cd jemalloc-5.3.0 && \
    ./autogen.sh && \
    ./configure \
      --prefix=/usr/local \
      --enable-prof \
      --enable-stats \
      --enable-background-thread \
      --disable-static && \
    make -j$(nproc) && \
    make install && \
    rm -rf /opt/build/jemalloc-5.3.0

# -------------------------
# fmt 12.1.0
# -------------------------
RUN curl -fsSL https://github.com/fmtlib/fmt/archive/refs/tags/12.1.0.tar.gz | tar -xz && \
    cd fmt-12.1.0 && \
    mkdir build && cd build && \
    cmake .. -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DBUILD_SHARED_LIBS=ON \
      -DFMT_TEST=OFF \
      -DFMT_DOC=OFF && \
    ninja && ninja install && \
    rm -rf /opt/build/fmt-12.1.0

# -------------------------
# spdlog v1.17.0
# -------------------------
RUN curl -fsSL https://github.com/gabime/spdlog/archive/refs/tags/v1.17.0.tar.gz | tar -xz && \
    cd spdlog-1.17.0 && \
    mkdir build && cd build && \
    cmake .. -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DBUILD_SHARED_LIBS=ON \
      -DSPDLOG_FMT_EXTERNAL=ON \
      -DSPDLOG_BUILD_EXAMPLE=OFF \
      -DSPDLOG_BUILD_TESTS=OFF && \
    ninja && ninja install && \
    rm -rf /opt/build/spdlog-1.17.0

# -------------------------
# GoogleTest v1.15.2
# -------------------------
RUN curl -fsSL https://github.com/google/googletest/archive/refs/tags/v1.15.2.tar.gz | tar -xz && \
    cd googletest-1.15.2 && \
    mkdir build && cd build && \
    cmake .. -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DBUILD_SHARED_LIBS=ON \
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5 && \
    ninja && ninja install && \
    rm -rf /opt/build/googletest-1.15.2

# -------------------------
# Abseil 20240116.2
# -------------------------
RUN curl -fsSL https://github.com/abseil/abseil-cpp/archive/refs/tags/20240116.2.tar.gz | tar -xz && \
    cd abseil-cpp-20240116.2 && \
    mkdir build && cd build && \
    cmake .. -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DBUILD_SHARED_LIBS=ON && \
    ninja && ninja install && \
    rm -rf /opt/build/abseil-cpp-20240116.2

# -------------------------
# Protobuf v27.3
# -------------------------
RUN curl -fsSL https://github.com/protocolbuffers/protobuf/releases/download/v27.3/protobuf-27.3.tar.gz | tar -xz && \
    cd protobuf-27.3 && \
    mkdir build && cd build && \
    cmake .. -GNinja \
      -Dprotobuf_BUILD_TESTS=OFF \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -Dprotobuf_ABSL_PROVIDER=package \
      -DBUILD_SHARED_LIBS=ON && \
    ninja && ninja install && \
    rm -rf /opt/build/protobuf-27.3

# -------------------------
# gRPC v1.66.2
# -------------------------
RUN git clone https://github.com/grpc/grpc.git && \
    cd grpc && \
    git checkout v1.66.2 && \
    git submodule update --init --recursive && \
    mkdir -p cmake/build && cd cmake/build && \
    cmake ../.. -GNinja \
      -DgRPC_INSTALL=ON \
      -DgRPC_BUILD_TESTS=OFF \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DgRPC_ABSL_PROVIDER=package \
      -DgRPC_PROTOBUF_PROVIDER=package \
      -DgRPC_SSL_PROVIDER=package \
      -DgRPC_ZLIB_PROVIDER=package \
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
      -DBUILD_SHARED_LIBS=ON && \
    ninja && ninja install && \
    rm -rf /opt/build/grpc

# -------------------------
# AWS SDK for C++ 1.11.350 (Arrow S3 dependency)
# Build only the S3-required components to keep image size down
# -------------------------
RUN git clone https://github.com/aws/aws-sdk-cpp.git && \
    cd aws-sdk-cpp && \
    git checkout 1.11.350 && \
    git submodule update --init --recursive && \
    mkdir build && cd build && \
    cmake .. -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DBUILD_ONLY="s3;identity-management;sts;cognito-identity;transfer;config" \
      -DBUILD_SHARED_LIBS=ON \
      -DENABLE_TESTING=OFF \
      -DCMAKE_PREFIX_PATH=/usr/local \
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5 && \
    ninja && ninja install && \
    rm -rf /opt/build/aws-sdk-cpp

# -------------------------
# xsimd 13.2.0 (Arrow 23.0.1 dependency, requires >= 13.0.0, header-only)
# Kitware cmake >=3.31 errors on cmake_minimum_required(<3.5).  Arrow's
# ExternalProject_Add for xsimd_ep does not pass CMAKE_POLICY_VERSION_MINIMUM,
# so it fails.  Pre-installing xsimd lets Arrow find it via find_package and
# skip the bundled build entirely.
# -------------------------
RUN curl -fsSL https://github.com/xtensor-stack/xsimd/archive/refs/tags/13.2.0.tar.gz | tar -xz && \
    cd xsimd-13.2.0 && \
    mkdir build && cd build && \
    cmake .. -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
      -DBUILD_TESTS=OFF && \
    ninja install && \
    rm -rf /opt/build/xsimd-13.2.0

# -------------------------
# Apache Arrow 23.0.1 (CUDA + S3 enabled)
# xsimd_SOURCE=SYSTEM: use the pre-installed xsimd above; avoids the
# ExternalProject_Add that fails with newer cmake.
# -------------------------
RUN curl -fsSL https://archive.apache.org/dist/arrow/arrow-23.0.1/apache-arrow-23.0.1.tar.gz | tar -xz && \
    cd apache-arrow-23.0.1/cpp && \
    mkdir build && cd build && \
    cmake .. -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DARROW_BUILD_SHARED=ON \
      -DARROW_BUILD_STATIC=OFF \
      -DARROW_COMPUTE=OFF \
      -DARROW_DATASET=OFF \
      -DARROW_FILESYSTEM=ON \
      -DARROW_WITH_ZLIB=ON \
      -DARROW_WITH_ZSTD=ON \
      -DARROW_WITH_SNAPPY=ON \
      -DARROW_WITH_LZ4=ON \
      -DARROW_WITH_BROTLI=ON \
      -DARROW_BUILD_TESTS=OFF \
      -DARROW_FLIGHT=OFF \
      -DARROW_CSV=ON \
      -DARROW_JSON=ON \
      -DARROW_S3=ON \
      -DARROW_SIMD_LEVEL=${ARROW_SIMD_LEVEL} \
      -DARROW_CUDA=OFF \
      -Dxsimd_SOURCE=SYSTEM \
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5 && \
    ninja && ninja install && \
    rm -rf /opt/build/apache-arrow-23.0.1

# -------------------------
# OpenTelemetry C++ v1.26.0
# -------------------------
RUN git clone https://github.com/open-telemetry/opentelemetry-cpp.git && \
    cd opentelemetry-cpp && \
    git checkout v1.26.0 && \
    mkdir build && cd build && \
    cmake .. -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DWITH_OTLP_GRPC=ON \
      -DWITH_OTLP_HTTP=ON \
      -DBUILD_TESTING=OFF \
      -DWITH_BENCHMARK=OFF \
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
      -DBUILD_SHARED_LIBS=ON && \
    ninja && ninja install && \
    rm -rf /opt/build/opentelemetry-cpp

# -------------------------
# FlatBuffers v25.12.19
# -------------------------
RUN curl -fsSL https://github.com/google/flatbuffers/archive/refs/tags/v25.12.19.tar.gz | tar -xz && \
    cd flatbuffers-25.12.19 && \
    mkdir build && cd build && \
    cmake .. -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DFLATBUFFERS_BUILD_TESTS=OFF \
      -DFLATBUFFERS_BUILD_SHAREDLIB=ON \
      -DFLATBUFFERS_BUILD_FLATLIB=OFF && \
    ninja && ninja install && \
    rm -rf /opt/build/flatbuffers-25.12.19

# -------------------------
# nats.c v3.12.0
# Built and installed before nats-cpp (natscpp cmake requires libnats).
# Build dir kept alive so we can re-install after natscpp overwrites
# nats/nats.h with its #include_next shim.
# -------------------------
RUN curl -fsSL https://github.com/nats-io/nats.c/archive/refs/tags/v3.12.0.tar.gz | tar -xz && \
    cd nats.c-3.12.0 && \
    mkdir build && cd build && \
    cmake .. -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DNATS_BUILD_WITH_TLS=ON \
      -DNATS_BUILD_STREAMING=OFF \
      -DBUILD_SHARED_LIBS=ON && \
    ninja && ninja install

# -------------------------
# nats-cpp (header-only, main)
# Installs a nats/nats.h shim (uses #include_next) that overwrites the
# real libnats header. Re-run nats.c install afterward to restore it.
# -------------------------
RUN git clone https://github.com/hurdad/nats-cpp.git && \
    cd nats-cpp && \
    mkdir build && cd build && \
    cmake .. -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DBUILD_TESTING=OFF \
      -DNATSCPP_BUILD_EXAMPLES=OFF && \
    ninja install && \
    rm -rf /opt/build/nats-cpp && \
    cd /opt/build/nats.c-3.12.0/build && ninja install && \
    rm -rf /opt/build/nats.c-3.12.0

# =========================
# Stage: Test (smoke tests)
# =========================
FROM builder AS test

ENV LD_PRELOAD=/usr/local/lib/libjemalloc.so
ENV MALLOC_CONF=background_thread:true,metadata_thp:auto,dirty_decay_ms:5000,muzzy_decay_ms:5000,narenas:4
ENV LD_LIBRARY_PATH=/usr/local/lib

COPY tests/ /tests/

# Build C++ tests
RUN cd /tests && \
    mkdir build && cd build && \
    cmake .. -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_PREFIX_PATH=/usr/local && \
    ninja

# Run C++ tests
RUN /tests/build/test_libs


# =========================
# Stage: Test-libs (upstream library test suites)
# =========================
FROM builder AS test-libs

ARG ARROW_SIMD_LEVEL

ENV LD_LIBRARY_PATH=/usr/local/lib

WORKDIR /opt/test

# -------------------------
# jemalloc
# -------------------------
RUN git clone https://github.com/jemalloc/jemalloc.git && \
    cd jemalloc && \
    git checkout 5.3.0 && \
    ./autogen.sh && \
    ./configure \
      --prefix=/usr/local \
      --enable-prof \
      --enable-stats \
      --enable-background-thread && \
    make -j$(nproc) && \
    make check_unit && \
    make check_stress

# -------------------------
# fmt 12.1.0
# -------------------------
RUN curl -fsSL https://github.com/fmtlib/fmt/archive/refs/tags/12.1.0.tar.gz | tar -xz && \
    cd fmt-12.1.0 && \
    mkdir build && cd build && \
    cmake .. -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DBUILD_SHARED_LIBS=ON \
      -DFMT_TEST=ON \
      -DFMT_DOC=OFF && \
    ninja && \
    ctest --output-on-failure -j$(nproc)

# -------------------------
# spdlog v1.17.0
# -------------------------
RUN curl -fsSL https://github.com/gabime/spdlog/archive/refs/tags/v1.17.0.tar.gz | tar -xz && \
    cd spdlog-1.17.0 && \
    mkdir build && cd build && \
    cmake .. -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DBUILD_SHARED_LIBS=ON \
      -DSPDLOG_FMT_EXTERNAL=ON \
      -DSPDLOG_BUILD_EXAMPLE=OFF \
      -DSPDLOG_BUILD_TESTS=ON && \
    ninja && \
    ctest --output-on-failure -j$(nproc)

# -------------------------
# Abseil
# -------------------------
RUN git clone https://github.com/abseil/abseil-cpp.git && \
    cd abseil-cpp && \
    git checkout 20240116.2 && \
    mkdir build && cd build && \
    cmake .. -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DABSL_BUILD_TESTING=ON \
      -DABSL_USE_EXTERNAL_GOOGLETEST=ON \
      -DABSL_USE_GOOGLETEST_HEAD=OFF && \
    ninja && \
    ctest --output-on-failure -j$(nproc) -E "absl_time_test|absl_mutex_test"

# -------------------------
# Protobuf
# -------------------------
RUN git clone https://github.com/protocolbuffers/protobuf.git && \
    cd protobuf && \
    git checkout v27.3 && \
    git submodule update --init --recursive && \
    mkdir build && cd build && \
    cmake .. -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -Dprotobuf_ABSL_PROVIDER=package \
      -Dprotobuf_BUILD_TESTS=OFF && \
    ninja

# -------------------------
# xsimd
# -------------------------
RUN curl -fsSL https://github.com/xtensor-stack/xsimd/archive/refs/tags/13.2.0.tar.gz | tar -xz && \
    cd xsimd-13.2.0 && \
    mkdir build && cd build && \
    cmake .. -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
      -DBUILD_TESTS=ON \
      -DDOWNLOAD_DOCTEST=ON && \
    ninja && \
    ctest --output-on-failure -j$(nproc)

# -------------------------
# FlatBuffers
# -------------------------
RUN curl -fsSL https://github.com/google/flatbuffers/archive/refs/tags/v25.12.19.tar.gz | tar -xz && \
    cd flatbuffers-25.12.19 && \
    mkdir build && cd build && \
    cmake .. -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DFLATBUFFERS_BUILD_TESTS=ON && \
    ninja && \
    ctest --output-on-failure -j$(nproc)

# -------------------------
# Arrow C++ (non-CUDA tests; CUDA tests require --runtime=nvidia at runtime)
# -------------------------
RUN curl -fsSL https://archive.apache.org/dist/arrow/arrow-23.0.1/apache-arrow-23.0.1.tar.gz | tar -xz && \
    cd apache-arrow-23.0.1/cpp && \
    mkdir build && cd build && \
    cmake .. -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DARROW_BUILD_SHARED=ON \
      -DARROW_BUILD_STATIC=OFF \
      -DARROW_COMPUTE=OFF \
      -DARROW_DATASET=OFF \
      -DARROW_FILESYSTEM=ON \
      -DARROW_WITH_ZLIB=ON \
      -DARROW_WITH_ZSTD=ON \
      -DARROW_WITH_SNAPPY=ON \
      -DARROW_WITH_LZ4=ON \
      -DARROW_WITH_BROTLI=ON \
      -DARROW_SIMD_LEVEL=${ARROW_SIMD_LEVEL} \
      -DARROW_CUDA=OFF \
      -DARROW_BUILD_TESTS=ON \
      -DARROW_FLIGHT=OFF \
      -DARROW_S3=ON \
      -Dxsimd_SOURCE=SYSTEM \
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5 && \
    ninja && \
    ctest --output-on-failure -j$(nproc) -E "cuda|gpu|s3fs|json-integration|ipc-read-write|compute-scalar-cast"

# -------------------------
# OpenTelemetry C++
# -------------------------
RUN git clone https://github.com/open-telemetry/opentelemetry-cpp.git && \
    cd opentelemetry-cpp && \
    git checkout v1.26.0 && \
    mkdir build && cd build && \
    cmake .. -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DWITH_OTLP_GRPC=ON \
      -DWITH_OTLP_HTTP=ON \
      -DBUILD_TESTING=ON \
      -DWITH_BENCHMARK=OFF \
      -DWITH_EXAMPLES=OFF \
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5 && \
    ninja && \
    ctest --output-on-failure -j$(nproc) -E "BasicCurlHttp"

# -------------------------
# nats.c v3.12.0
# -------------------------
RUN curl -fsSL https://github.com/nats-io/nats.c/archive/refs/tags/v3.12.0.tar.gz | tar -xz && \
    cd nats.c-3.12.0 && \
    mkdir build && cd build && \
    cmake .. -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DNATS_BUILD_WITH_TLS=ON \
      -DNATS_BUILD_STREAMING=OFF \
      -DNATS_BUILD_TESTS=OFF && \
    ninja

# =========================
# Stage: Dev Image
# =========================
FROM builder AS dev

ENV LD_PRELOAD=/usr/local/lib/libjemalloc.so
ENV MALLOC_CONF=background_thread:true,metadata_thp:auto,dirty_decay_ms:5000,muzzy_decay_ms:5000,narenas:4
ENV LD_LIBRARY_PATH=/usr/local/lib

RUN rm -rf /opt/build && ldconfig

WORKDIR /workspace

CMD ["/bin/bash"]

# =========================
# Stage: Runtime Image
# =========================
FROM ubuntu:24.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    libstdc++6 \
    ca-certificates \
    libssl3 \
    zlib1g \
    libzstd1 \
    libsnappy1v5 \
    liblz4-1 \
    libbrotli1 \
    libutf8proc3 \
    libcurl4 && \
    rm -rf /var/lib/apt/lists/*

# Copy only runtime artifacts
COPY --from=builder /usr/local/lib /usr/local/lib
RUN rm -f /usr/local/lib/libgtest*.so* /usr/local/lib/libgmock*.so*

RUN ldconfig

# Strip symbols to reduce size
RUN find /usr/local/lib -name "*.so*" -exec strip --strip-unneeded {} + || true

# jemalloc tuning
ENV LD_PRELOAD=/usr/local/lib/libjemalloc.so
ENV MALLOC_CONF=background_thread:true,metadata_thp:auto,dirty_decay_ms:5000,muzzy_decay_ms:5000,narenas:4
ENV LD_LIBRARY_PATH=/usr/local/lib

WORKDIR /app

CMD ["/bin/bash"]