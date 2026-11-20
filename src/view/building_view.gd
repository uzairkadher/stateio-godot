class_name BuildingView
extends Node2D
## Procedural vector presentation for a single building node (M2 & M9).
## Reads SimSnapshot dictionaries only — zero gameplay formulas live here.

var building_id: String = ""
var visual_radius: float = 38.0
var pixels_per_unit: float = 100.0
var _owner_id: int = GameEnums.OwnerId.NEUTRAL
var _population: int = 0
var _population_cap: int = 50
var _shield_hp: float = 0.0
var _max_shield_hp: float = 0.0
var _mechanic_type: int = GameEnums.SpecialMechanicType.NONE
var _is_selected: bool = false
var _is_valid_target_highlight: bool = false

var _base_pos: Vector2 = Vector2.ZERO
var _shake_timer: float = 0.0
var _bump_timer: float = 0.0
var _pop_label: Label = null
var _badge_label: Label = null

func _ready() -> void:
	_pop_label = Label.new()
	_pop_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pop_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_pop_label.position = Vector2(-36, -16)
	_pop_label.size = Vector2(72, 32)
	_pop_label.add_theme_font_size_override("font_size", 22)
	add_child(_pop_label)

	_badge_label = Label.new()
	_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_badge_label.position = Vector2(-40, visual_radius + 4)
	_badge_label.size = Vector2(80, 22)
	_badge_label.add_theme_font_size_override("font_size", 13)
	add_child(_badge_label)

func sync_from_snapshot(b_dict: Dictionary, ppu: float = 100.0) -> void:
	pixels_per_unit = ppu
	building_id = str(b_dict.get("id", ""))
	var world_pos: Vector2 = b_dict.get("position", Vector2.ZERO) * pixels_per_unit
	_base_pos = world_pos
	if _shake_timer <= 0.0:
		position = _base_pos

	var new_owner: int = int(b_dict.get("owner_id", 0))
	if new_owner != _owner_id:
		_bump_timer = 0.25
	_owner_id = new_owner
	_population = int(b_dict.get("population", 0))
	_population_cap = int(b_dict.get("population_cap", 50))
	_shield_hp = float(b_dict.get("shield_hp", 0.0))
	_max_shield_hp = float(b_dict.get("max_shield_hp", 0.0))
	_mechanic_type = int(b_dict.get("mechanic_type", 0))
	_is_selected = bool(b_dict.get("is_selected", false))

	if _pop_label != null:
		_pop_label.text = str(_population)
	if _badge_label != null:
		_badge_label.text = _mechanic_short_label(_mechanic_type)
	queue_redraw()

func set_selected_visual(selected: bool) -> void:
	_is_selected = selected
	queue_redraw()

func set_target_highlight(highlighted: bool) -> void:
	_is_valid_target_highlight = highlighted
	queue_redraw()

func trigger_hit_shake() -> void:
	_shake_timer = 0.10

func _process(delta: float) -> void:
	if _shake_timer > 0.0:
		_shake_timer = maxf(0.0, _shake_timer - delta)
		position = _base_pos + Vector2(randf_range(-5.0, 5.0), randf_range(-5.0, 5.0))
		if _shake_timer <= 0.0:
			position = _base_pos
	if _bump_timer > 0.0:
		_bump_timer = maxf(0.0, _bump_timer - delta)
		var s: float = 1.0 + 0.12 * (_bump_timer / 0.25)
		scale = Vector2(s, s)
	else:
		scale = Vector2.ONE

func _draw() -> void:
	var fill: Color = GameEnums.owner_color(_owner_id)
	var border: Color = Color(0.95, 0.97, 1.0, 0.9)

	# Special zone radius ring
	if _mechanic_type == GameEnums.SpecialMechanicType.SPEED_ZONE:
		draw_arc(Vector2.ZERO, 1.0 * pixels_per_unit, 0.0, TAU, 36, Color(0.13, 0.77, 0.37, 0.45), 3.0)
	elif _mechanic_type == GameEnums.SpecialMechanicType.SLOW_ZONE:
		draw_arc(Vector2.ZERO, 1.0 * pixels_per_unit, 0.0, TAU, 36, Color(0.66, 0.33, 0.97, 0.45), 3.0)
	elif _mechanic_type == GameEnums.SpecialMechanicType.TURRET:
		draw_arc(Vector2.ZERO, 2.0 * pixels_per_unit, 0.0, TAU, 48, Color(0.94, 0.27, 0.27, 0.30), 2.0)

	# Selection / target highlight rings
	if _is_selected:
		draw_arc(Vector2.ZERO, visual_radius + 10.0, 0.0, TAU, 32, Color(1.0, 0.92, 0.25, 1.0), 4.5)
	elif _is_valid_target_highlight:
		draw_arc(Vector2.ZERO, visual_radius + 8.0, 0.0, TAU, 32, Color(0.35, 0.95, 0.65, 0.9), 3.5)

	# Main building circle
	draw_circle(Vector2.ZERO, visual_radius, fill)
	draw_arc(Vector2.ZERO, visual_radius, 0.0, TAU, 32, border, 3.0)

	# Active shield ring
	if _shield_hp > 0.0 and _max_shield_hp > 0.0:
		var ratio: float = clampf(_shield_hp / _max_shield_hp, 0.0, 1.0)
		draw_arc(Vector2.ZERO, visual_radius + 5.0, -PI * 0.5, -PI * 0.5 + TAU * ratio, 32, Color(0.22, 0.75, 0.98, 0.95), 4.0)

static func _mechanic_short_label(m: int) -> String:
	match m:
		GameEnums.SpecialMechanicType.SHIELD:
			return "SHIELD"
		GameEnums.SpecialMechanicType.HARD_SHIELD:
			return "H-SHIELD"
		GameEnums.SpecialMechanicType.TURRET:
			return "TURRET"
		GameEnums.SpecialMechanicType.SPEED_ZONE:
			return "SPEED+"
		GameEnums.SpecialMechanicType.SLOW_ZONE:
			return "SLOW-"
		GameEnums.SpecialMechanicType.PROPAGANDA:
			return "BOOST"
		GameEnums.SpecialMechanicType.ADDITIONAL_FIGHTERS:
			return "+50"
		_:
			return ""
