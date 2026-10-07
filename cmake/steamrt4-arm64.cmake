# Cross-compiles the Linux build for the Steam Frame (arm64) with clang and lld
# against Valve's Steam Runtime 4 arm64 SDK sysroot (STEAMRT4_ARM64_SYSROOT).
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)
# Kept in the cache: CMake reads this file again whenever it configures anew,
# also when Ninja re-runs it without the variable set.
if(DEFINED ENV{STEAMRT4_ARM64_SYSROOT})
  set(STEAMRT4_ARM64_SYSROOT "$ENV{STEAMRT4_ARM64_SYSROOT}" CACHE PATH "Steam Runtime 4 arm64 SDK sysroot" FORCE)
endif()
set(CMAKE_SYSROOT "${STEAMRT4_ARM64_SYSROOT}")
set(CMAKE_C_COMPILER clang)
set(CMAKE_CXX_COMPILER clang++)
set(CMAKE_C_COMPILER_TARGET aarch64-linux-gnu)
set(CMAKE_CXX_COMPILER_TARGET aarch64-linux-gnu)
# GCC (libstdc++, start files) from usr/lib rather than through the sysroot's
# lib -> usr/lib link: the header paths in the dependency files then exist as
# written, and Ninja rebuilds only what changed.
file(GLOB _gcc_dirs LIST_DIRECTORIES true "${CMAKE_SYSROOT}/usr/lib/gcc/aarch64-linux-gnu/*")
if(_gcc_dirs)
  list(SORT _gcc_dirs COMPARE NATURAL)
  list(GET _gcc_dirs -1 _gcc_dir)
  set(CMAKE_C_FLAGS_INIT "--gcc-install-dir=${_gcc_dir}")
  set(CMAKE_CXX_FLAGS_INIT "--gcc-install-dir=${_gcc_dir}")
endif()
set(CMAKE_EXE_LINKER_FLAGS_INIT -fuse-ld=lld)
set(CMAKE_SHARED_LINKER_FLAGS_INIT -fuse-ld=lld)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
