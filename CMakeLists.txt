cmake_minimum_required(VERSION 3.24)
project(GalaxyQuest C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 11)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(DECOMP ${CMAKE_SOURCE_DIR}/decomp)

if(ANDROID)
  set(PORT_PLATFORM android)
else()
  set(PORT_PLATFORM linux)
  # Position-independent code: the executable sits at 0x98000000, beyond the
  # reach of x86-64's absolute 32-bit addressing.
  set(CMAKE_POSITION_INDEPENDENT_CODE ON)
endif()

# ---------------------------------------------------------------------------
# Decompiled game sources
# ---------------------------------------------------------------------------
file(GLOB_RECURSE GAME_SRCS CONFIGURE_DEPENDS ${DECOMP}/src/Game/*.cpp ${DECOMP}/src/Game/*.c)
file(GLOB_RECURSE JSYSTEM_SRCS CONFIGURE_DEPENDS ${DECOMP}/src/JSystem/*.cpp)
file(GLOB_RECURSE NW4R_SRCS CONFIGURE_DEPENDS ${DECOMP}/src/nw4r/*.cpp)

# SDK libraries that are pure software and are compiled from the decomp as-is.
set(SDK_MODULES gx gd mem arc tpl aralt)
set(SDK_SRCS)
foreach(m ${SDK_MODULES})
  file(GLOB_RECURSE _s CONFIGURE_DEPENDS ${DECOMP}/src/RVL_SDK/${m}/*.c)
  list(APPEND SDK_SRCS ${_s})
endforeach()

list(FILTER SDK_SRCS EXCLUDE REGEX "/gx/GXFifo\\.c$|/gx/GXPerf\\.c$")
# OS pieces that are pure software on top of the thread API.
list(APPEND SDK_SRCS ${DECOMP}/src/RVL_SDK/os/OSMutex.c ${DECOMP}/src/RVL_SDK/os/OSMessage.c)
# THP movie audio is plain C (the video decoder is replaced by platform/src/sdk/thp_video.cpp).
list(APPEND SDK_SRCS ${DECOMP}/src/RVL_SDK/thp/THPAudio.c)

set(DECOMP_INCLUDES
  ${CMAKE_SOURCE_DIR}/platform/include
  ${DECOMP}/include
  ${DECOMP}/libs/JSystem/include
  ${DECOMP}/libs/RVL_SDK/include
  ${DECOMP}/libs/nw4r/include
  ${DECOMP}/libs/RVLFaceLib/include
)

set(PORT_DEFS TARGET_PC=1 NDEBUG=1 VERSION=0)

# Paths in the binaries (__FILE__, debug info) relative to the repository
# and the NDK, not the machine that built them.
add_compile_options(-ffile-prefix-map=${CMAKE_SOURCE_DIR}/= -ffile-prefix-map=${CMAKE_SOURCE_DIR}=.)
if(ANDROID)
  add_compile_options(-ffile-prefix-map=${ANDROID_NDK}=ndk)
endif()

set(PORT_COMMON_FLAGS
  -fshort-wchar
  -fsigned-char
  -fno-strict-aliasing
  -fwrapv
  -ffp-contract=on
  -Wno-register
  -Wno-multichar
  -Wno-invalid-offsetof
  -Wno-c++11-narrowing
  -Wno-writable-strings
  -Wno-null-conversion
  -Wno-deprecated-declarations
  -Wno-int-to-pointer-cast
  -Wno-pointer-to-int-cast
  -Wno-invalid-source-encoding
  -Wno-unused-value
  -Wno-return-type
  -Wno-switch
  -Wno-parentheses
  -Wno-dangling-else
  -Wno-tautological-compare
  -Wno-tautological-undefined-compare
  -Wno-undefined-bool-conversion
  -Wno-constant-conversion
  -Wno-shift-negative-value
  -Wno-implicit-function-declaration
  -Wno-int-conversion
  -Wno-incompatible-pointer-types
  -Wno-incompatible-function-pointer-types
  -Wno-pointer-sign
  -Wno-unknown-pragmas
  -Wno-ignored-attributes
  -Wno-microsoft-template
  -fms-extensions
  -Wno-void-pointer-to-int-cast
  -Wno-microsoft-cast
  -Wno-microsoft-anon-tag
  -Wno-microsoft-include
  -Wno-language-extension-token
  -ferror-limit=0
  # With -fshort-wchar, newer clang turns port_wcslen's 16-bit loop into a
  # call to the C library's 32-bit wcslen.
  -fno-builtin-wcslen
  -include ${CMAKE_SOURCE_DIR}/platform/include/port/compat.h
)
if(NOT ANDROID AND CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64")
  # JKRHeap's operator new aligns to 4 bytes; clang's SSE stores to memory it
  # takes for 16-byte aligned fault on x86-64 (ARM allows them).  Not 4: types
  # holding a double would go to the aligned operator new, off the game heap.
  list(APPEND PORT_COMMON_FLAGS -fnew-alignment=8)
endif()
set(PORT_CXX_FLAGS -fno-exceptions -fno-rtti)
set(PORT_C_FLAGS)

add_library(decomp OBJECT ${GAME_SRCS} ${JSYSTEM_SRCS} ${NW4R_SRCS} ${SDK_SRCS})
target_include_directories(decomp PRIVATE ${DECOMP_INCLUDES})
target_compile_definitions(decomp PRIVATE ${PORT_DEFS})
target_compile_options(decomp PRIVATE ${PORT_COMMON_FLAGS} $<$<COMPILE_LANGUAGE:CXX>:${PORT_CXX_FLAGS}> $<$<COMPILE_LANGUAGE:C>:${PORT_C_FLAGS}>)

# ---------------------------------------------------------------------------
# Port platform layer + final game library
# ---------------------------------------------------------------------------
file(GLOB_RECURSE PLATFORM_SRCS CONFIGURE_DEPENDS
  ${CMAKE_SOURCE_DIR}/platform/src/*.c
  ${CMAKE_SOURCE_DIR}/platform/src/*.cpp)

if(ANDROID)
  add_library(game SHARED $<TARGET_OBJECTS:decomp> ${PLATFORM_SRCS})
else()
  # Linux (Steam Frame): one executable, linked where libgame.so loads on
  # Android; platform/linux/main.c reserves the game's window around it.
  add_library(launcher OBJECT platform/linux/main.c platform/android/headless.c)
  target_include_directories(launcher PRIVATE platform/include)
  add_executable(game $<TARGET_OBJECTS:decomp> $<TARGET_OBJECTS:launcher> ${PLATFORM_SRCS})
  set_target_properties(game PROPERTIES OUTPUT_NAME galaxyquest)
endif()
target_include_directories(game PRIVATE ${DECOMP_INCLUDES})
target_compile_definitions(game PRIVATE ${PORT_DEFS} PORT_PLATFORM_CODE=1)
target_compile_options(game PRIVATE ${PORT_COMMON_FLAGS} $<$<COMPILE_LANGUAGE:CXX>:${PORT_CXX_FLAGS}> $<$<COMPILE_LANGUAGE:C>:${PORT_C_FLAGS}>)
target_link_options(game PRIVATE -Wl,--no-undefined -Wl,--error-limit=0)
if(ANDROID)
  # -Bsymbolic: game code must bind to the port's operator new/delete, not the
  # system C++ runtime's.
  target_link_options(game PRIVATE -Wl,-Bsymbolic -Wl,--gc-sections)
  target_link_libraries(game PRIVATE log android)
endif()

if(NOT ANDROID)
  # The OpenXR loader is shipped next to the executable ($ORIGIN), with the
  # libjsoncpp.so.26 it needs (SteamOS has .25).  An RPATH, unlike a RUNPATH,
  # also covers the loader's own dependencies.
  find_library(OPENXR_LOADER NAMES openxr_loader REQUIRED)
  target_link_options(game PRIVATE -fuse-ld=lld -no-pie -Wl,--image-base=0x98000000 -Wl,--disable-new-dtags -Wl,-rpath,$ORIGIN)
  target_link_libraries(game PRIVATE ${OPENXR_LOADER} EGL GLESv2 asound pthread dl m)
  if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64")
    # x86-64's non-PIE start files address absolutely below 2 GB; -B swaps in
    # the PIE ones, which work at 0x98000000 (a PC build, for testing).
    set(PIE_CRT ${CMAKE_BINARY_DIR}/pie-crt)
    file(MAKE_DIRECTORY ${PIE_CRT})
    foreach(pair crt1.o:Scrt1.o crtbegin.o:crtbeginS.o crtend.o:crtendS.o)
      string(REPLACE ":" ";" pair ${pair})
      list(GET pair 0 name)
      list(GET pair 1 pie)
      execute_process(COMMAND ${CMAKE_CXX_COMPILER} -print-file-name=${pie} OUTPUT_VARIABLE path OUTPUT_STRIP_TRAILING_WHITESPACE)
      file(CREATE_LINK ${path} ${PIE_CRT}/${name} SYMBOLIC)
    endforeach()
    target_link_options(game PRIVATE -B${PIE_CRT})
  endif()
endif()

if(ANDROID)
  # The Khronos OpenXR loader (tools/fetch_openxr.sh puts it there).
  set(OPENXR_DIR ${CMAKE_SOURCE_DIR}/third_party/openxr/prefab/modules)
  set(GLUE_DIR ${ANDROID_NDK}/sources/android/native_app_glue)

  add_library(openxr_loader SHARED IMPORTED)
  set_target_properties(openxr_loader PROPERTIES IMPORTED_LOCATION ${OPENXR_DIR}/openxr_loader/libs/android.arm64-v8a/libopenxr_loader.so)

  target_include_directories(game PRIVATE ${OPENXR_DIR}/headers/include ${GLUE_DIR})
  target_link_libraries(game PRIVATE openxr_loader EGL GLESv3 aaudio)

  # Launcher: reserves the 32-bit game window and loads libgame.so into it.
  add_library(main SHARED platform/android/launcher.c ${GLUE_DIR}/android_native_app_glue.c)
  target_include_directories(main PRIVATE ${GLUE_DIR})
  target_link_libraries(main PRIVATE android log dl)
  target_link_options(main PRIVATE -u ANativeActivity_onCreate)

  # Preloaded into the app process by wrap.sh: reserves the game window before
  # ART lays out its heap.
  add_library(reserve SHARED platform/android/reserve.c)
  target_link_libraries(reserve PRIVATE log)

  # Bring-up tool: boots libgame.so from an adb shell without VR.
  add_executable(petari_headless platform/android/headless.c)
  target_link_libraries(petari_headless PRIVATE log dl m)
  target_include_directories(petari_headless PRIVATE platform/include)
endif()
