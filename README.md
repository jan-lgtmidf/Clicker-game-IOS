# AstroForge: Cosmic Incremental

AstroForge ist ein hoch-qualitatives, mobiles (9:16 Porträt) Clicker- und Idle-Spiel, entwickelt in Godot 4.6.2 (GDScript 2.0). Der Spieler betreibt eine kosmische Schmiede im Orbit einer sich verändernden Anomalie (dem Asteroidenkern).

---

## 🌌 Spielkonzept
*   **Der Kern:** Durch Tippen auf den zentralen Asteroidenkern werden Materialien abgebaut. Das visuelle Design des Kerns schrumpft elastisch bei Klick und federt organisch zurück.
*   **Wirtschaftssystem (3 Ressourcen + Prestige):**
    1.  **Weltraumerz (Erz):** Grundmaterial für grundlegende Shop-Upgrades und Bohrer-Automatisierung.
    2.  **Kosmisches Gas (Gas):** Höherwertiges Material für Produktionsgeschwindigkeiten und Zauber.
    3.  **Sternenkristalle (Kristalle):** Seltenes Material von kritischen Treffern oder Kometen, das zum Freischalten von Talenten im Talentbaum benötigt wird.
    4.  **Sternenstaub (Prestige):** Gibt bei Reset einen permanenten Bonus von `+2%` globaler Produktion und wird für mächtige passive Perks ausgegeben.
    5.  **Dunkle Materie:** Währung der Singularitäts-Kammer, generiert durch den Einsatz von Sternenstaub, zur weiteren Stabilisierung des Reaktors und Beschleunigung der Automation.

---

## ⚡ Spielfeatures & Spielmechaniken

### 1. Game Juice & Visuelles Feedback
*   **Interaktiver Hintergrund:** 30 Sternenstaub-Partikel driften durch den Raum und weichen Klicks repulsiv aus.
*   **Klick-Wellen (Ripples):** Farbkodierte Expansionsringe breiten sich kreisförmig vom Klickpunkt aus.
*   **Floating-Texte:** Schwebende Zahlen steigen bogenförmig auf und faden aus. Kritische Treffer sind doppelt so groß, goldfarben und mit einem Ausrufezeichen versehen.
*   **3D-Button-Effekt:** Alle HUD-Knöpfe skalieren leicht hoch bei Hover und verschieben sich physisch um 2px nach unten (inklusive Skalierungs-Dämpfung) bei Klick.

### 2. Kenney Grafik-Overhaul
*   **Hintergrund:** Gekachelter dunkler Weltraum (`assets/Kenney/kenney_space-shooter-remastered/Backgrounds/darkPurple.png`)
*   **Klickbarer Kern:** Entwickelt sich über 4 Planetenstufen (`assets/Kenney/kenney_planets/`)
*   **Klick-Partikel:** Grau-Meteore (Normal), Gold-Sterne (Krit) aus dem Space Shooter Pack
*   **Kometen:** Rote & gelbe UFOs die über den Screen fliegen
*   **Drohnen:** Raumschiffe mit dynamischen Thruster-Flammen

### 3. Zaubersprüche (Spells)
Drei freischaltbare Zauber bieten temporäre strategische Vorteile (mit individuellen Abklingzeiten):
*   **Overdrive:** Verdoppelt Erzerträge für 10 Sekunden (cyanfarbener Funkenstoß).
*   **Anomalie-Siphon:** Entzieht der Anomalie sofort 15% ihrer kollabierenden Energie.
*   **Magnetnetz:** Zieht 15 Sekunden lang alle automatischen Drohnen und Kometen magnetisch an.

### 4. Reaktor-Diagnostik & Kernschmelze
*   **Supernova-Alarm:** Alle 75–90 Sekunden gerät die Anomalie in einen kritischen Zustand. Der Spieler muss den Kern klicken, um ihn zu stabilisieren.
*   **Reaktor-Kernschmelze:** Schlägt die Stabilisierung fehl, tritt eine Kernschmelze ein. Alle automatischen Bohrer und Siphons fallen für 6 Sekunden aus.

### 5. Synthesizer-Sound
*   Dynamische Musikakkorde werden in Echtzeit generiert und blenden je nach Spielzustand (Normal, Overdrive, Meltdown) ineinander über.

---

## 🗺️ Roadmap & Zukünftige Module

### Abgeschlossene Meilensteine (Phasen 1–9)
*   [x] **Basissysteme & Wirtschaft:** Klick-Mechanik, Erz, Gas, Kristalle, Prestige (Stardust), Singularität (Dark Matter).
*   [x] **Game Juice & Sound:** Real-time Synthesizer Pads, Fades, dynamic camera effects (shake, flash), ripples, floating texts.
*   [x] **Savegame & OTA-Update:** iOS Build (.ipa) Workflow, Auto-Hot-Reload von Autoloads.
*   [x] **Sektoren-System & 3D Reise-Cutscene:** Sektor-Boni (+50% global), 3D-Spaceship Hyperraum Reise (MeshInstance3D, SubViewport).
*   [x] **Visuelle Upgrades:** Combofieber (Subtile Neon-Blitze & Glow), physische abplatzende Gesteinstrümmer, Parallax-Background.
*   [x] **Interaktive Bedrohungen:** Reaktor-Kernschmelze Minigame mit Bouncing Plasma-Bubbles.
*   *   [x] **Bergbau-Drohnen & Artefakte:** Orbitale Laserdrohnen, Kometen-Loot-Drops, Inventarsystem für ausgerüstete Artefakt-Buffs.

### Neue Module in Planung (Nächste Schritte)
1.  **Modul 10A — Kosmische Anomalie-Events:** Zufällige globale Phänomene (z.B. *Kristallschauer*, *Quantenfluktuationen*), die temporäre, massive Boni bieten und den Screen einfärben.
2.  **Modul 10B — Forge-Statistiken:** Ein neues Menüfenster mit detaillierten Messwerten über den aktuellen Run und die gesamte Spielhistorie.

---

## 📱 iOS Build — Schnellanleitung

> ✅ **Vollständig funktionierend und getestet auf echtem iPhone (Juli 2026)**

### Neues Build erstellen:
1. Änderungen im Code vornehmen
2. `git push` im Terminal ausführen
3. Auf GitHub → **Actions** → laufenden Build beobachten (~5–10 Minuten)
4. Nach erfolgreichem Build: **AstroForge-Unsigned-IPA** Artefakt herunterladen

### IPA auf iPhone installieren (kostenlos, kein Apple Developer Account nötig):
1. `.zip` entpacken → `AstroForge.ipa` extrahieren
2. **Sideloadly** öffnen (kostenlos unter [sideloadly.io](https://sideloadly.io))
3. iPhone per USB mit dem Computer verbinden
4. `.ipa` in Sideloadly ziehen
5. Apple ID eingeben (kostenlose ID reicht)
6. "Start" klicken → App wird installiert
7. Auf iPhone: **Einstellungen → Allgemein → VPN & Geräteverwaltung → App vertrauen**

> **Hinweis:** Kostenlose Apple ID → App muss alle **7 Tage** neu signiert werden (Sideloadly wiederholen). Apple Developer Account (99$/Jahr) → unbegrenzte Gültigkeit.

### Technische Details des Workflows:
Vollständige Dokumentation aller gelösten Probleme und der Workflow-Architektur: siehe **[CLAUDE.md](./CLAUDE.md)**, Abschnitt "iOS IPA Build via GitHub Actions".
