#!/bin/bash
# Copies the Linux arm64 build to a Steam Frame over SSH, and the converted
# game files too when their folder is given:
#   tools/push_frame.sh <user@headset> [cooked folder]
# The app goes to ~/GalaxyQuest, the game files to
# ~/.local/share/GalaxyQuest/game (where the app looks first).
set -e
HOST=${1:?usage: tools/push_frame.sh <user@headset> [cooked folder]}
COOKED=${2:+$(cd "$2" && pwd)}  # before the cd below
cd "$(dirname "$0")/.."
BUILD=${BUILD:-build-linux-arm64}
ssh "$HOST" 'mkdir -p ~/GalaxyQuest ~/.local/share/GalaxyQuest/game'
rsync -a --info=progress2 "$BUILD/galaxyquest" "$BUILD/libopenxr_loader.so.1" "$BUILD/libjsoncpp.so.26" "$HOST:GalaxyQuest/"
if [ -n "$COOKED" ]; then
  rsync -a --info=progress2 "$COOKED/" "$HOST:.local/share/GalaxyQuest/game/"
fi
echo "done: run ~/GalaxyQuest/galaxyquest on the headset (add it to Steam as a non-Steam game)"
