class_name TroopGroupState
extends RefCounted
## Pure simulation state for an in-flight troop wave/group.

var id: int = 0
var owner_id: int = GameEnums.OwnerId.NEUTRAL
var source_id: String = ""
var target_id: String = ""
var amount: int = 0
var position: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.RIGHT
var waypoints: Array[Vector2] = []
var current_waypoint_index: int = 0
var base_speed: float = 3.5
var current_speed: float = 3.5
var speed_multiplier: float = 1.0
var distance_traveled: float = 0.0
var total_route_length: float = 0.0
var elapsed_time: float = 0.0
var is_arrived: bool = false
var is_eliminated: bool = false

func remaining_distance() -> float:
	return maxf(0.0, total_route_length - distance_traveled)

func estimated_eta() -> float:
	var eff_speed: float = maxf(0.1, current_speed)
	return remaining_distance() / eff_speed

func to_snapshot_dict() -> Dictionary:
	return {
		"id": id,
		"owner_id": owner_id,
		"source_id": source_id,
		"target_id": target_id,
		"amount": amount,
		"position": position,
		"direction": direction,
		"current_speed": current_speed,
		"eta": estimated_eta(),
		"is_arrived": is_arrived,
		"is_eliminated": is_eliminated,
	}
