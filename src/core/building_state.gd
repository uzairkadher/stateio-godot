class_name BuildingState
extends RefCounted
## Pure simulation state for a single building/territory node.

var id: String = ""
var display_name: String = ""
var position: Vector2 = Vector2.ZERO
var owner_id: int = GameEnums.OwnerId.NEUTRAL
var population: int = 0
var population_accumulator: float = 0.0
var fractional_damage: float = 0.0
var population_cap: int = 50
var hard_cap: int = 999
var base_spawn_rate: float = 1.0
var building_type: String = "standard"
var upgrade_level: int = 1
var mechanic_type: int = GameEnums.SpecialMechanicType.NONE
var block_timer: float = 0.0
var production_lock_count: int = 0
var shield_hp: float = 0.0
var max_shield_hp: float = 0.0
var is_selected: bool = false

func can_produce() -> bool:
	if production_lock_count > 0:
		return false
	if block_timer > 0.0:
		return false
	return population < population_cap

func to_snapshot_dict() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"position": position,
		"owner_id": owner_id,
		"population": population,
		"population_cap": population_cap,
		"base_spawn_rate": base_spawn_rate,
		"building_type": building_type,
		"upgrade_level": upgrade_level,
		"mechanic_type": mechanic_type,
		"block_timer": block_timer,
		"shield_hp": shield_hp,
		"max_shield_hp": max_shield_hp,
		"is_selected": is_selected,
	}

static func from_map_dict(data: Dictionary, default_hard_cap: int = 999) -> BuildingState:
	var b := BuildingState.new()
	b.id = str(data.get("id", ""))
	b.display_name = str(data.get("name", b.id))
	var pos_dict: Dictionary = data.get("position", {})
	b.position = Vector2(float(pos_dict.get("x", 0.0)), float(pos_dict.get("y", 0.0)))
	b.owner_id = int(data.get("owner_id", GameEnums.OwnerId.NEUTRAL))
	b.population = maxi(0, int(data.get("initial_population", 10)))
	b.population_cap = maxi(1, int(data.get("population_cap", 50)))
	b.hard_cap = default_hard_cap
	b.base_spawn_rate = maxf(0.0, float(data.get("spawn_rate", 1.0)))
	b.building_type = str(data.get("building_type", "standard"))
	b.upgrade_level = maxi(1, int(data.get("upgrade_level", 1)))
	b.mechanic_type = GameEnums.mechanic_from_string(str(data.get("mechanic_type", "")))
	return b
