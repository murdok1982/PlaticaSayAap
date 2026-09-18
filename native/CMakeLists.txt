cmake_minimum_required(VERSION 3.22.1)
project(platica_native C CXX)

set(CMAKE_CXX_STANDARD 17)

set(WHISPER_CPP_DIR ${CMAKE_CURRENT_SOURCE_DIR}/whisper.cpp)
set(LLAMA_CPP_DIR ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp)

add_library(platica_whisper SHARED whisper_bridge.cpp)
add_library(platica_llama SHARED llama_bridge.cpp)

target_include_directories(platica_whisper PRIVATE ${WHISPER_CPP_DIR}/include ${WHISPER_CPP_DIR}/ggml/include)
target_include_directories(platica_llama PRIVATE ${LLAMA_CPP_DIR}/include ${LLAMA_CPP_DIR}/ggml/include)

target_link_libraries(platica_whisper whisper ggml log)
target_link_libraries(platica_llama llama ggml log)
