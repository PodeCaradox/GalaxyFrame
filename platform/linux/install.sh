#!/bin/bash
# Installs GalaxyQuest on the Steam Frame from the player's own Super Mario
# Galaxy disc: extracts the disc image with Dolphin's dolphin-tool (the
# Flatpak from Flathub, installed if missing), converts the game files with
# converter/tools/cook/cook.py into ~/.local/share/GalaxyQuest/game, and adds
# the program to Steam.  Run it on the Frame from the unpacked release folder,
# in the desktop mode's Konsole or over SSH:
#   ./install.sh <disc image: .iso .rvz .wbfs .gcz .wia .ciso, or an extracted disc folder> [--no-movies]
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
DATA=${GALAXYQUEST_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/GalaxyQuest}
DOLPHIN=org.DolphinEmu.dolphin-emu

say() { printf '\n== %s\n' "$*"; }
fail() { printf '\nFEHLER: %s\n' "$*" >&2; exit 1; }

SOURCE=""
MOVIES=--with-movies
for arg in "$@"; do
  case "$arg" in
    --no-movies) MOVIES="" ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) [ -z "$SOURCE" ] || fail "nur ein Disc-Abbild angeben"; SOURCE=$arg ;;
  esac
done
[ -n "$SOURCE" ] || fail "Pfad zum Disc-Abbild fehlt. Beispiel: ./install.sh ~/Downloads/SuperMarioGalaxy.iso"
[ -e "$SOURCE" ] || fail "nicht gefunden: $SOURCE"
SOURCE=$(realpath "$SOURCE")
command -v python3 >/dev/null || fail "python3 fehlt"
[ -f "$HERE/converter/tools/cook/cook.py" ] || fail "converter/ fehlt neben install.sh: das ganze Release-Archiv entpacken"

# The converted game is 3.3 GB (1 GB without movies); the extracted disc up
# to 4.7 GB more while the conversion runs.
mkdir -p "$DATA"
free_gb=$(( $(df -Pk "$DATA" | awk 'NR==2 {print $4}') / 1024 / 1024 ))
[ "$free_gb" -ge 9 ] || fail "zu wenig Platz in $DATA: $free_gb GB frei, 9 GB nötig"
WORK=$DATA/.install
rm -rf "$WORK"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

if [ -d "$SOURCE" ]; then
  DISC=$SOURCE
else
  DOLPHIN_TOOL=()
  if command -v dolphin-tool >/dev/null; then
    DOLPHIN_TOOL=(dolphin-tool)
  else
    command -v flatpak >/dev/null || fail "weder dolphin-tool noch flatpak gefunden"
    if ! flatpak info "$DOLPHIN" >/dev/null 2>&1; then
      say "Dolphin wird aus Flathub installiert (zum Entpacken der Disc)"
      # Into the user's installation: the system one asks for a password over SSH.
      flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      flatpak install --user -y --noninteractive flathub "$DOLPHIN"
    fi
    # The Flatpak sandbox sees only what it is given: the image's folder and the work folder.
    DOLPHIN_TOOL=(flatpak run --filesystem="$(dirname "$SOURCE")":ro --filesystem="$WORK" --command=dolphin-tool "$DOLPHIN")
  fi
  say "Disc wird entpackt: $SOURCE"
  "${DOLPHIN_TOOL[@]}" extract -i "$SOURCE" -o "$WORK/disc" --gameonly --quiet
  DISC=$WORK/disc
fi

say "Spieldateien werden umgewandelt (einige Minuten)"
python3 "$HERE/converter/tools/cook/cook.py" "$DISC" "$WORK/cooked" $MOVIES
[ -f "$WORK/cooked/sys/main.dol" ] || [ -d "$WORK/cooked/files" ] || fail "die Umwandlung hat keine Spieldateien erzeugt"
rm -rf "$DATA/game"
mv "$WORK/cooked" "$DATA/game"

chmod 755 "$HERE/galaxyquest"
if command -v steamos-add-to-steam >/dev/null && pgrep -x steam >/dev/null; then
  say "GalaxyQuest wird zu Steam hinzugefügt"
  steamos-add-to-steam "$HERE/galaxyquest" || true
fi

say "Fertig"
cat <<EOF
Programm:    $HERE/galaxyquest
Spieldaten:  $DATA/game

In Steam (Desktop-Modus): den neuen Eintrag "galaxyquest" in GalaxyQuest
umbenennen und in den Eigenschaften "In VR-Bibliothek aufnehmen" anhaken.
Fehlt der Eintrag: Spiele -> "Ein Nicht-Steam-Spiel zur Bibliothek
hinzufügen" -> $HERE/galaxyquest
Dann im VR-Modus aus der Bibliothek starten.
EOF
