# GalaxyQuest auf der Steam Frame

Super Mario Galaxy in VR, nativ auf der **Valve Steam Frame** (SteamOS, arm64):
der Spielcode des [Petari-Projekts](https://github.com/SMGCommunity/Petari)
läuft direkt auf dem Prozessor der Frame, das Bild geht über OpenXR an
SteamVR. Es ist eine Portierung von
[GalaxyQuest](https://github.com/bigmak94/GalaxyQuest) (dort für Meta Quest);
alles über das Spiel selbst (Diorama, Riesenleinwand, VR-Einstellungen) steht
in der [README](README.md).

> **Du brauchst deine eigene Super-Mario-Galaxy-Disc.** Weder dieses
> Repository noch das Programm enthält Spieldaten. Jeder wandelt seine eigene
> Disc einmal um. Gib die umgewandelten Spieldaten nicht weiter.

## Was du brauchst

- Eine **Steam Frame** mit eingerichtetem SteamVR.
- Dein **Super Mario Galaxy** als Disc-Abbild (ISO, RVZ, WBFS), z. B. mit
  [CleanRip](https://wiibrew.org/wiki/CleanRip) von deiner Disc gezogen.
  Auf der Frame getestet: eine russische Fan-Übersetzung der europäischen
  Disc (RMGR01; das Spiel meldet sie als RMGP01). Die europäische (RMGP01)
  und die amerikanische (RMGE01) laufen in der Quest-Fassung.
- Einen **PC** mit
  - [Python 3.8 oder neuer](https://www.python.org/downloads/) (Windows: beim
    Installieren „Add python.exe to PATH“ anhaken),
  - [Dolphin](https://dolphin-emu.org/) zum Entpacken der Disc,
  - etwa 10 GB freiem Platz.
- Aus den **Releases** dieses Repositorys:
  - `GalaxyQuest-SteamFrame-arm64.tar.gz` (das Programm für die Frame),
  - `GalaxyQuest-converter.zip` (der Konverter für deine Disc).

## 1. Disc entpacken (PC)

In Dolphin: Rechtsklick auf das Spiel → *Eigenschaften* → Reiter *Dateisystem*
→ Rechtsklick auf die Disc ganz oben → *Gesamte Disc extrahieren…* → einen
neuen, leeren Ordner `extracted` wählen. Danach liegt darin `DATA` mit `sys`
und `files`.

(Alternativ auf der Kommandozeile: `DolphinTool extract -i "Super Mario Galaxy.iso" -o extracted`.)

## 2. Spieldaten umwandeln (PC)

`GalaxyQuest-converter.zip` entpacken (die `README.txt` darin beschreibt die
Quest mit adb: hier nicht nötig), den Ordner `extracted` hineinlegen und dort
ein Terminal öffnen (Windows: in die Adresszeile des Explorers klicken, `cmd`
tippen, Enter). Dann:

```
py tools/cook/cook.py extracted cooked --with-movies
```

(macOS/Linux: `python3` statt `py`.) Nach ein paar Minuten liegt der Ordner
`cooked` (3,3 GB) da. Zeilen mit `note` am Ende sind normal.

Ohne `--with-movies` fehlen Prolog und Abspann (2,3 GB weniger).

## 3. Auf die Frame kopieren

Auf der Frame gehört

- das Programm nach `~/GalaxyQuest/` (also `/home/steamos/GalaxyQuest/`),
- der *Inhalt* von `cooked` nach `~/.local/share/GalaxyQuest/game/`.

**Variante A – USB-Stick oder SD-Karte, ohne Netzwerk:**

1. `GalaxyQuest-SteamFrame-arm64.tar.gz` und den Ordner `cooked` auf den Stick
   kopieren.
2. Frame in den Desktop-Modus schalten, den Stick einstecken.
3. Im Dateimanager (Dolphin) das Archiv in den Persönlichen Ordner kopieren
   und dort entpacken (Rechtsklick → *Entpacken → Hierher entpacken*): es
   entsteht `GalaxyQuest` mit `galaxyquest`, `libopenxr_loader.so.1` und
   `libjsoncpp.so.26`. (Nicht auf dem Stick entpacken: dort fehlt dem
   Programm das Recht, ausgeführt zu werden.)
4. Den *Inhalt* von `cooked` nach `~/.local/share/GalaxyQuest/game` kopieren
   (versteckte Ordner zeigt Strg+H). Oder `cooked` einfach auf der SD-Karte
   lassen: findet das Spiel seine Daten nicht im Heimordner, zeigt es beim
   Start eine Liste der Ordner mit Spieldaten (auch auf SD-Karte und
   USB-Stick); dort einen auswählen, das Spiel merkt ihn sich.

**Variante B – über das Netzwerk (SSH):**

Einmalig auf der Frame im Desktop-Modus eine Konsole öffnen:

```
passwd                              # Passwort setzen, falls noch keins
sudo systemctl enable --now sshd
```

Dann auf dem PC (Windows-PowerShell oder Linux-Terminal; `frame.local` geht
meistens, sonst die IP-Adresse aus `ip a` auf der Frame):

```
tar -xzf GalaxyQuest-SteamFrame-arm64.tar.gz
ssh steamos@frame.local "mkdir -p ~/GalaxyQuest ~/.local/share/GalaxyQuest/game"
scp GalaxyQuest/* steamos@frame.local:GalaxyQuest/
scp -r cooked/* steamos@frame.local:.local/share/GalaxyQuest/game/
ssh steamos@frame.local "chmod +x ~/GalaxyQuest/galaxyquest"
```

## 4. Zu Steam hinzufügen

Im Desktop-Modus: Steam öffnen → *Spiele* → *Ein Nicht-Steam-Spiel zur
Bibliothek hinzufügen* → *Durchsuchen* → `/home/steamos/GalaxyQuest/galaxyquest`.
Danach in den *Eigenschaften* des neuen Eintrags:

- Name: `GalaxyQuest`,
- **„In VR-Bibliothek aufnehmen“ anhaken.**

Zurück in den VR-Modus wechseln und GalaxyQuest aus der Bibliothek starten.

## 5. 120 Hz einstellen (empfohlen)

Das Spiel läuft mit 60 Bildern pro Sekunde und zeigt jedes genau zwei
Bildwechsel lang, wenn das Headset mit **120 Hz** läuft – dann ist das Bild
am ruhigsten und die Grafikkarte hat pro Auge die meiste Zeit. Die
Bildwiederholrate legt auf der Frame SteamVR fest (das Spiel kann sie dort
nicht selbst wählen): in den SteamVR-Einstellungen unter *Video* bei den
anwendungsspezifischen Einstellungen für GalaxyQuest 120 Hz wählen.

## Steuerung (Frame-Controller)

| Frame-Controller | Wii | Im Spiel |
|---|---|---|
| Linker Stick | Nunchuk-Stick | Laufen |
| A | A | Springen, reden, bestätigen. Halten: Zwischensequenz oder Dialog überspringen |
| B oder Y, oder einen Controller kurz schwingen oder aus dem Handgelenk drehen (rechts wie die Wii-Fernbedienung, links wie der Nunchuk) | Schütteln | Drehattacke |
| Rechten Controller neigen | Wii-Fernbedienung neigen | Sternenkugel und Rochen-Surfen lenken |
| Rechter Trigger | B | Sternenteile schießen, abbrechen |
| Rechten Controller zielen | Pointer | Sternenteile sammeln, Zugsterne greifen, Menüs |
| Linker Trigger | Z | Ducken, Stampfattacke, Weit- und Rückwärtssprung |
| Linke Griff-Taste | C | Kamera hinter Mario |
| Menü (≡, rechts) | + | Pausenmenü mit den VR-Einstellungen |
| X oder Ansicht (⧉, links) | − | Pausenmenü |
| Rechter Stick oder linkes Steuerkreuz, links/rechts | Steuerkreuz | Ansicht um Mario drehen |
| Rechter Stick oder linkes Steuerkreuz hoch, rechter Stick drücken | Steuerkreuz oben | Ego-Perspektive |

Ansicht neu ausrichten: mit SteamVRs eigenem „Ansicht zentrieren“ im
System-Menü; das Spiel stellt Leinwand und Diorama dann vor dich.

## Sprache

Im Pausenmenü → VR-Einstellungen → Reiter *Game* → *Language*, oder in
`~/.local/share/GalaxyQuest/petari_vr.ini` die Zeile `language = german`
(`english`, `french`, `spanish`, `italian`). Gilt ab dem nächsten Start.

Bei Fan-Übersetzungen steckt die Übersetzung meist im englischen Ordner der
Disc: bei RMGR01 ist „english“ Russisch. Solche Discs haben manchmal
beschädigte Dateien anderer Sprachen; der Konverter ersetzt dann die
betroffenen Archive durch die einer anderen Sprache und meldet das als
`note: … damaged on this disc, … used instead` (bei RMGR01 ist deshalb der
Hinweis zum Handgelenksriemen beim Start auf Niederländisch).

## Wenn etwas nicht geht

- **Protokoll:** `~/.local/share/GalaxyQuest/petari_log.txt` (das vom
  vorigen Start: `petari_log.txt.prev`). Einstellungen:
  `~/.local/share/GalaxyQuest/petari_vr.ini`, Spielstände:
  `~/.local/share/GalaxyQuest/nand`.
- **Startet nicht aus Steam:** in der Konsole
  `~/GalaxyQuest/galaxyquest` aufrufen; eine Meldung wie
  `error while loading shared libraries` heißt, dass eine der drei Dateien
  aus dem Archiv fehlt.
- **Liste mit Spieldaten-Ordnern statt Spiel:** die umgewandelten Daten
  liegen nicht in `~/.local/share/GalaxyQuest/game` (dort muss direkt `sys`
  und `files` liegen). *Not converted* heißt: noch mit `cook.py` umwandeln.
- **Ruckelt:** 120 Hz einstellen (siehe oben).
- **Bild schliert bei Kopfbewegungen:** in `petari_vr.ini` muss
  `timewarp = 1` gelten (Standard): dann dreht das Spiel jedes der 120
  Bilder pro Sekunde auf die aktuelle Kopfhaltung nach, was SteamVR selbst
  nicht tut.

## Selbst bauen

Gebaut wird unter Linux oder WSL2 mit **Ubuntu 24.04** (CMake 3.24+,
clang 16+), gegen Valves Steam-Runtime-4-SDK für arm64:

```
sudo apt install clang lld cmake ninja-build python3 curl
mkdir -p ~/steamrt4-arm64-sdk/sysroot && cd ~/steamrt4-arm64-sdk
curl -O https://repo.steampowered.com/steamrt4/images/latest-public-beta/com.valvesoftware.SteamRuntime.Sdk-arm64-steamrt4-sysroot.tar.gz
tar -xzf com.valvesoftware.SteamRuntime.Sdk-arm64-steamrt4-sysroot.tar.gz -C sysroot --exclude='./dev/*'
cd ~/GalaxyQuest        # dieses Repository, nicht auf einem exFAT-Stick
ARCH=arm64 STEAMRT4_ARM64_SYSROOT=~/steamrt4-arm64-sdk/sysroot ./build_linux.sh
```

Ergebnis in `build-linux-arm64/`: `galaxyquest`, `libopenxr_loader.so.1`,
`libjsoncpp.so.26` und daraus gepackt `GalaxyQuest-SteamFrame-arm64.tar.gz`
(das Release-Archiv). Den Konverter packt `python3 tools/package_converter.py`
nach `out/GalaxyQuest-converter.zip`. Auf die Frame kopieren:
`tools/push_frame.sh steamos@frame.local [cooked-Ordner]`.

Was sich gegenüber der Quest-Fassung ändert, steht in
[docs/TECHNICAL.md](docs/TECHNICAL.md) unter „Steam Frame (Linux)“.
