# Agent Handoff Guide — Frontier Command

## Architecture (Four-Layer Decoupled Design)
1. **Layer 0 (`src/core/`):** Locked data contracts (`GameEnums`, `EventBus`, `SendCommand`, `BuildingState`, `TroopGroupState`, `SpecialMechanicState`, `MatchState`, `SimSnapshot`, `GameStateManager`). Zero `Node` or rendering dependencies.
2. **Layer 1 (`src/sim/`, `src/ai/`, `src/map/`):** Headless deterministic simulation, utility Bot AI, JSON `MapLoader`, and `AStarGrid2D` `PathCache`. Must never import `Node2D`, `Control`, `CanvasItem`, `src/view/`, or `src/ui/`.
3. **Layer 2 (`src/view/`, `src/ui/`):** Presentation, touch/mouse input, procedural vector rendering, HUD, and menus. Reads `SimSnapshot` and submits `SendCommand` only.
4. **Layer 3 (`src/services/`, `data/`, `tests/`):** `SaveManager`, `AudioManager`, tunable JSON configs, and headless tests.

## File Ownership Boundaries (Multi-Agent Safe)
- **Core / Integrator:** `project.godot`, `src/core/*`, `scenes/main.tscn`, `src/ui/app_router.gd`
- **Simulation Agent:** `src/sim/*`
- **Map & Data Agent:** `src/map/*`, `data/*`
- **AI Agent:** `src/ai/*`
- **View & UI Agent:** `src/view/*`, `src/ui/*`, `scenes/*`, `src/services/*`
- **QA Agent:** `tests/*`, `tools/*`

## Core Contracts (Single Source of Truth)
- **Single-authority mutations:** Only `OwnershipSystem` mutates `owner_id`; only `PopulationSystem` mutates `population`; only `TroopSendSystem` validates and executes `SendCommand`.
- **Unified command path:** Both `InputController` and `BotController` construct `SendCommand` and submit via `SimulationEngine.submit_command(cmd)`.

## Completed vs. Incomplete Systems
- **Completed (Source-Level, Engine-UNVERIFIED):** M1–M9 (all core contracts, 5 maps, population, troop sending/bursts, A* movement, mid-air clash, combat/capture, 3-preset Utility AI, match loop/restart, 8 special mechanics, menus/HUD/touch/audio/save, 11 headless test suites, static validator).
- **Incomplete / Deferred (M10):** Desktop Godot 4.3 import/parse verification, running `tests/test_runner.gd` in Godot, profiling 250+ troops, Android export preset & APK build, OPPO Reno6 Pro device test.

## Known Risks / Potential First-Import Fixes
1. `test_runner.gd` relies on global `class_name` registration; run `godot --headless --path . --import` once before running `tests/test_runner.gd`.
2. Verify `InputEventScreenTouch` + `emulate_touch_from_mouse=true` does not double-fire on Android (in `src/view/input_controller.gd`, guard mouse events when running on touchscreens if double-triggers appear on device).
3. Verify `AudioStreamWAV` looping for `assets/audio/ambient_loop.wav` in Godot 4.3 import settings (`edit/loop_mode=1`).

## Instructions for the Next Coding Agent
1. Read `IMPLEMENTATION_STATUS.md` and `DESKTOP_HANDOFF.md`.
2. Run `python3 tools/static_validator.py` before and after any edits.
3. Preserve zero-Node boundaries in `src/core/`, `src/sim/`, `src/ai/`, and `src/map/`.
4. When receiving Godot 4.3 parse/runtime logs from the user's PC, fix reported line-level errors without breaking contract signatures, then re-run `tests/test_runner.gd`.
