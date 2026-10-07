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

# Messages in German on a German system, else in English.
case "${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}" in de*) DE=1 ;; *) DE=0 ;; esac
t() { if [ $DE = 1 ]; then printf '%s' "$1"; else printf '%s' "$2"; fi; }
say() { printf '\n== %s\n' "$*"; }
fail() { printf '\n%s: %s\n' "$(t FEHLER ERROR)" "$*" >&2; exit 1; }

SOURCE=""
MOVIES=--with-movies
for arg in "$@"; do
  case "$arg" in
    --no-movies) MOVIES="" ;;
    -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
    *) [ -z "$SOURCE" ] || fail "$(t 'nur ein Disc-Abbild angeben' 'give only one disc image')"; SOURCE=$arg ;;
  esac
done
[ -n "$SOURCE" ] || fail "$(t 'Pfad zum Disc-Abbild fehlt. Beispiel' 'the path to the disc image is missing. Example'): ./install.sh ~/Downloads/SuperMarioGalaxy.iso"
[ -e "$SOURCE" ] || fail "$(t 'nicht gefunden' 'not found'): $SOURCE"
SOURCE=$(realpath "$SOURCE")
command -v python3 >/dev/null || fail "$(t 'python3 fehlt' 'python3 is missing')"
[ -f "$HERE/converter/tools/cook/cook.py" ] || fail "$(t 'converter/ fehlt neben install.sh: das ganze Release-Archiv entpacken' 'converter/ is missing next to install.sh: extract the whole release archive')"

# The converted game is 3.3 GB (1 GB without movies); the extracted disc up
# to 4.7 GB more while the conversion runs.
mkdir -p "$DATA"
free_gb=$(( $(df -Pk "$DATA" | awk 'NR==2 {print $4}') / 1024 / 1024 ))
[ "$free_gb" -ge 9 ] || fail "$(t "zu wenig Platz in $DATA: $free_gb GB frei, 9 GB nötig" "not enough space in $DATA: $free_gb GB free, 9 GB needed")"
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
    command -v flatpak >/dev/null || fail "$(t 'weder dolphin-tool noch flatpak gefunden' 'found neither dolphin-tool nor flatpak')"
    if ! flatpak info "$DOLPHIN" >/dev/null 2>&1; then
      say "$(t 'Dolphin wird aus Flathub installiert (zum Entpacken der Disc)' 'Installing Dolphin from Flathub (to extract the disc)')"
      # Into the user's installation: the system one asks for a password over SSH.
      flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      flatpak install --user -y --noninteractive flathub "$DOLPHIN"
    fi
    # The Flatpak sandbox sees only what it is given: the image's folder and the work folder.
    DOLPHIN_TOOL=(flatpak run --filesystem="$(dirname "$SOURCE")":ro --filesystem="$WORK" --command=dolphin-tool "$DOLPHIN")
  fi
  say "$(t 'Disc wird entpackt' 'Extracting the disc'): $SOURCE"
  "${DOLPHIN_TOOL[@]}" extract -i "$SOURCE" -o "$WORK/disc" --gameonly --quiet
  DISC=$WORK/disc
fi

say "$(t 'Spieldateien werden umgewandelt (einige Minuten)' 'Converting the game files (a few minutes)')"
python3 "$HERE/converter/tools/cook/cook.py" "$DISC" "$WORK/cooked" $MOVIES
[ -f "$WORK/cooked/sys/main.dol" ] || [ -d "$WORK/cooked/files" ] || fail "$(t 'die Umwandlung hat keine Spieldateien erzeugt' 'the conversion made no game files')"
rm -rf "$DATA/game"
mv "$WORK/cooked" "$DATA/game"

chmod 755 "$HERE/galaxyquest"
if command -v steamos-add-to-steam >/dev/null && pgrep -x steam >/dev/null; then
  say "$(t 'GalaxyQuest wird zu Steam hinzugefügt' 'Adding GalaxyQuest to Steam')"
  steamos-add-to-steam "$HERE/galaxyquest" || true
fi

say "$(t Fertig Done)"
if [ $DE = 1 ]; then
  cat <<EOF
Programm:    $HERE/galaxyquest
Spieldaten:  $DATA/game

In Steam (Desktop-Modus): den neuen Eintrag "galaxyquest" in GalaxyQuest
umbenennen und in den Eigenschaften "In VR-Bibliothek aufnehmen" anhaken.
Fehlt der Eintrag: Spiele -> "Ein Nicht-Steam-Spiel zur Bibliothek
hinzufügen" -> $HERE/galaxyquest
Dann im VR-Modus aus der Bibliothek starten.
EOF
else
  cat <<EOF
Program:     $HERE/galaxyquest
Game files:  $DATA/game

In Steam (desktop mode): rename the new entry "galaxyquest" to GalaxyQuest
and tick "Include in VR Library" in its Properties. If the entry is missing:
Games -> "Add a Non-Steam Game to My Library..." -> $HERE/galaxyquest
Then start it from the library in VR mode.
EOF
fi
