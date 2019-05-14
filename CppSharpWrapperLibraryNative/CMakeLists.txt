cmake_minimum_required(VERSION 3.0)

set (CPPSHARP_GENERATED_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../bin/cppsharp)
set (INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../bin/inc)
set(LIB_TYPE SHARED)

include_directories(${INCLUDE_DIR})

add_library(Std-symbols ${LIB_TYPE} ${CPPSHARP_GENERATED_DIR}/Std-symbols.cpp)

install(TARGETS Std-symbols)
