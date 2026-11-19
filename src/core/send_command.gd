class_name SendCommand
extends RefCounted
## Unified troop-dispatch command emitted identically by Player Input and Bot AI.
## Pure RefCounted — zero Godot Node or UI dependencies.

const Enums = preload("res://src/core/enums.gd")

var faction: int = Enums.FactionId.NEUTRAL
var source_ids: PackedInt32Array = PackedInt32Array()
var target_id: int = -1
var send_fraction: float = 1.0
var issued_tick: int = 0

func _init(
	p_faction: int = Enums.FactionId.NEUTRAL,
	p_source_ids: PackedInt32Array = PackedInt32Array(),
	p_target_id: int = -1,
	p_send_fraction: float = 1.0,
	p_issued_tick: int = 0
) -> void:
	faction = p_faction
	source_ids = p_source_ids.duplicate()
	target_id = p_target_id
	send_fraction = clampf(p_send_fraction, 0.0, 1.0)
	issued_tick = p_issued_tick

func is_valid() -> bool:
	if faction == Enums.FactionId.NEUTRAL:
		return false
	if source_ids.is_empty():
		return false
	if target_id < 0:
		return false
	if send_fraction <= 0.0 or send_fraction > 1.0:
		return false
	for sid in source_ids:
		if sid < 0 or sid == target_id:
			return false
	return true
