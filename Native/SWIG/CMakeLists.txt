
if (WIN32)
    SET(SWIG_DIR C:/Users/jekoritz/Downloads/swigwin-3.0.12/swigwin-3.0.12/Lib)
    SET(SWIG_EXECUTABLE C:/Users/jekoritz/Downloads/swigwin-3.0.12/swigwin-3.0.12/swig.exe)
endif()

cmake_policy(SET CMP0078 NEW)
cmake_policy(SET CMP0086 NEW)
FIND_PACKAGE(SWIG REQUIRED)
include(UseSWIG)

set (UseSWIG_TARGET_NAME_PREFERENCE STANDARD)
set (SWIG_CSHARP_OUTPUT_DIR ${CMAKE_CURRENT_BINARY_DIR}/csharp)

set(SWIG_SOURCES mapping.i)
get_property(dirs DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY INCLUDE_DIRECTORIES)

set_source_files_properties(${SWIG_SOURCES} PROPERTIES
    CPLUSPLUS ON
    SWIG_MODULE_NAME Native
    USE_TARGET_INCLUDE_DIRECTORIES TRUE
    SWIG_INCLUDE_DIRECTORIES ${dirs}
    SWIG_GENERATED_INCLUDE_DIRECTORIES ${dirs}
    SWIG_FLAGS "-includeall")

swig_add_library(mapping
    TYPE SHARED
    LANGUAGE csharp
    SOURCES ${SWIG_SOURCES}
    OUTPUT_DIR ${SWIG_CSHARP_OUTPUT_DIR}
)
set (SWIG_MODULE_mapping_EXTRA_DEPS string)

set_property(TARGET mapping PROPERTY
    SWIG_USE_LIBRARY_INCLUDE_DIRECTORIES TRUE)

target_link_libraries(mapping Native)

install(TARGETS mapping DESTINATION swig)
install(DIRECTORY ${SWIG_CSHARP_OUTPUT_DIR} DESTINATION swig)
