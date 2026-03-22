cmake_minimum_required(VERSION 3.22)
project(docker_jetpack_tests)

set(CMAKE_CXX_STANDARD 20)

find_package(Arrow REQUIRED)
find_package(ArrowCUDA REQUIRED)
find_package(Parquet REQUIRED)
find_package(gRPC REQUIRED)
find_package(Protobuf REQUIRED)
find_package(Flatbuffers REQUIRED)
find_package(natscpp REQUIRED)

add_executable(test_libs test_libs.cpp)

target_link_libraries(test_libs PRIVATE
    Arrow::arrow_shared
    ArrowCUDA::arrow_cuda_shared
    Parquet::parquet_shared
    gRPC::grpc++
    protobuf::libprotobuf
    flatbuffers::flatbuffers
    jemalloc
    natscpp::natscpp
)
