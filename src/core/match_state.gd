class_name MatchState
extends RefCounted
## Pure headless simulation state container.
## Holds all mutable match entities (buildings, troop groups, fighters).
## Zero Godot Node, rendering, or UI dependencies.

const Enums = preload("res://src/core/enums.gd")

class BuildingState extends RefCounted:
	var id: int = -1
	var stage_id: String = ""
	var position: Vector2 = Vector2.ZERO
	var owner: int = Enums.FactionId.NEUTRAL
	var population: int = 0
	var fractional_population: float = 0.0
	var fractional_damage: float = 0.0
	var block_timer: float = 0.0
	var production_lock_count: int = 0
	var soft_cap: int = 50
	var hard_cap_enabled: bool = false
	var special_type: int = Enums.BuildingSpecialType.NONE
	var shield_hp: int = 0
	var is_active: bool = true

	func to_dict() -> Dictionary:
		return {
			"id": id,
			"stage_id": stage_id,
			"position": position,
			"owner": owner,
			"population": population,
			"soft_cap": soft_cap,
			"special_type": special_type,
			"shield_hp": shield_hp,
			"is_active": is_active,
		}

class TroopGroup extends RefCounted:
	var group_id: int = -1
	var owner: int = Enums.FactionId.NEUTRAL
	var source_id: int = -1
	var target_id: int = -1
	var remaining_to_spawn: int = 0
	var burst_timer: float = 0.0
	var active_fighter_count: int = 0

class FighterUnit extends RefCounted:
	var fighter_id: int = -1
	var group_id: int = -1
	var owner: int = Enums.FactionId.NEUTRAL
	var target_id: int = -1
	var amount: int = 1
	var position: Vector2 = Vector2.ZERO
	var rotation_rad: float = 0.0
	var speed: float = 3.5
	var collision_radius: float = 0.28
	var path: PackedVector2Array = PackedVector2Array()
	var waypoint_index: int = 0
	var is_alive: bool = true

	func to_dict() -> Dictionary:
		return {
			"fighter_id": fighter_id,
			"group_id": group_id,
			"owner": owner,
			"target_id": target_id,
			"amount": amount,
			"position": position,
			"rotation_rad": rotation_rad,
			"speed": speed,
			"is_alive": is_alive,
		}

var active_stage_id: String = ""
var objective_type: int = Enums.ObjectiveType.SKIRMISH
var tick_index: int = 0
var elapsed_time: float = 0.0
var next_group_id: int = 1
var next_fighter_id: int = 1
var buildings: Dictionary = {}   # int -> BuildingState
var groups: Dictionary = {}      # int -> TroopGroup
var fighters: Dictionary = {}    # int -> FighterUnit

func add_building(building: BuildingState) -> void:
	buildings[building.id] = building

func get_building(building_id: int) -> BuildingState:
	return buildings.get(building_id, null)

func get_active_group_count() -> int:
	return groups.size()

func get_active_fighter_count() -> int:
	return fighters.size()

func reset(stage_id: String = "", p_objective_type: int = Enums.ObjectiveType.SKIRMISH) -> void:
	active_stage_id = stage_id
	objective_type = p_objective_type
	tick_index = 0
	elapsed_time = 0.0
	next_group_id = 1
	next_fighter_id = 1
	buildings.clear()
	groups.clear()
	fighters.clear()
