cmake_minimum_required(VERSION 3.16)
project(PenumbraOverture CXX C)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 11)

# The engine lives in its own repository; point at a different checkout with
#   cmake -DHPL1_ENGINE_DIR=/path/to/HPL1-Fledged
set(HPL1_ENGINE_DIR "${CMAKE_SOURCE_DIR}/../../HPL1-Fledged"
    CACHE PATH "Where the HPL1 engine is checked out")

if(NOT EXISTS "${HPL1_ENGINE_DIR}/CMakeLists.txt")
	message(FATAL_ERROR
		"HPL1 engine not found at ${HPL1_ENGINE_DIR}.\n"
		"Clone it next to this port, or pass -DHPL1_ENGINE_DIR=<path>.")
endif()

add_subdirectory(${HPL1_ENGINE_DIR} engine)

# The engine looks for its shaders under rehatched/core/programs beside the
# game data, so they are placed there rather than referenced in place.
file(COPY ${HPL1_SHADER_DIR}/ DESTINATION ${CMAKE_SOURCE_DIR}/rehatched/core/programs)

# ---- game --------------------------------------------------------------------
file(GLOB_RECURSE game_src ${CMAKE_SOURCE_DIR}/PenumbraOverture/src/*.cpp)
add_executable(PenumbraOverture ${game_src})
target_link_libraries(PenumbraOverture PRIVATE HPL)
