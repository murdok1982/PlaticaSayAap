cmake_minimum_required(VERSION 3.22.1)
project(platica_whisper_bridge C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)

set(WHISPER_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_SERVER OFF CACHE BOOL "" FORCE)
set(GGML_OPENMP OFF CACHE BOOL "" FORCE)

add_subdirectory(
    ${CMAKE_CURRENT_SOURCE_DIR}/../whisper.cpp
    whisper.cpp-build
)

add_library(platica_whisper SHARED ${CMAKE_CURRENT_SOURCE_DIR}/../whisper_bridge.cpp)
target_include_directories(platica_whisper PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/../whisper.cpp/include
    ${CMAKE_CURRENT_SOURCE_DIR}/../whisper.cpp/ggml/include
)
target_link_libraries(platica_whisper PRIVATE whisper log android)
