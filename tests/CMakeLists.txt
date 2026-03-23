cmake_minimum_required(VERSION 3.22)
project(docker_jetpack_tests)

set(CMAKE_CXX_STANDARD 20)

find_package(Arrow REQUIRED)
find_package(ArrowCUDA REQUIRED)
find_package(gRPC REQUIRED)
find_package(Protobuf REQUIRED)
find_package(Flatbuffers REQUIRED)
find_package(AWSSDK REQUIRED COMPONENTS core)
find_package(opentelemetry-cpp REQUIRED)
find_package(PkgConfig REQUIRED)
pkg_check_modules(NATS REQUIRED IMPORTED_TARGET libnats)
find_package(natscpp REQUIRED)

# Main smoke test — no CUDA link so it runs during docker build without --runtime=nvidia
add_executable(test_libs test_libs.cpp)
target_link_libraries(test_libs PRIVATE
    Arrow::arrow_shared
    gRPC::grpc++
    protobuf::libprotobuf
    flatbuffers::flatbuffers_shared
    jemalloc
    natscpp::natscpp
    AWS::aws-sdk-cpp-core
    opentelemetry_trace
    opentelemetry_metrics
    opentelemetry_logs
    opentelemetry_sdk
)

# CUDA smoke test — requires --runtime=nvidia at runtime; built but not run during build
add_executable(test_libs_cuda test_libs_cuda.cpp)
target_link_libraries(test_libs_cuda PRIVATE
    Arrow::arrow_shared
    ArrowCUDA::arrow_cuda_shared
)
