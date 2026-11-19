# Territory Capture — Milestone 1 Scaffold (Godot 4.3.stable)

Independent territory-capture strategy game scaffold built for parallel AI coding agent execution.

## Pinned Engine Version
- **Godot `4.3.stable`** (Standard / GDScript, `GL Compatibility` renderer)
- Version pinned in `ENGINE_VERSION.txt` and `project.godot` (`config_version=5`).
- Do **not** upgrade or switch engines without an explicit architecture decision.

## Project Structure
```text
project.godot                 # Pinned Godot 4.3.stable project config (1080x2400 portrait)
ENGINE_VERSION.txt            # Exact pinned engine string (4.3.stable)
AGENT_HANDOFF.md              # Strict AI agent ownership & integration rules
data/gameplay_config.json     # Tunable gameplay parameters (no hardcoded balance constants)
scenes/main.tscn              # Minimal runnable boot scene (M1 verification)
src/core/                     # LOCKED pure RefCounted contracts (zero Node/UI dependencies)
src/sim/                      # Agent A: Headless simulation (M3-M5, M8)
src/map/                      # Agent B: Map loader & AStarGrid2D pathfinding (M2, M8)
src/ai/                       # Agent C: Utility Bot AI (M6)
src/view/                     # Agent D: Rendering, pooled visuals, input (M4, M9)
src/ui/                       # Agent D: HUD, overlays, settings (M7, M9)
src/persistence/              # Agent B: SaveManager & ProgressionManager (M8)
tests/                        # Agent E: Headless CLI test runner & contract unit tests
```

## Setup & Local Verification
1. Install **Godot 4.3.stable** (Standard, non-Mono) from [godotengine.org](https://godotengine.org/download/archive/4.3-stable/).
2. Unzip this project into a working directory.
3. **Run Headless Automated Tests** (works immediately without opening the editor):
   ```bash
   godot --headless --path . -s res://tests/run_tests.gd
   ```
   Expected exit code: `0` with `ALL TESTS PASSED.`
4. **Launch Minimal Runnable Scene**:
   ```bash
   godot --path .
   ```
   Or open `project.godot` in Godot 4.3 and press **F5**. The portrait window displays the Milestone 1 boot verification screen (`Core Contracts: LOADED`, `Config Valid: true`, `FSM State: MENU`).

## Sandbox Verification Note
This scaffold was generated in an offline Linux environment where the `godot` 4.3 binary was not pre-installed. Static validation (GDScript structure, `preload` path resolution, `.tscn` resource integrity, JSON schema, and zero-Node purity in `src/core/`) passed 100%, while live Godot runtime launch and headless test execution must be run locally on Godot 4.3.stable before unlocking Milestone 2.
