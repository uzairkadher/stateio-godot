class_name SimSnapshot
extends RefCounted
## Read-only snapshot DTO exported by SimulationEngine for AI, View, and HUD.
## Prevents presentation or AI layers from mutating MatchState directly.

var map_id: String = ""
var map_display_name: String = ""
var phase: int = GameEnums.MatchPhase.MENU
var outcome: int = GameEnums.MatchOutcome.NONE
var winner_owner_id: int = GameEnums.OwnerId.NEUTRAL
var elapsed_time: float = 0.0
var countdown_remaining: float = 0.0
var is_paused: bool = false
var tick_count: int = 0

var buildings: Dictionary = {}       # String id -> Dictionary snapshot
var building_order: Array[String] = []
var troop_groups: Array = []         # Array of Dictionary snapshots
var mechanics: Array = []            # Array of Dictionary snapshots
var faction_power: Dictionary = {}   # owner_id -> int total population
var faction_buildings: Dictionary = {} # owner_id -> int count

static func build_from(state: MatchState) -> SimSnapshot:
	var snap := SimSnapshot.new()
	snap.map_id = state.map_id
	snap.map_display_name = state.map_display_name
	snap.phase = state.phase
	snap.outcome = state.outcome
	snap.winner_owner_id = state.winner_owner_id
	snap.elapsed_time = state.elapsed_time
	snap.countdown_remaining = state.countdown_remaining
	snap.is_paused = state.is_paused
	snap.tick_count = state.tick_count
	snap.building_order = state.building_order.duplicate()

	for bid in state.building_order:
		var b: BuildingState = state.buildings[bid]
		snap.buildings[bid] = b.to_snapshot_dict()
		snap.faction_buildings[b.owner_id] = int(snap.faction_buildings.get(b.owner_id, 0)) + 1
		snap.faction_power[b.owner_id] = int(snap.faction_power.get(b.owner_id, 0)) + b.population

	for g in state.troop_groups:
		var grp: TroopGroupState = g
		if not grp.is_eliminated and not grp.is_arrived:
			snap.troop_groups.append(grp.to_snapshot_dict())
			snap.faction_power[grp.owner_id] = int(snap.faction_power.get(grp.owner_id, 0)) + grp.amount

	for mid in state.mechanic_order:
		var m: SpecialMechanicState = state.mechanics[mid]
		snap.mechanics.append(m.to_snapshot_dict())

	return snap
