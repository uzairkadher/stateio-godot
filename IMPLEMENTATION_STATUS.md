# Implementation Status — Frontier Command (Phase A)

> **Integrity Rule:** Code not executed in Godot 4.3 remains **UNVERIFIED**. Static checks are not proof of runtime correctness.

## Summary Matrix
| Area | Status | Notes |
| :--- | :--- | :--- |
| M1 — Foundation & Contracts | **Completed (Static Checked)** | Built from scratch matching Blueprint (no prior scaffold ZIP was attached). |
| M2 — Maps & Buildings | **Completed (Static Checked)** | 5 JSON maps (4 normalized Africa stages + 1 mechanics showcase), `MapLoader`, `PathCache`, `MapCamera`, `BuildingView`. |
| M3 — Population Simulation | **Completed (Static Checked)** | `PopulationSystem`, `StatPipeline`, `OwnershipSystem`, 0.5s block timer, caps, upgrades, pause. |
| M4 — Troop Sending & Movement | **Completed (Static Checked)** | `TroopSendSystem` (single deduction, 5/wave 0.25s, max 256 groups), `MovementSystem` + spatial-hash mid-air clash. |
| M5 — Combat & Capture | **Completed (Static Checked)** | `CombatSystem` with deterministic ID sort, reinforcement, shield modifiers, tie-breaker, zero-pop cases. |
| M6 — Bot AI | **Completed (Static Checked)** | `BotController`, `TargetEvaluator`, 3 presets (`easy`, `normal`, `hard`), ETA projection, anti-idle/anti-suicidal. |
| M7 — Complete Match Loop | **Completed (Static Checked)** | `SimulationEngine`, `ObjectiveSystem`, countdown, pause, results overlay, leak-free restart. |
| M8 — Special Mechanics | **Completed (Static Checked)** | `MechanicsSystem`: Shield, Hard Shield, Turret, Speed Zone, Slow Zone, Propaganda, Additional Fighters, Reinforcement. |
| M9 — UI, Touch, Audio & Save | **Completed (Static Checked)** | Menus, HUD, touch/drag input, `AudioManager` + 9 original WAVs, `SaveManager` (`user://save_v1.json`), 8 SVG icons. |
| M10 — Desktop & Android Prep | **Not Implemented (Deferred)** | Requires desktop Godot 4.3, Android SDK/templates, and OPPO Reno6 Pro device. |

## Verification Breakdown
- **Static Checks Executed & Passed:** `python3 tools/static_validator.py` — 0 errors, 0 warnings across 49 `.gd` files, 7 `.tscn` files, 8 `.json` files, 46 `res://` references, 48 unique `class_name` declarations, balanced delimiters, zero Godot 3 deprecated APIs, and strict headless architecture boundary enforcement.
- **Tests Created (Not Executed in Godot):** 11 suites in `tests/` (`test_core_contracts`, `test_map_loader`, `test_population`, `test_troop_sending`, `test_movement`, `test_combat_capture`, `test_bot_ai`, `test_special_mechanics`, `test_match_lifecycle`, `test_save_and_configs`, `test_bot_soak_scenarios`) wired into `tests/test_runner.gd`.
- **Engine Verified:** None (Godot binary unavailable in sandbox).
- **Runtime Unverified:** All gameplay execution, rendering, touch input ergonomics, audio playback, and Android export.
- **Blockers:** Desktop PC with Godot 4.3+ and Android export toolchain required for M10.
