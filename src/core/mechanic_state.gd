class_name SpecialMechanicState
extends RefCounted
## Modular runtime state for a special building mechanic or active timed effect.

var id: String = ""
var mechanic_type: int = GameEnums.SpecialMechanicType.NONE
var building_id: String = ""
var owner_id: int = GameEnums.OwnerId.NEUTRAL
var position: Vector2 = Vector2.ZERO
var is_enabled: bool = true
var is_active: bool = true
var duration_total: float = 0.0
var duration_remaining: float = 0.0
var cooldown_total: float = 0.0
var cooldown_remaining: float = 0.0
var zone_radius: float = 1.0
var impact_percentage: float = 0.0
var shield_hp: float = 0.0
var max_shield_hp: float = 0.0
var stack_count: int = 1
var max_stacks: int = 1
var work_for_neutrals: bool = true
var work_when_pop_zero: bool = true
var triggered_once: bool = false
var turret_timer: float = 0.0
var last_target_pos: Vector2 = Vector2.ZERO
var beam_flash_timer: float = 0.0

func to_snapshot_dict() -> Dictionary:
	return {
		"id": id,
		"mechanic_type": mechanic_type,
		"building_id": building_id,
		"owner_id": owner_id,
		"position": position,
		"is_enabled": is_enabled,
		"is_active": is_active,
		"duration_remaining": duration_remaining,
		"cooldown_remaining": cooldown_remaining,
		"zone_radius": zone_radius,
		"impact_percentage": impact_percentage,
		"shield_hp": shield_hp,
		"max_shield_hp": max_shield_hp,
		"stack_count": stack_count,
		"last_target_pos": last_target_pos,
		"beam_flash_timer": beam_flash_timer,
	}
