# GalaxyQuest on the Steam Frame

*Deutsch: [ANLEITUNG-STEAM-FRAME.md](ANLEITUNG-STEAM-FRAME.md)*

Super Mario Galaxy in VR, running natively on the **Valve Steam Frame**
(SteamOS, arm64): the game code of the
[Petari project](https://github.com/SMGCommunity/Petari) runs directly on
the Frame's processor, and the picture goes to SteamVR through OpenXR. It is
a port of [GalaxyQuest](https://github.com/bigmak94/GalaxyQuest) (made for
Meta Quest there); everything about the game itself (diorama, giant screen,
VR settings) is in the [README](README.md).

> **You need your own Super Mario Galaxy disc.** Neither this repository nor
> the program contains any game data. Everyone converts their own disc once.
> Do not share the converted game files.

## What you need

- A **Steam Frame** with SteamVR set up, and about 9 GB free.
- Your **Super Mario Galaxy** as a disc image (ISO, RVZ, WBFS, GCZ, WIA),
  for example dumped from your disc with
  [CleanRip](https://wiibrew.org/wiki/CleanRip). Tested on the Frame: a
  Russian fan translation of the European disc (RMGR01; the game reports it
  as RMGP01). The European (RMGP01) and American (RMGE01) discs run in the
  Quest version.
- `GalaxyQuest-SteamFrame-arm64.tar.gz` from this repository's **Releases**.

You do not need a PC: `install.sh` from the archive extracts the disc on the
Frame (with Dolphin's `dolphin-tool`; if Dolphin is missing, the script
installs it from Flathub), converts the game files (a few minutes, 3.3 GB)
and adds the game to Steam.

## 1. Install

**Option A – on the Frame itself:**

1. Switch the Frame to desktop mode.
2. Put the archive and your disc image into your home folder (download them
   in the browser or copy them from a USB stick).
3. Extract the archive there (right-click → *Extract → Extract archive
   here*): this makes the folder `GalaxyQuest`. Do not extract it on the USB
   stick: the program would not be allowed to run from there.
4. Open Konsole and run, with the path to your disc image:

   ```
   ~/GalaxyQuest/install.sh ~/Downloads/SuperMarioGalaxy.iso
   ```

**Option B – from a PC over the network (SSH):**

Once, on the Frame in desktop mode, open Konsole:

```
passwd                              # set a password if there is none yet
sudo systemctl enable --now sshd
```

Then on the PC (Windows PowerShell or a Linux terminal), in the folder with
the archive and the disc image (here `smg.iso`; `frame.local` usually works,
otherwise use the IP address `ip a` shows on the Frame):

```
scp GalaxyQuest-SteamFrame-arm64.tar.gz smg.iso steamos@frame.local:
ssh steamos@frame.local "tar -xzf GalaxyQuest-SteamFrame-arm64.tar.gz && ~/GalaxyQuest/install.sh ~/smg.iso && rm ~/smg.iso"
```

Add `--no-movies` at the end to leave out the prologue and ending movies
(2.3 GB less). If you already extracted the disc (a folder with `sys` and
`files`), you can give that folder instead of the image.

## 2. Set it up in Steam

The script adds the game to Steam if Steam is running (otherwise: Steam →
*Games* → *Add a Non-Steam Game to My Library…* → *Browse* →
`/home/steamos/GalaxyQuest/galaxyquest`). Then, in the entry's
*Properties*:

- name: `GalaxyQuest`,
- **tick "Include in VR Library".**

Switch back to VR mode and start GalaxyQuest from the library.

## 3. Without install.sh (by hand)

On the Frame the program goes to `~/GalaxyQuest/`, the *contents* of the
converted folder to `~/.local/share/GalaxyQuest/game/` (with `sys` and
`files` directly inside). The conversion also works on a PC with Python
3.8+: extract the disc with Dolphin (right-click the game → *Properties* →
*Filesystem* → right-click the disc → *Extract Entire Disc…*), then, in the
archive's `converter` folder:

```
python tools/cook/cook.py <extracted disc> cooked --with-movies
```

If the game finds no data in the home folder, it shows a list of folders
with game data on start (also on SD cards and USB sticks); pick one there
and the game remembers it.

## 4. Refresh rate

The game runs at 60 frames a second and shows each one for exactly two
refreshes when the headset runs at **120 Hz**; on the second it turns the
picture to where your head points now. That gives the steadiest picture and
the GPU the most time per eye. The game sets 120 Hz itself when it starts:
it writes the rate into SteamVR's per-application settings (SteamVR →
*Video*), where it can also be changed. Other rates: pause menu → VR
settings → *Refresh rate* (72, 90, 120, 144 Hz).

## Controls (Frame controllers)

| Frame controller | Wii | In the game |
|---|---|---|
| Left stick | Nunchuk stick | Move |
| A | A | Jump, talk, confirm. Hold: skip a cutscene or dialogue |
| Y (or B) | Shake | Spin |
| X | Hold Z + A | Long jump while running, backflip standing still |
| Tilt the right controller | Tilt the Wii Remote | Steer the star ball and the manta ray |
| Right trigger | B | Shoot star bits, cancel |
| Point the right controller | Pointer | Collect star bits, grab pull stars, menus |
| Left trigger | Z | Crouch; ground pound in the air; held with A same as X |
| Left grip | C | Camera behind Mario |
| View (⧉, small button on the left) | + | Pause menu with the VR settings |
| Right stick or left D-pad, left/right | D-pad | Turn the view around Mario |
| Right stick or left D-pad up, right stick click | D-pad up | First-person view |

The Menu button (≡) on the right does nothing. Spinning also works by
swinging a controller briefly or flicking your wrist, but not as reliably
as with Y.

Recentre the view with SteamVR's own "Recenter view" in the system menu;
the game then puts the screen and the diorama in front of you.

## Language

Pause menu → VR settings → *Game* tab → *Language*, or the line
`language = german` in `~/.local/share/GalaxyQuest/petari_vr.ini`
(`english`, `french`, `spanish`, `italian`). Takes effect on the next start.

On fan translations the translation usually sits in the disc's English
folder: on RMGR01, "english" is Russian. Such discs sometimes carry damaged
files of other languages; the converter then replaces the affected archives
with another language's and reports it as
`note: … damaged on this disc, … used instead` (that is why the wrist strap
notice at start is in Dutch on RMGR01).

## Troubleshooting

- **Log:** `~/.local/share/GalaxyQuest/petari_log.txt` (the one from the
  start before: `petari_log.txt.prev`). Settings:
  `~/.local/share/GalaxyQuest/petari_vr.ini`, saves:
  `~/.local/share/GalaxyQuest/nand`.
- **Does not start from Steam:** run `~/GalaxyQuest/galaxyquest` in
  Konsole; a message like `error while loading shared libraries` means one
  of the three files from the archive is missing.
- **A list of game data folders instead of the game:** the converted data
  is not in `~/.local/share/GalaxyQuest/game` (`sys` and `files` must be
  directly inside). *Not converted* means: still to be converted with
  `cook.py` (or `install.sh`).
- **Stutters:** check that SteamVR uses 120 Hz for GalaxyQuest (see above);
  lines with `missed … refreshes` in the log show how often a frame came
  late. Other apps busy in the background (a chat client streaming video,
  for example) take CPU time from the game.
- **The picture smears when you turn your head:** `timewarp = 1` (the
  default) must be set in `petari_vr.ini`: the game then turns each of the
  120 pictures a second to your current head pose, which SteamVR itself does
  not do.

## Building it yourself

Build on Linux or WSL2 with **Ubuntu 24.04** (CMake 3.24+, clang 16+),
against Valve's Steam Runtime 4 SDK for arm64:

```
sudo apt install clang lld cmake ninja-build python3 curl
mkdir -p ~/steamrt4-arm64-sdk/sysroot && cd ~/steamrt4-arm64-sdk
curl -O https://repo.steampowered.com/steamrt4/images/latest-public-beta/com.valvesoftware.SteamRuntime.Sdk-arm64-steamrt4-sysroot.tar.gz
tar -xzf com.valvesoftware.SteamRuntime.Sdk-arm64-steamrt4-sysroot.tar.gz -C sysroot --exclude='./dev/*'
cd ~/GalaxyQuest        # this repository, not on an exFAT stick
ARCH=arm64 STEAMRT4_ARM64_SYSROOT=~/steamrt4-arm64-sdk/sysroot ./build_linux.sh
```

The result in `build-linux-arm64/`: `galaxyquest`, `libopenxr_loader.so.1`,
`libjsoncpp.so.26`, and packed from them
`GalaxyQuest-SteamFrame-arm64.tar.gz` (the release archive, with
`install.sh` from `platform/linux/` and the converter). A development build
to the Frame: `tools/push_frame.sh steamos@frame.local [cooked folder]`.

What differs from the Quest version is in
[docs/TECHNICAL.md](docs/TECHNICAL.md) under "Steam Frame (Linux)".
