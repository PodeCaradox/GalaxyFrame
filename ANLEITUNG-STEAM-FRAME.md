# GalaxyQuest auf der Steam Frame

*English: [STEAM-FRAME.md](STEAM-FRAME.md)*

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

- Eine **Steam Frame** mit eingerichtetem SteamVR, etwa 9 GB frei.
- Dein **Super Mario Galaxy** als Disc-Abbild (ISO, RVZ, WBFS, GCZ, WIA),
  z. B. mit [CleanRip](https://wiibrew.org/wiki/CleanRip) von deiner Disc
  gezogen. Auf der Frame getestet: eine russische Fan-Übersetzung der
  europäischen Disc (RMGR01; das Spiel meldet sie als RMGP01). Die
  europäische (RMGP01) und die amerikanische (RMGE01) laufen in der
  Quest-Fassung.
- Aus den **Releases** dieses Repositorys `GalaxyQuest-SteamFrame-arm64.tar.gz`.

Einen PC brauchst du nicht: `install.sh` aus dem Archiv entpackt die Disc auf
der Frame (mit Dolphins `dolphin-tool`; fehlt Dolphin, installiert das Skript
es aus Flathub), wandelt die Spieldateien um (einige Minuten, 3,3 GB) und
trägt das Spiel in Steam ein.

## 1. Installieren

**Variante A – direkt auf der Frame:**

1. Frame in den Desktop-Modus schalten.
2. Archiv und Disc-Abbild in den Persönlichen Ordner holen (Download im
   Browser oder vom USB-Stick kopieren).
3. Das Archiv dort entpacken (Rechtsklick → *Entpacken → Hierher
   entpacken*): es entsteht der Ordner `GalaxyQuest`. Nicht auf dem Stick
   entpacken: dort fehlt dem Programm das Recht, ausgeführt zu werden.
4. Konsole öffnen und, mit dem Pfad zu deinem Disc-Abbild:

   ```
   ~/GalaxyQuest/install.sh ~/Downloads/SuperMarioGalaxy.iso
   ```

**Variante B – vom PC über das Netzwerk (SSH):**

Einmalig auf der Frame im Desktop-Modus eine Konsole öffnen:

```
passwd                              # Passwort setzen, falls noch keins
sudo systemctl enable --now sshd
```

Dann auf dem PC (Windows-PowerShell oder Linux-Terminal), im Ordner mit dem
Archiv und dem Disc-Abbild (hier `smg.iso`; `frame.local` geht meistens, sonst
die IP-Adresse aus `ip a` auf der Frame):

```
scp GalaxyQuest-SteamFrame-arm64.tar.gz smg.iso steamos@frame.local:
ssh steamos@frame.local "tar -xzf GalaxyQuest-SteamFrame-arm64.tar.gz && ~/GalaxyQuest/install.sh ~/smg.iso && rm ~/smg.iso"
```

Ohne Prolog- und Abspann-Film (2,3 GB weniger) hinten `--no-movies`
anhängen. Hast du die Disc schon entpackt (Ordner mit `sys` und `files`),
geht statt des Abbilds auch dieser Ordner.

## 2. In Steam einrichten

Das Skript trägt das Spiel in Steam ein, wenn Steam läuft (sonst: Steam →
*Spiele* → *Ein Nicht-Steam-Spiel zur Bibliothek hinzufügen* → *Durchsuchen*
→ `/home/steamos/GalaxyQuest/galaxyquest`). Danach in den *Eigenschaften* des
Eintrags:

- Name: `GalaxyQuest`,
- **„In VR-Bibliothek aufnehmen“ anhaken.**

Zurück in den VR-Modus wechseln und GalaxyQuest aus der Bibliothek starten.

## 3. Ohne install.sh (von Hand)

Auf der Frame gehört das Programm nach `~/GalaxyQuest/`, der *Inhalt* des
umgewandelten Ordners nach `~/.local/share/GalaxyQuest/game/` (dort direkt
`sys` und `files`). Umwandeln geht auch auf einem PC mit Python 3.8+: Disc
mit Dolphin entpacken (Rechtsklick auf das Spiel → *Eigenschaften* →
*Dateisystem* → Rechtsklick auf die Disc → *Gesamte Disc extrahieren…*), dann
im Ordner `converter` aus dem Archiv:

```
python tools/cook/cook.py <entpackte Disc> cooked --with-movies
```

Findet das Spiel keine Daten im Heimordner, zeigt es beim Start eine Liste
der Ordner mit Spieldaten (auch auf SD-Karte und USB-Stick); dort einen
auswählen, das Spiel merkt ihn sich.

## 4. Bildwiederholrate

Das Spiel läuft mit 60 Bildern pro Sekunde und zeigt jedes genau zwei
Bildwechsel lang, wenn das Headset mit **120 Hz** läuft; beim zweiten dreht
es das Bild auf die aktuelle Kopfhaltung nach. So ist das Bild am ruhigsten,
und die Grafikkarte hat pro Auge die meiste Zeit. Das Spiel stellt 120 Hz
beim Start selbst ein: es trägt die Rate in SteamVRs anwendungsspezifische
Einstellungen ein (SteamVR → *Video*), dort lässt sie sich auch ändern.
Andere Raten: Pausenmenü → VR-Einstellungen → *Refresh rate* (72, 90, 120,
144 Hz).

## Steuerung (Frame-Controller)

| Frame-Controller | Wii | Im Spiel |
|---|---|---|
| Linker Stick | Nunchuk-Stick | Laufen |
| A | A | Springen, reden, bestätigen. Halten: Zwischensequenz oder Dialog überspringen |
| Y (oder B) | Schütteln | Drehattacke |
| X | Z halten + A | Beim Laufen Weitsprung, im Stand Rückwärtssalto |
| Rechten Controller neigen | Wii-Fernbedienung neigen | Sternenkugel und Rochen-Surfen lenken |
| Rechter Trigger | B | Sternenteile schießen, abbrechen |
| Rechten Controller zielen | Pointer | Sternenteile sammeln, Zugsterne greifen, Menüs |
| Linker Trigger | Z | Ducken; in der Luft Stampfattacke; gehalten mit A wie X |
| Linke Griff-Taste | C | Kamera hinter Mario |
| Ansicht (⧉, kleine Taste links) | + | Pausenmenü mit den VR-Einstellungen |
| Rechter Stick oder linkes Steuerkreuz, links/rechts | Steuerkreuz | Ansicht um Mario drehen |
| Rechter Stick oder linkes Steuerkreuz hoch, rechter Stick drücken | Steuerkreuz oben | Ego-Perspektive |

Die Menü-Taste (≡) rechts ist frei. Die Drehattacke geht auch, wenn man
einen Controller kurz schwingt oder aus dem Handgelenk dreht, aber nicht so
zuverlässig wie mit Y.

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
- **Ruckelt:** prüfen, ob SteamVR für GalaxyQuest 120 Hz nutzt (siehe
  oben); im Protokoll zeigen Zeilen mit `missed … refreshes`, wie oft ein
  Bild zu spät kam. Andere Programme im Hintergrund (etwa ein Chat-Programm,
  das Video überträgt) nehmen dem Spiel Rechenzeit.
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
(das Release-Archiv, mit `install.sh` aus `platform/linux/` und dem
Konverter). Ein Entwicklungsstand auf die Frame:
`tools/push_frame.sh steamos@frame.local [cooked-Ordner]`.

Was sich gegenüber der Quest-Fassung ändert, steht in
[docs/TECHNICAL.md](docs/TECHNICAL.md) unter „Steam Frame (Linux)“.
