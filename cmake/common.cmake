macro(process_subdirs)
  set(SUBDIR_EXP "*")
  if(${ARGC} GREATER 1)
    set(SUBDIR_EXP ${ARGV})
  endif()
  file(GLOB subdirs ${SUBDIR_EXP})
  foreach(dir ${subdirs})
    if(IS_DIRECTORY ${dir} AND EXISTS ${dir}/CMakeLists.txt)
      get_filename_component(subdir ${dir} NAME)
      add_subdirectory(${subdir})
    endif()
  endforeach()
endmacro()

function(cms_add_interface name)
  set(multiValueArgs INTERFACE)
  cmake_parse_arguments(cms_add_interface "" "" "${multiValueArgs}" ${ARGN})
  foreach(dep ${cms_add_interface_INTERFACE})
    cms_find_package (${dep})
  endforeach()
  add_library(${name} INTERFACE)
  foreach(inc ${INCLUDE_DIRS})
    target_include_directories(${name} INTERFACE ${inc})
  endforeach()
  if(LIBS)
    target_link_libraries (${name} INTERFACE ${LIBS})
  endif()
  install(TARGETS ${name} EXPORT "cmssw" DESTINATION lib)
endfunction()

function(cms_add_library name)
  set(multiValueArgs SOURCES PUBLIC)
  message("Processing library ${name}")
  cmake_parse_arguments(cms_add_library "" "" "${multiValueArgs}" ${ARGN})
  foreach(dep ${cms_add_library_PUBLIC})
    cms_find_package (${dep})
  endforeach()
  file(GLOB PRODUCT_SOURCES ${cms_add_library_SOURCES})
  add_library(${name} SHARED ${PRODUCT_SOURCES} ${${name}_EXTRA_SOURCES})
  target_compile_definitions(${name} PRIVATE ${PROJECT_CPPDEFINES})
  target_compile_options(${name} PRIVATE ${PROJECT_CXXFLAGS})
  list(REMOVE_DUPLICATES INCLUDE_DIRS)
  foreach(inc ${INCLUDE_DIRS})
    target_include_directories(${name} PUBLIC ${inc})
  endforeach()
  if(LIBS)
    list(REMOVE_DUPLICATES LIBS)
    target_link_libraries (${name} PUBLIC ${LIBS})
  endif()
  add_rootdict_rules(${name})
  if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/headers.h)
    condformat_serialization(${name} headers.h)
  endif()
  install(TARGETS ${name} EXPORT "cmssw" DESTINATION lib)
endfunction()

function(cms_add_binary name)
  set(multiValueArgs SOURCES PUBLIC)
  message("Processing binary ${name}")
  cmake_parse_arguments(cms_add_binary "" "" "${multiValueArgs}" ${ARGN})
  foreach(dep ${cms_add_binary_PUBLIC})
    cms_find_package (${dep})
  endforeach()
  file(GLOB PRODUCT_SOURCES ${cms_add_binary_SOURCES})
  add_executable(${name} ${PRODUCT_SOURCES})
  target_compile_definitions(${name} PRIVATE ${PROJECT_CPPDEFINES})
  target_compile_options(${name} PRIVATE ${PROJECT_CXXFLAGS})
  list(REMOVE_DUPLICATES INCLUDE_DIRS)
  foreach(inc ${INCLUDE_DIRS})
    target_include_directories(${name} PUBLIC ${inc})
  endforeach()
  if(LIBS)
    list(REMOVE_DUPLICATES LIBS)
    target_link_libraries (${name} LINK_PUBLIC ${LIBS})
  endif()
  install(TARGETS ${name} EXPORT "cmssw" DESTINATION bin)
endfunction()

macro(cms_find_package package)
  string(REPLACE "/" "" package_lib ${package})
  if(EXISTS ${CMAKE_SOURCE_DIR}/../cmssw-cmake/cmssw/Find${package_lib}.cmake)
    if(NOT ${package_lib}_FOUND)
      include(${CMAKE_SOURCE_DIR}/../cmssw-cmake/cmssw/Find${package_lib}.cmake)
      string(REPLACE "/" "" package_lib ${package})
      set(LIBS ${package_lib} ${LIBS})
    endif()
  elseif(EXISTS ${CMAKE_SOURCE_DIR}/../cmssw-cmake/tools/Find${package}.cmake)
    if(NOT ${package}_FOUND)
      include(${CMAKE_SOURCE_DIR}/../cmssw-cmake/tools/Find${package}.cmake)
    endif()
  elseif(EXISTS ${CMAKE_SOURCE_DIR}/../cmssw-cmake/coral/Find${package_lib}.cmake)
    if(NOT ${package_lib}_FOUND)
      include(${CMAKE_SOURCE_DIR}/../cmssw-cmake/coral/Find${package_lib}.cmake)
    endif()
  else()
   cms_find_library(${package_lib})
  endif()
endmacro()

macro(cms_find_library tool)
  foreach(lib ${ARGN})
    find_library(${tool}_LIB_${lib} NAMES ${lib} HINTS ${LIBRARY_DIR} $ENV{LD_LIBRARY_PATH})
    if(${${tool}_LIB_${lib}} STREQUAL "${tool}_LIB_${lib}-NOTFOUND")
      set(LIBS ${lib} ${LIBS})
    else()
      set(LIBS ${${tool}_LIB_${lib}} ${LIBS})
    endif()
  endforeach()
endmacro()

