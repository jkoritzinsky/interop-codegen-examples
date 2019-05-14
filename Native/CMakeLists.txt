cmake_minimum_required (VERSION 3.0)

project (Native)

include(GenerateExportHeader)

set(LIB_TYPE SHARED)

set(SOURCES Native.cpp)

add_library(Native ${LIB_TYPE} ${SOURCES})
generate_export_header(Native)

set_property(TARGET Native PROPERTY INCLUDE_INSTALL_DIR .)

include_directories(PUBLIC ${CMAKE_CURRENT_BINARY_DIR})

add_subdirectory(SWIG)

install(FILES
 Native.h
 ${PROJECT_BINARY_DIR}/native_export.h DESTINATION inc
)

install(TARGETS Native)