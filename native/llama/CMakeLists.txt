cmake_minimum_required(VERSION 3.22.1)
project(platica_llama_bridge C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)

set(LLAMA_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_SERVER OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_TOOLS OFF CACHE BOOL "" FORCE)
set(GGML_OPENMP OFF CACHE BOOL "" FORCE)

add_subdirectory(
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama.cpp
    llama.cpp-build
)

add_library(platica_llama SHARED ${CMAKE_CURRENT_SOURCE_DIR}/../llama_bridge.cpp)
target_include_directories(platica_llama PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama.cpp/include
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama.cpp/ggml/include
)
target_link_libraries(platica_llama PRIVATE llama log android)
