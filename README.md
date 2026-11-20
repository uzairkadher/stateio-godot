# Frontier Command — Phase A Prototype (Godot 4.3+)

> **Integrity Notice:** This project was authored and statically validated in an environment without the Godot 4.3 binary installed. All GDScript runtime behavior, `.tscn` scene instantiation, and automated Godot tests are **UNVERIFIED** until executed in Godot 4.3 on desktop (Milestone M10).

## Project Overview
**Frontier Command** is an independent, offline-capable, mobile-first 2D territory capture strategy game inspired by the State.io gameplay loop. Zero proprietary code, branding, or extracted commercial assets are included; all art (`assets/original_art/`) and sound effects (`assets/audio/`) are original placeholders.

## Implemented Phase A Features (M1–M9 — Source-Complete, Engine-UNVERIFIED)
- **M1 Foundation:** Locked zero-Node core contracts (`GameEnums`, `EventBus`, `SendCommand`, `BuildingState`, `TroopGroupState`, `SpecialMechanicState`, `MatchState`, `SimSnapshot`, `GameStateManager`).
- **M2 Maps & Buildings:** Data-driven JSON `MapLoader` with schema validation, `PathCache` (`AStarGrid2D` 0.5u cells), 5 complete playable maps (4 Africa-inspired normalized stages + 1 special-mechanics showcase), `MapCamera` with pan/zoom/bounds, and procedural `BuildingView`.
- **M3 Population Simulation:** Fixed-dt `PopulationSystem`, `StatPipeline`, `OwnershipSystem`, `0.5s` production block timer, soft/hard caps, upgrade scaling, pause/resume, and non-negative enforcement.
- **M4 Troop Sending & Movement:** Single-deduction `TroopSendSystem` (25%/50%/100% ratios, 5/wave every 0.25s, max 256 groups, duplicate command protection) and time-based `MovementSystem` with spatial-hash 1:1 mid-air clashes.
- **M5 Combat & Capture:** Deterministic `CombatSystem` (sorted by group ID on simultaneous arrivals), friendly reinforcement, shield damage interception, configurable tie-breaker, and telemetry.
- **M6 Bot AI:** Travel-time-aware utility `BotController` + `TargetEvaluator` with 3 presets (`easy`, `normal`, `hard`), reaction delays, anti-idle and anti-suicidal guards, emitting identical `SendCommand` structs.
- **M7 Match Loop:** `SimulationEngine` + `ObjectiveSystem` (SKIRMISH win/lose/draw), countdown, pause/resume, results overlay, and leak-free restart/replay.
- **M8 Special Mechanics:** Modular `MechanicsSystem` supporting Shield, Hard Shield, Turret, Speed Zone, Slow Zone, Propaganda, Additional Fighters, and Reinforcement.
- **M9 UI, Input, Audio & Save:** `MainMenu`, `MapSelectMenu`, `SettingsMenu`, `AboutMenu`, `GameHUD`, `InputController` (tap & drag multi-select), voice-limiting `AudioManager` with 9 original WAV files, and atomic `SaveManager` (`user://save_v1.json`).

## Folder Structure
```
frontier_command/
├── project.godot
├── src/
│   ├── core/       # Locked contracts & FSM (zero Node dependencies)
│   ├── sim/        # Headless deterministic simulation systems
│   ├── ai/         # Utility Bot AI (reads SimSnapshot, emits SendCommand)
│   ├── map/        # JSON MapLoader & AStarGrid2D PathCache
│   ├── view/       # Camera2D, BuildingView, TroopRenderer, InputController, MatchController
│   ├── ui/         # AppRouter, Menus, GameHUD
│   └── services/   # AudioManager, SaveManager
├── scenes/         # Godot 4.3 .tscn scenes (entry: res://scenes/main.tscn)
├── data/           # Tunable balance, mechanics, bot presets, and 5 JSON maps
├── assets/         # Original SVG icons and synthesized WAV audio
├── tests/          # Headless Godot 4.3 unit, integration, and soak tests
└── tools/          # Static validator (python3 tools/static_validator.py)
```

## How to Open & Run
1. Install **Godot 4.3 (Standard)** on desktop.
2. Open the Godot Project Manager, click **Import**, and select `project.godot`.
3. Press **F5** (or run `res://scenes/main.tscn`) to launch the game.

## How to Run Tests
```bash
# Static check (works anywhere with Python 3)
python3 tools/static_validator.py

# Godot headless import + automated test suite (requires Godot 4.3 on desktop)
godot --headless --path . --import
godot --headless --path . -s res://tests/test_runner.gd
```

## Controls
- **Tap source -> Tap target:** Send troops from one owned building.
- **Drag across friendly buildings -> Release on target:** Multi-select send.
- **Tap empty space:** Cancel current selection.
- **25% / 50% / 100% buttons:** Choose send percentage.
- **Reinforce +20 button:** Call once-per-match reinforcement on selected friendly node.
- **Pinch / Mouse wheel:** Zoom camera; **Right-drag:** Pan camera.

## Configuration
Edit JSON files under `data/balance/gameplay_config.json`, `data/balance/mechanics_config.json`, `data/bots/bot_presets.json`, and `data/maps/*.json` without modifying code.

## Known Limitations
- Runtime execution, Godot parse checks, Android APK export, and real-device OPPO Reno6 Pro testing are **UNVERIFIED** (deferred to M10).
- Visuals and audio are clean programmatic/placeholder assets intended for easy replacement.
