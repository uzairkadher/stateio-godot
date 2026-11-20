class_name SendCommand
extends RefCounted
## Unified immutable command contract emitted identically by InputController (player)
## and BotController (AI). Bots cannot bypass validation or wave limits.

var command_id: String = ""
var owner_id: int = GameEnums.OwnerId.NEUTRAL
var source_ids: Array[String] = []
var target_id: String = ""
var send_ratio: float = 1.0
var issued_at_time: float = 0.0

func _init(
	p_owner_id: int = GameEnums.OwnerId.NEUTRAL,
	p_source_ids: Array[String] = [],
	p_target_id: String = "",
	p_send_ratio: float = 1.0,
	p_command_id: String = "",
	p_issued_at: float = 0.0
) -> void:
	owner_id = p_owner_id
	source_ids = p_source_ids.duplicate()
	target_id = p_target_id
	send_ratio = clampf(p_send_ratio, 0.0, 1.0)
	command_id = p_command_id
	issued_at_time = p_issued_at

func is_structurally_valid() -> bool:
	if owner_id == GameEnums.OwnerId.NEUTRAL:
		return false
	if target_id.is_empty():
		return false
	if source_ids.is_empty():
		return false
	if send_ratio <= 0.0 or send_ratio > 1.0:
		return false
	return true

func to_dict() -> Dictionary:
	return {
		"command_id": command_id,
		"owner_id": owner_id,
		"source_ids": source_ids.duplicate(),
		"target_id": target_id,
		"send_ratio": send_ratio,
		"issued_at_time": issued_at_time,
	}
