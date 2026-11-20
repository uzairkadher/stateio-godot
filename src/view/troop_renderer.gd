class_name TroopRenderer
extends Node2D
## Procedural renderer for in-flight troop groups, turret beams, and brief hit/capture bursts.

var pixels_per_unit: float = 100.0
var _groups: Array = []
var _mechanics: Array = []
var _bursts: Array = []  # {"pos": Vector2, "color": Color, "ttl": float}

func sync_from_snapshot(snapshot: SimSnapshot, ppu: float = 100.0) -> void:
	pixels_per_unit = ppu
	_groups = snapshot.troop_groups
	_mechanics = snapshot.mechanics
	queue_redraw()

func add_burst(world_pos_units: Vector2, color: Color) -> void:
	_bursts.append({"pos": world_pos_units * pixels_per_unit, "color": color, "ttl": 0.30})

func _process(delta: float) -> void:
	if _bursts.is_empty():
		return
	for i in range(_bursts.size() - 1, -1, -1):
		_bursts[i]["ttl"] = float(_bursts[i]["ttl"]) - delta
		if float(_bursts[i]["ttl"]) <= 0.0:
			_bursts.remove_at(i)
	queue_redraw()

func _draw() -> void:
	# Turret beams
	for m in _mechanics:
		if int(m.get("mechanic_type", 0)) == GameEnums.SpecialMechanicType.TURRET and float(m.get("beam_flash_timer", 0.0)) > 0.0:
			var from_p: Vector2 = m["position"] * pixels_per_unit
			var to_p: Vector2 = m["last_target_pos"] * pixels_per_unit
			draw_line(from_p, to_p, Color(1.0, 0.35, 0.15, 0.95), 4.0)

	# Active troop groups
	for g in _groups:
		var pos: Vector2 = g["position"] * pixels_per_unit
		var dir: Vector2 = g.get("direction", Vector2.RIGHT)
		var owner_id: int = int(g.get("owner_id", 0))
		var amount: int = int(g.get("amount", 1))
		var col: Color = GameEnums.owner_color(owner_id)
		var r: float = clampf(9.0 + float(amount) * 0.9, 9.0, 18.0)
		# Motion trail
		draw_line(pos - dir * 18.0, pos, Color(col.r, col.g, col.b, 0.45), 4.0)
		draw_circle(pos, r, col)
		draw_arc(pos, r, 0.0, TAU, 16, Color(1, 1, 1, 0.85), 2.0)

	# Hit / capture bursts
	for b in _bursts:
		var t: float = float(b["ttl"]) / 0.30
		var c: Color = b["color"]
		c.a = t
		draw_arc(b["pos"], 18.0 + (1.0 - t) * 28.0, 0.0, TAU, 20, c, 3.0)
