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
- A **PC** with Linux, or Windows with WSL2, to build the program once.
  There are no ready-made builds.

`install.sh` from the built archive then does the rest on the Frame: it
extracts the disc (with Dolphin's `dolphin-tool`; if Dolphin is missing, the
script installs it from Flathub), converts the game files (a few minutes,
3.3 GB) and adds the game to Steam.

## 1. Build it (PC)

1. **Windows only:** open PowerShell and install Ubuntu in WSL2, then open
   *Ubuntu 24.04* from the Start menu and do the rest there:

   ```
   wsl --install -d Ubuntu-24.04
   ```

2. Install the tools (CMake 3.24+, clang 16+, lld, Ninja; tested with
   clang 20, `sudo apt install clang-20` if the default one fails):

   ```
   sudo apt update
   sudo apt install git clang lld cmake ninja-build python3 curl
   ```

3. Download Valve's Steam Runtime 4 SDK sysroot for arm64 (about 1 GB):

   ```
   mkdir -p ~/steamrt4-arm64-sdk/sysroot && cd ~/steamrt4-arm64-sdk
   curl -O https://repo.steampowered.com/steamrt4/images/latest-public-beta/com.valvesoftware.SteamRuntime.Sdk-arm64-steamrt4-sysroot.tar.gz
   tar -xzf com.valvesoftware.SteamRuntime.Sdk-arm64-steamrt4-sysroot.tar.gz -C sysroot --exclude='./dev/*'
   ```

4. Get the source and build it. Keep it in the Linux home folder, not on a
   Windows drive or a USB stick (they lose the executable bit):

   ```
   git clone https://github.com/PodeCaradox/GalaxyQuest-SteamFrame.git ~/GalaxyQuest
   cd ~/GalaxyQuest
   ARCH=arm64 STEAMRT4_ARM64_SYSROOT=~/steamrt4-arm64-sdk/sysroot ./build_linux.sh
   ```

   The result is `~/GalaxyQuest/build-linux-arm64/GalaxyQuest-SteamFrame-arm64.tar.gz`
   (about 10 minutes the first time; after `git pull` only what changed is
   rebuilt). On Windows, `explorer.exe build-linux-arm64` in the Ubuntu
   window opens that folder in Explorer.

## 2. Bring it to the Frame and install

**Option A – USB stick, no network setup:**

1. Copy `GalaxyQuest-SteamFrame-arm64.tar.gz` and your disc image (here
   `smg.iso`) to a USB stick.
2. On the Frame, switch to desktop mode and plug in the stick.
3. In the file manager (Dolphin), copy both files from the stick into your
   home folder, then right-click the archive → *Extract → Extract archive
   here*. This makes the folder `GalaxyQuest`. (Not on the stick itself:
   the program would not be allowed to run from there.)
4. Open Konsole and run, with the path to your disc image:

   ```
   ~/GalaxyQuest/install.sh ~/smg.iso
   ```

**Option B – over the network (SSH):**

1. Once, on the Frame: turn on *Settings → System → Developer Mode* and set
   a password for the user `steamos` in the developer settings. That turns
   SSH on. (Without developer mode, Konsole in desktop mode does it too:
   `passwd`, then `sudo systemctl enable --now sshd`.)
2. On the PC (Windows PowerShell, a Linux terminal or the Ubuntu window),
   in the folder with the archive and the disc image:

   ```
   scp GalaxyQuest-SteamFrame-arm64.tar.gz smg.iso steamos@frame.local:
   ssh steamos@frame.local "tar -xzf GalaxyQuest-SteamFrame-arm64.tar.gz && ~/GalaxyQuest/install.sh ~/smg.iso && rm ~/smg.iso"
   ```

   Both ask for the password from step 1. If `frame.local` is not found
   (often the case inside WSL), use the Frame's IP address (`ip a` in
   Konsole on the Frame). From the Ubuntu window a disc image in the
   Windows downloads is at `/mnt/c/Users/<you>/Downloads/smg.iso`.

Add `--no-movies` after the disc image to leave out the prologue and ending
movies (2.3 GB less). If you already extracted the disc (a folder with
`sys` and `files`), you can give that folder instead of the image.

## 3. Set it up in Steam

The script adds the game to Steam if Steam is running (otherwise: Steam →
*Games* → *Add a Non-Steam Game to My Library…* → *Browse* →
`/home/steamos/GalaxyQuest/galaxyquest`). Then, in the entry's
*Properties*:

- name: `GalaxyQuest`,
- **tick "Include in VR Library".**

Switch back to VR mode and start GalaxyQuest from the library.

## 4. Without install.sh (by hand)

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

## 5. Refresh rate

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

## Development

A development build straight to the Frame: `tools/push_frame.sh steamos@frame.local [cooked folder]`.

What differs from the Quest version is in
[docs/TECHNICAL.md](docs/TECHNICAL.md) under "Steam Frame (Linux)".
