cmake_minimum_required (VERSION 2.6)
project (LuaGumbo C)

set(CMAKE_C_STANDARD_REQUIRED true)
set(CMAKE_C_STANDARD 99)

if(UNIX)
  set(CMAKE_POSITION_INDEPENDENT_CODE ON)
endif()

# Lua
if(WIN32)
  find_package (Lua REQUIRED)
else()
  # Only the include dir matters on UNIX
  find_package (Lua)
  if(NOT LUA_INCLUDE_DIR)
    message( FATAL_ERROR "Variable `LUA_INCLUDE_DIR' expected to be defined.")
  endif()
endif()

# Gumbo
set(LIB_INCLUDE_DIR ${PROJECT_SOURCE_DIR}/lib)
set(WINDOWS_LIB_INCLUDE_DIR ${LIB_INCLUDE_DIR}/visualc/include)
set(LIBGUMBO_OBJ attribute char_ref error parser string_buffer string_piece svg_attrs svg_tags tag tag_lookup tokenizer utf8 util vector)

include(mk/lib-deps.cmake)

foreach(LIB_NAME ${LIBGUMBO_OBJ})
  list(APPEND LIBGUMBO_TARGET_OBJECTS "$<TARGET_OBJECTS:${LIB_NAME}>")
endforeach(LIB_NAME)

include_directories( ${LIB_INCLUDE_DIR} )
if (WIN32)
  include_directories( ${WINDOWS_LIB_INCLUDE_DIR} )
endif()

# Lua-Gumbo
add_library( parse MODULE gumbo/parse.c ${LIBGUMBO_TARGET_OBJECTS} )
set_target_properties( parse PROPERTIES PREFIX "" )
target_include_directories( parse PRIVATE ${LUA_INCLUDE_DIR} )
if(WIN32)
  target_compile_definitions( parse PRIVATE _CRT_SECURE_NO_WARNINGS )
endif()

# Only link against the Lua library on Windows
if(WIN32)
  target_link_libraries( parse ${LUA_LIBRARIES} )
endif()

# Needed to avoid getting undefined references to liblua
if(APPLE)
  set(CMAKE_SHARED_MODULE_CREATE_C_FLAGS "${CMAKE_SHARED_MODULE_CREATE_C_FLAGS} -undefined dynamic_lookup")
endif()

# avoid 'Invalid escape sequence \X' errors from backslashes in the path
FUNCTION(win32_safe_slashes var)
  if(WIN32)
    string(REPLACE "\\" "/" safe "${${var}}")
    set(${var} "${safe}" PARENT_SCOPE)
  endif()
ENDFUNCTION()

# Install targets for Luarocks and non-Luarocks
# Luarocks: Install *.lua and binary to the Luarocks systree
# UNIX: Install *.lua and *.so to default Lua package.path/cpath directory
# WIN32: Default package.path/cpath is relative to the running Lua exe, so there
#        is no standard install path that can be used. Instead, only parse.dll
#        is copied to gumbo/ relative to the project source dir, so that require('gumbo')
#        works if Lua is run from the project source dir.
if(LUAROCKS_INSTALL_LIBDIR)
  SET(INSTALL_LIB_DIR ${LUAROCKS_INSTALL_LIBDIR})
elseif(UNIX)
  set(INSTALL_LIB_DIR "${CMAKE_INSTALL_PREFIX}/lib/lua/${LUA_VERSION_MAJOR}.${LUA_VERSION_MINOR}")
elseif(WIN32)
  set(INSTALL_LIB_DIR "${PROJECT_SOURCE_DIR}")
endif()

if(INSTALL_LIB_DIR)
  win32_safe_slashes(INSTALL_LIB_DIR)
  install(TARGETS parse ARCHIVE DESTINATION "${INSTALL_LIB_DIR}/gumbo" LIBRARY DESTINATION "${INSTALL_LIB_DIR}/gumbo")
endif()

if(LUAROCKS_INSTALL_LUADIR)
  SET(INSTALL_LUA_DIR ${LUAROCKS_INSTALL_LUADIR})
elseif(UNIX)
  SET(INSTALL_LUA_DIR "${CMAKE_INSTALL_PREFIX}/lib/lua/${LUA_VERSION_MAJOR}.${LUA_VERSION_MINOR}")
endif()

if(INSTALL_LUA_DIR)
  win32_safe_slashes(INSTALL_LUA_DIR)
  install(FILES gumbo.lua DESTINATION "${INSTALL_LUA_DIR}")
  install(DIRECTORY gumbo/ DESTINATION "${INSTALL_LUA_DIR}/gumbo" FILES_MATCHING PATTERN "*.lua")
endif()
