#!/bin/bash
# Configures and builds the Linux target: build-linux-<arch>/galaxyquest.
#   ./build_linux.sh                    this machine (a PC, to test)
#   ARCH=arm64 STEAMRT4_ARM64_SYSROOT=<sysroot> ./build_linux.sh
#                                       the Steam Frame, against Valve's Steam
#                                       Runtime 4 arm64 SDK sysroot; also packs
#                                       GalaxyQuest-SteamFrame-arm64.tar.gz
# Needs clang 16+, lld, CMake 3.24+ and Ninja; natively also the EGL, GLES,
# ALSA and OpenXR loader development files.
set -e
cd "$(dirname "$0")"
ARCH=${ARCH:-native}
BUILD=${BUILD:-build-linux-$ARCH}
if [ "$ARCH" = arm64 ]; then
  # Every time: CMake reads it again whenever it configures anew.
  [ -d "$STEAMRT4_ARM64_SYSROOT/usr" ] || { echo "set STEAMRT4_ARM64_SYSROOT to the arm64 SDK sysroot" >&2; exit 1; }
fi
if [ ! -f $BUILD/build.ninja ]; then
  args=()
  if [ "$ARCH" = arm64 ]; then
    args+=(-DCMAKE_TOOLCHAIN_FILE=cmake/steamrt4-arm64.cmake)
  fi
  cmake -S . -B $BUILD -G Ninja -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_BUILD_TYPE=${CONFIG:-RelWithDebInfo} "${args[@]}"
fi
ninja -C $BUILD "$@"
if [ "$ARCH" = arm64 ]; then
  # The OpenXR loader and its JSON library go next to the executable (rpath
  # $ORIGIN): SteamOS has neither in these versions.
  for lib in libopenxr_loader.so.1 libjsoncpp.so.26; do
    cp -L "$STEAMRT4_ARM64_SYSROOT/usr/lib/aarch64-linux-gnu/$lib" $BUILD/
  done
  # The release download: the three files in a GalaxyQuest folder, with the
  # executable bit kept (ANLEITUNG-STEAM-FRAME.md).
  rm -rf $BUILD/package
  mkdir -p $BUILD/package/GalaxyQuest
  cp $BUILD/galaxyquest $BUILD/libopenxr_loader.so.1 $BUILD/libjsoncpp.so.26 LICENSE THIRD_PARTY_NOTICES.md ANLEITUNG-STEAM-FRAME.md STEAM-FRAME.md \
    platform/linux/install.sh $BUILD/package/GalaxyQuest/
  # The disc converter for install.sh, as the converter zip holds it.
  python3 tools/package_converter.py $BUILD/converter.zip > /dev/null
  python3 -m zipfile -e $BUILD/converter.zip $BUILD/package/GalaxyQuest/
  mv $BUILD/package/GalaxyQuest/GalaxyQuest-converter $BUILD/package/GalaxyQuest/converter
  rm $BUILD/package/GalaxyQuest/converter/README.txt  # the Quest's steps; install.sh does them here
  find $BUILD/package -type f -exec chmod 644 {} +  # copies from a Windows drive come executable
  chmod 755 $BUILD/package/GalaxyQuest/galaxyquest $BUILD/package/GalaxyQuest/install.sh
  tar -C $BUILD/package --owner=0 --group=0 -czf $BUILD/GalaxyQuest-SteamFrame-arm64.tar.gz GalaxyQuest
fi
