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
- Einen **PC** mit Linux oder Windows mit WSL2, um das Programm einmal zu
  bauen. Einen fertigen Download gibt es nicht.

Den Rest macht dann `install.sh` aus dem gebauten Archiv auf der Frame: es
entpackt die Disc (mit Dolphins `dolphin-tool`; fehlt Dolphin, installiert
das Skript es aus Flathub), wandelt die Spieldateien um (einige Minuten,
3,3 GB) und trägt das Spiel in Steam ein.

## 1. Bauen (PC)

1. **Nur Windows:** PowerShell öffnen und Ubuntu in WSL2 installieren,
   dann *Ubuntu 24.04* im Startmenü öffnen und alles Weitere dort:

   ```
   wsl --install -d Ubuntu-24.04
   ```

2. Werkzeuge installieren (CMake 3.24+, clang 16+, lld, Ninja; getestet mit
   clang 20, `sudo apt install clang-20`, falls das Standard-clang
   scheitert):

   ```
   sudo apt update
   sudo apt install git clang lld cmake ninja-build python3 curl
   ```

3. Valves Steam-Runtime-4-SDK für arm64 herunterladen (etwa 1 GB):

   ```
   mkdir -p ~/steamrt4-arm64-sdk/sysroot && cd ~/steamrt4-arm64-sdk
   curl -O https://repo.steampowered.com/steamrt4/images/latest-public-beta/com.valvesoftware.SteamRuntime.Sdk-arm64-steamrt4-sysroot.tar.gz
   tar -xzf com.valvesoftware.SteamRuntime.Sdk-arm64-steamrt4-sysroot.tar.gz -C sysroot --exclude='./dev/*'
   ```

4. Quellcode holen und bauen. Im Linux-Heimordner lassen, nicht auf einem
   Windows-Laufwerk oder USB-Stick (dort fehlt das Recht zum Ausführen):

   ```
   git clone https://github.com/PodeCaradox/GalaxyQuest-SteamFrame.git ~/GalaxyQuest
   cd ~/GalaxyQuest
   ARCH=arm64 STEAMRT4_ARM64_SYSROOT=~/steamrt4-arm64-sdk/sysroot ./build_linux.sh
   ```

   Ergebnis: `~/GalaxyQuest/build-linux-arm64/GalaxyQuest-SteamFrame-arm64.tar.gz`
   (beim ersten Mal etwa 10 Minuten; nach `git pull` wird nur Geändertes
   neu gebaut). Unter Windows öffnet `explorer.exe build-linux-arm64` im
   Ubuntu-Fenster den Ordner im Explorer.

## 2. Auf die Frame bringen und installieren

**Variante A – USB-Stick, ohne Netzwerk:**

1. `GalaxyQuest-SteamFrame-arm64.tar.gz` und dein Disc-Abbild (hier
   `smg.iso`) auf einen USB-Stick kopieren.
2. Frame in den Desktop-Modus schalten, den Stick einstecken.
3. Im Dateimanager (Dolphin) beide Dateien vom Stick in den Persönlichen
   Ordner kopieren, dann Rechtsklick auf das Archiv → *Entpacken → Hierher
   entpacken*: es entsteht der Ordner `GalaxyQuest`. (Nicht auf dem Stick
   entpacken: dort fehlt dem Programm das Recht, ausgeführt zu werden.)
4. Konsole öffnen und, mit dem Pfad zu deinem Disc-Abbild:

   ```
   ~/GalaxyQuest/install.sh ~/smg.iso
   ```

**Variante B – über das Netzwerk (SSH):**

1. Einmalig auf der Frame: *Einstellungen → System → Entwicklermodus*
   einschalten und in den Entwickler-Einstellungen ein Passwort für den
   Benutzer `steamos` setzen. Damit ist SSH an. (Ohne Entwicklermodus geht
   es auch in der Konsole des Desktop-Modus: `passwd`, dann
   `sudo systemctl enable --now sshd`.)
2. Auf dem PC (Windows-PowerShell, Linux-Terminal oder das Ubuntu-Fenster),
   im Ordner mit Archiv und Disc-Abbild:

   ```
   scp GalaxyQuest-SteamFrame-arm64.tar.gz smg.iso steamos@frame.local:
   ssh steamos@frame.local "tar -xzf GalaxyQuest-SteamFrame-arm64.tar.gz && ~/GalaxyQuest/install.sh ~/smg.iso && rm ~/smg.iso"
   ```

   Beide fragen nach dem Passwort aus Schritt 1. Wird `frame.local` nicht
   gefunden (in WSL häufig), die IP-Adresse der Frame nehmen (`ip a` in der
   Konsole der Frame). Im Ubuntu-Fenster liegt ein Disc-Abbild aus den
   Windows-Downloads unter `/mnt/c/Users/<du>/Downloads/smg.iso`.

Ohne Prolog- und Abspann-Film (2,3 GB weniger) hinter dem Disc-Abbild
`--no-movies` anhängen. Hast du die Disc schon entpackt (Ordner mit `sys` und
`files`), geht statt des Abbilds auch dieser Ordner.

## 3. In Steam einrichten

Das Skript trägt das Spiel in Steam ein, wenn Steam läuft (sonst: Steam →
*Spiele* → *Ein Nicht-Steam-Spiel zur Bibliothek hinzufügen* → *Durchsuchen*
→ `/home/steamos/GalaxyQuest/galaxyquest`). Danach in den *Eigenschaften* des
Eintrags:

- Name: `GalaxyQuest`,
- **„In VR-Bibliothek aufnehmen“ anhaken.**

Zurück in den VR-Modus wechseln und GalaxyQuest aus der Bibliothek starten.

## 4. Ohne install.sh (von Hand)

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

## 5. Bildwiederholrate

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

## Entwicklung

Ein Entwicklungsstand direkt auf die Frame: `tools/push_frame.sh steamos@frame.local [cooked-Ordner]`.

Was sich gegenüber der Quest-Fassung ändert, steht in
[docs/TECHNICAL.md](docs/TECHNICAL.md) unter „Steam Frame (Linux)“.
