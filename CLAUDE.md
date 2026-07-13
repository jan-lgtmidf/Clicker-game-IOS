# CLAUDE.md — AstroForge: Cosmic Incremental
# Persistenter Speicher & Technische Referenz für KI-Assistenten.

---

## 🎯 Projekt-Identität
* **Name:** AstroForge: Cosmic Incremental
* **Engine:** Godot 4.6.2, GDScript 2.0, Mobile 9:16 Portrait (Canvas Items mode)
* **Auflösung:** 540×960 (Native Portrait, gestreckt auf Canvas-Items)
* **UI-Sprache:** Deutsch
* **Code-Sprache:** Englisch
* **Konzept:** Space-Mining Clicker. Der Spieler baut durch Klicks auf das Asteroidensubstrat Erz, Gas und Kristalle ab, schaltet Automatisierungen frei, wehrt Kernschmelzen ab, investiert Sternenstaub und nutzt Zaubersprüche.

---

## 📁 Vollständige Dateistruktur
```
Clicker game/
├── CLAUDE.md                           ← DIESE DATEI (technische Referenz)
├── README.md                           ← Spieldesign & Module
├── project.godot
├── export_presets.cfg                  ← iOS Export-Konfiguration (application/signature="-")
├── .github/workflows/ios_build.yml    ← GitHub Actions Workflow für .ipa Build
├── scenes/
│   ├── Main.tscn                       ← Hauptszene mit HUD, Tabs und Telemetrie
│   ├── Main.gd                         ← HUD, Tabs-Handling, Kometen & Drohnen-Prozess
│   ├── SpaceBackground.tscn
│   ├── SpaceBackground.gd             ← Sternenstaub-Partikel-Repulsion + Klick-Wellen (Ripples)
│   ├── AsteroidCore.tscn
│   ├── AsteroidCore.gd                 ← Kern-Interaktion, Squash & Stretch, Supernova-Ring
│   ├── SkillLineDrawer.gd              ← Zeichnet Talentverbindungen (Draw-Liniengitter)
│   ├── FloatingText.tscn
│   └── FloatingText.gd                 ← Schwebender "+N" Text mit Drift und Fade
└── scripts/
    ├── GameManager.gd                  ← Autoload: Spielzustand, Währungen, Upgrades, Save/Load
    ├── SoundManager.gd                 ← Autoload: SFX & dynamische, synthetisierte Synthesizer-Akkorde
    └── JuiceManager.gd                 ← Autoload: Camera-Shake, Camera-Flash, Partikel & Sparks
```

---

## 🏗️ Architektur-Übersicht

```
Main.tscn (Control)
├── Background (ColorRect mit Shader)
├── SpaceBackground (Node2D)            ← Zeichnet interaktiven Staub & Ripples
├── GameCamera (Camera2D)
├── HUD (CanvasLayer)
│   └── VBoxContainer
│       ├── ResourceHeader (HBox)       ← ERZ, GAS, KRISTALLE, STAUB
│       ├── CoreContainer (Center)
│       │   └── AsteroidCore (Control)  ← Der klickbare Kern
│       ├── SpellsBar (HBox)            ← Overdrive, Siphon, Magnetnetz
│       ├── NavigationTabs (HBox)       ← Shop, Automation, Talente, Singularität, Prestige
│       └── PanelContainer (Tabs)       ← ScrollContainers für Menüs
├── TelemetryDrawer (Control)            ← Reaktordiagnostik (Einklappbar)
└── OfflineModal (ColorRect)            ← Willkommens-Fenster
```

---

## 🧠 GameManager — Datenstruktur & API
`GameManager.gd` ist als Autoload (`GameManager`) registriert. Alle Werte sind typisiert.

### Ressourcentracker:
* `space_ore` (Erz)
* `cosmic_gas` (Gas)
* `star_crystals` (Kristalle)
* `stardust` (Sternenstaub - Prestige)
* `dark_matter` (Dunkle Materie - Singularity)
* `stardust_invested` (Investierter Sternenstaub)
* `lifetime_space_ore` / `lifetime_stardust`

### Upgrade-Kategorien:
* `upgrade_levels`:
  * `click_power`: Stufe des Lasers (+1 Erz pro Klick)
  * `crit_chance`: Kritische Chance (+1% pro Stufe)
  * `crit_multiplier`: Krit-Stärke (+30% pro Stufe)
  * `drill`: Plasmabohrer (+1.5 Erz/Sek)
  * `siphon`: Siphon (+0.4 Gas/Sek)
  * `synthesizer`: Kristallsynthetisierer (+0.1 Kristalle/Sek)
  * `drone_count`: Sammler-Drohnen (Max 8)
  * `drone_speed`: Triebwerke (+25px/s Geschwindigkeit)
* `perk_levels` (Stardust Perks):
  * `global_boost` (+5% Produktion)
  * `starting_ore` (+1000 Erz zum Start)
  * `crit_juice` (+10% Partikel/Ertrag bei Krits)
* `singularity_upgrades` (Dark Matter):
  * `gravitational_pull` (+10% Kometenhäufigkeit & Speed)
  * `quantum_tunneling` (5% Chance auf Doppel-Tick)
  * `chamber_stabilization` (+15% Reaktorsicherheitszeit)

### Zaubersprüche (Spells):
* `overdrive_active` (x2 Klick-Erz, hält 10s)
* `magnetic_net_active` (Zieht alle Drohnen/Kometen an, hält 15s)

---

## ⚡ Core-Systeme & Gameloop-Details

### 1. Klick- & Juice-System
* **Kern:** `AsteroidCore.gd` nutzt ein elastisches Spring-Interpolationsmodell für Klicks.
* **Krit-Klick:** Prüft `crit_chance`. Erzeugt einen doppelten/kritischen Float-Text (Gold, größer, mit "!") und wirft Kristalle ab, wenn das Talent `crystal_refiner` freigeschaltet ist.
* **Ripples & Dust:** `SpaceBackground.gd` berechnet bei jedem Klick eine Repulsionskraft auf 30 Staubpartikel. Gleichzeitig breiten sich farbkodierte Vektor-Kreise (Ripples) aus.

### 2. Kometen & Meltdown-Events
* **Kometen:** Spawnen zufällig am oberen Bildschirmrand. Klicken bringt Bonus-Erz/Kristalle.
* **Reaktor-Supernova:** Alle 75–90s droht eine Supernova. Der Spieler muss den Kern klicken, um Energie zu absorbieren (Containment).
* **Meltdown:** Schlägt das Containment fehl, tritt eine Kernschmelze ein: Alle Automatisierungen gehen für 6 Sekunden offline.

### 3. Synthesized Sound & Music
* **Music Pad:** `SoundManager.gd` synthetisiert Akkorde in Echtzeit.
* **Dynamischer Fader:** Die Musik wechselt stufenlos zwischen `normal` (Dur-Akkord), `overdrive` (heller Sound) und `meltdown` (tiefer, verzerrter Alarm-Moll-Akkord).

### 4. Savegame & Offline-Ertrag
* Speichert unter `user://savegame.save` via `ConfigFile`.
* Berechnet Offline-Erträge mit 60% Effizienz (Capped bei 12 Std.).

### 5. Coordinate Space (WICHTIG!)
* `to_global()` ist auf `Control`-Nodes **nicht verfügbar** (nur auf `Node2D`/`Node3D`).
* Um Koordinaten eines `Control`-Nodes in globale Bildschirmkoordinaten umzurechnen, verwende:
  ```gdscript
  var global_pos = control_node.get_global_transform() * local_pos
  ```
* **Godot-Logs:** Laufzeit-Fehler erscheinen unter:
  `C:\Users\Jaan\AppData\Roaming\Godot\app_userdata\AstroForge\logs\godot.log`

---

## 💻 Code-Konventionen
1. **Explizite Typisierung:** `var x: float = 0.0`
2. **Konstanten:** `const MAX_DRONES: int = 8`
3. **Dokumentation:** Docstrings beginnen mit `##`
4. **Signale:** Kommunikation zwischen Subsystemen über Godot-Signale abwickeln.
5. **Tween Safeguards:** Bevor ein Tween neu instanziiert wird, Referenz prüfen und ggf. `.kill()` aufrufen, um Tween-Fighting zu verhindern.

---

## 📱 iOS IPA Build via GitHub Actions — VOLLSTÄNDIG FUNKTIONIERENDE LÖSUNG

> **Status: ✅ ERFOLGREICH GETESTET — IPA läuft auf echtem iPhone (Juli 2026)**

### Überblick
Das Projekt wird automatisch als unsignierte `.ipa` über GitHub Actions gebaut und als Workflow-Artefakt bereitgestellt. Die `.ipa` kann dann mit **Sideloadly** oder **AltStore** (kostenlos, kein Apple Developer Account nötig) auf ein iPhone installiert werden.

### Wichtigste Erkenntnisse (nach stundenlangem Debugging)

#### Problem 1: Godot schreibt "Apple Distribution" in das Xcode-Projekt
Wenn Godot 4.6.x ein iOS Xcode-Projekt exportiert, schreibt es intern `CODE_SIGN_IDENTITY = "Apple Distribution"` in die `project.pbxproj`. Das verursacht immer diesen Fehler:
```
AstroForge has conflicting provisioning settings. AstroForge is automatically signed
for development, but a conflicting code signing identity Apple Distribution has been
manually specified.
** ARCHIVE FAILED **
ERROR: Project export for preset "iOS" failed.
```
**Dieser Fehler ist HARMLOS und wird bewusst ignoriert** (`|| true`). Das `.xcodeproj`-Verzeichnis wird trotzdem korrekt angelegt. Wir bauen das Projekt danach selbst mit `xcodebuild` neu.

**Fix:** Nach dem Godot-Export laufen `sed`-Befehle, die alle "Apple Distribution"-Einträge in der `project.pbxproj` durch `"-"` (Ad-Hoc) ersetzen.

#### Problem 2: Swift-Linker-Fehler ("swift_Builtin_float not found")
Godot 4.6.2 baut intern Swift-Module in seine iOS-Export-Templates ein. Xcode 15.x auf dem macos-14 GitHub Runner ist zu alt und kennt die Swift 6 Symbole nicht.
```
ld: warning: Could not find or use auto-linked library 'swift_Builtin_float'
Undefined symbols for architecture arm64:
  "__swift_FORCE_LOAD_$_swift_Builtin_float_$_godot_swift_module"
clang: error: linker command failed with exit code 1
** BUILD FAILED **
```
**Fix:** Den Runner auf **Xcode 16.2** updaten:
```yaml
- name: Setup Xcode 16.2
  uses: maxim-lobanov/setup-xcode@v1
  with:
    xcode-version: '16.2'
```

#### Problem 3: `defaults read` im Packaging-Schritt schlug fehl
Im Packaging-Schritt wurde `defaults read "$APP/Info.plist" CFBundleExecutable` verwendet, was auf bestimmten Builds mit einem Syntaxfehler fehlschlug und den gesamten Schritt abbrach.
**Fix:** Den `defaults read`-Aufruf komplett entfernen. Die `.app` wird direkt in `Payload/` kopiert und gezippt, ohne den Executable-Namen prüfen zu müssen.

### Funktionierende `export_presets.cfg` Konfiguration
```ini
[preset.0.options]
application/app_store_team_id="TEAMID1234"  # Kann ein Platzhalter sein
application/signature="-"                   # WICHTIG: "-" für Ad-Hoc, NICHT leer lassen!
```

### Workflow-Struktur (`.github/workflows/ios_build.yml`)
```yaml
1. Checkout Source Code
2. Setup Xcode 16.2          ← KRITISCH: Xcode 15 funktioniert NICHT (Swift 6 fehlt)
3. Setup Godot 4.6.2         ← Godot Binary installieren
4. Install iOS Export Templates
5. Prepare Project           ← godot_mcp Plugin deaktivieren (CI hat keinen Godot-Editor)
6. Export Godot iOS Project  ← Erzeugt .xcodeproj, Godot-interner Build SCHLÄGT FEHL → OK
   └── sed-Cleanup:          ← "Apple Distribution" durch "-" ersetzen in project.pbxproj
7. Build Xcode Project       ← UNSER eigener xcodebuild-Aufruf mit CODE_SIGN_IDENTITY="-"
8. Package into IPA          ← .app → Payload/ → .zip → .ipa umbenennen
9. Upload IPA                ← Als GitHub Actions Artefakt hochladen
```

### Neue .ipa auf iPhone installieren
1. Auf GitHub → **Actions** → letzter erfolgreicher Build → **AstroForge-Unsigned-IPA** herunterladen
2. `.zip` entpacken → `AstroForge.ipa` erhalten
3. **Sideloadly** öffnen, iPhone per USB anschließen
4. `.ipa` in Sideloadly ziehen → Apple ID eingeben → Installieren
5. Auf dem iPhone: Einstellungen → Allgemein → VPN & Geräteverwaltung → App vertrauen

> **Hinweis:** Mit einer kostenlosen Apple ID über Sideloadly muss die App alle 7 Tage neu signiert werden. Mit einem Apple Developer Account (99$/Jahr) kann eine unbegrenzte Ad-Hoc Distribution erstellt werden.

---

## 🖼️ Grafik-Assets (Kenney)
Alle visuellen Assets liegen unter `assets/Kenney/`. Das Projekt nutzt:
* `kenney_space-shooter-remastered/Backgrounds/darkPurple.png` → Kachelbarer Hintergrund
* `kenney_planets/` → Klickbarer Kern (4 Evolutionsstufen)
* `kenney_space-shooter-remastered/Meteors/` → Normale Klick-Partikel
* `kenney_space-shooter-remastered/Power-ups/star_gold.png` → Krit-Partikel
* `kenney_space-shooter-remastered/Ships/` → UFO-Kometen & Sammler-Drohnen
