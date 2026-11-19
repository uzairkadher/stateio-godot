# AI Coding Agent Handoff & File Ownership Rules

## 1. Locked Core Contracts (`src/core/`)
`src/core/` is **LOCKED** as of Milestone 1. Downstream agents (Milestones 2–10) may **import** from `src/core/` using `preload("res://src/core/...")`, but **must not** modify any file in `src/core/` without a dedicated contract-change PR reviewed before other agents rebase.

### Locked Contract Files
- `src/core/enums.gd` — Canonical enums (`FactionId`, `GameState`, `StageState`, `ObjectiveType`, `ObjectiveOutcome`, `StatType`, `StatOp`, `BuildingSpecialType`, `CommandType`)
- `src/core/event_bus.gd` — Pure `RefCounted` cross-layer pub/sub signals
- `src/core/game_state_manager.gd` — Strict match lifecycle FSM
- `src/core/match_state.gd` — Pure simulation data (`MatchState`, `BuildingState`, `TroopGroup`, `FighterUnit`)
- `src/core/send_command.gd` — Unified command struct emitted by both Player Input and Bot AI
- `src/core/sim_snapshot.gd` — Read-only deep-copied snapshot for AI and HUD
- `src/core/config_loader.gd` — JSON config loader & validator

## 2. Strict Directory Ownership Boundaries
| Agent | Owned Directories | Forbidden Directories |
| :--- | :--- | :--- |
| **Agent A (Simulation)** | `src/sim/` | `src/view/`, `src/ui/`, `scenes/`, `src/ai/` |
| **Agent B (Map & Data)** | `src/map/`, `src/persistence/`, `data/` | `src/sim/`, `src/view/`, `src/ai/` |
| **Agent C (Bot AI)** | `src/ai/` | `src/sim/`, `src/view/`, `src/ui/`, `scenes/` |
| **Agent D (View & UI)** | `src/view/`, `src/ui/`, `scenes/`, `assets/` | `src/sim/`, `src/ai/`, `src/map/` |
| **Agent E (QA & Build)** | `tests/` | Direct production edits without PR |

## 3. Architectural Purity Rules
1. **No Godot Nodes in `src/core/` or `src/sim/`**: Every simulation class must extend `RefCounted` so `godot --headless --path . -s res://tests/run_tests.gd` executes without a graphics context.
2. **Single-Authority Mutations**:
   - Only `OwnershipSystem` (M3) may change `BuildingState.owner`.
   - Only `PopulationSystem` (M3) may change `BuildingState.population`.
   - Only `TroopSendSystem` (M4) may consume `SendCommand` and create `TroopGroup`s.
3. **Read-Only AI & UI**: `src/ai/` and `src/ui/` must consume `SimSnapshot` + `EventBus` signals; they must never mutate `MatchState` directly.
4. **Preload Discipline**: Always use explicit `const X = preload("res://...")` in addition to `class_name` so headless CLI tests work on fresh checkouts without a pre-built `.godot/` cache.

## 4. Merge & Completion Reporting Protocol
Before reporting any milestone complete, an agent must:
1. Work on a dedicated feature branch (e.g., `feat/m2-map-loader`).
2. List every added/modified file and confirm zero edits outside its owned directory.
3. Run `godot --headless --path . -s res://tests/run_tests.gd` and attach the raw exit code and output.
