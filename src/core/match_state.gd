class_name MatchState
extends RefCounted
## Single source of truth for all runtime match state.
## Mutations are strictly performed by single-authority simulation systems.

var map_id: String = ""
var map_display_name: String = ""
var difficulty: String = "normal"
var objective_type: int = GameEnums.ObjectiveType.SKIRMISH
var phase: int = GameEnums.MatchPhase.MENU
var outcome: int = GameEnums.MatchOutcome.NONE
var winner_owner_id: int = GameEnums.OwnerId.NEUTRAL

var elapsed_time: float = 0.0
var countdown_remaining: float = 0.0
var is_paused: bool = false
var tick_count: int = 0

var buildings: Dictionary = {}          # String building_id -> BuildingState
var building_order: Array[String] = []  # Deterministic iteration order
var troop_groups: Array = []            # Array of TroopGroupState
var pending_waves: Array = []           # Queued burst wave dictionaries
var mechanics: Dictionary = {}          # String mechanic_id -> SpecialMechanicState
var mechanic_order: Array[String] = []  # Deterministic iteration order

var next_group_id: int = 1
var processed_command_ids: Dictionary = {} # command_id -> true (duplicate protection)
var reinforcement_requests_used: Dictionary = {} # owner_id -> int

# Match telemetry
var total_troops_sent: Dictionary = {}     # owner_id -> int
var total_troops_lost: Dictionary = {}     # owner_id -> int
var total_captures: Dictionary = {}        # owner_id -> int
var active_factions: Array[int] = []

func reset() -> void:
	phase = GameEnums.MatchPhase.MENU
	outcome = GameEnums.MatchOutcome.NONE
	winner_owner_id = GameEnums.OwnerId.NEUTRAL
	elapsed_time = 0.0
	countdown_remaining = 0.0
	is_paused = false
	tick_count = 0
	buildings.clear()
	building_order.clear()
	troop_groups.clear()
	pending_waves.clear()
	mechanics.clear()
	mechanic_order.clear()
	next_group_id = 1
	processed_command_ids.clear()
	reinforcement_requests_used.clear()
	total_troops_sent.clear()
	total_troops_lost.clear()
	total_captures.clear()
	active_factions.clear()

func get_building(building_id: String) -> BuildingState:
	return buildings.get(building_id, null)

func get_owner_building_count(owner_id: int) -> int:
	var count: int = 0
	for bid in building_order:
		var b: BuildingState = buildings[bid]
		if b.owner_id == owner_id:
			count += 1
	return count

func get_owner_total_population(owner_id: int) -> int:
	var total: int = 0
	for bid in building_order:
		var b: BuildingState = buildings[bid]
		if b.owner_id == owner_id:
			total += b.population
	for g in troop_groups:
		var grp: TroopGroupState = g
		if not grp.is_eliminated and not grp.is_arrived and grp.owner_id == owner_id:
			total += grp.amount
	for w in pending_waves:
		if int(w.get("owner_id", 0)) == owner_id:
			total += int(w.get("remaining_amount", 0))
	return total
