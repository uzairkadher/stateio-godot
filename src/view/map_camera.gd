class_name MapCamera
extends Camera2D
## Mobile & desktop Camera2D with pan, pinch/wheel zoom, and strict map bounds clamping.

var world_bounds: Rect2 = Rect2(-800, -800, 1600, 1600)
var min_zoom: float = 0.65
var max_zoom: float = 1.85
var _panning: bool = false
var _last_pan_pos: Vector2 = Vector2.ZERO

func configure_from_map(map_data: Dictionary) -> void:
	world_bounds = MapLoader.compute_world_bounds_rect(map_data)
	var cam_cfg: Dictionary = map_data.get("camera", {})
	min_zoom = maxf(0.3, float(cam_cfg.get("min_zoom", 0.65)))
	max_zoom = maxf(min_zoom, float(cam_cfg.get("max_zoom", 1.85)))
	var def_zoom: float = clampf(float(cam_cfg.get("default_zoom", 1.0)), min_zoom, max_zoom)
	zoom = Vector2(def_zoom, def_zoom)
	position = world_bounds.get_center()
	_clamp_position()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_apply_zoom(1.1)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_apply_zoom(0.9)
		elif mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = mb.pressed
			_last_pan_pos = mb.position
	elif event is InputEventMouseMotion and _panning:
		var mm: InputEventMouseMotion = event
		var delta: Vector2 = (mm.position - _last_pan_pos) / zoom
		_last_pan_pos = mm.position
		position -= delta
		_clamp_position()
	elif event is InputEventMagnifyGesture:
		var mg: InputEventMagnifyGesture = event
		_apply_zoom(mg.factor)

func _apply_zoom(factor: float) -> void:
	var next_z: float = clampf(zoom.x * factor, min_zoom, max_zoom)
	zoom = Vector2(next_z, next_z)
	_clamp_position()

func _clamp_position() -> void:
	position.x = clampf(position.x, world_bounds.position.x, world_bounds.position.x + world_bounds.size.x)
	position.y = clampf(position.y, world_bounds.position.y, world_bounds.position.y + world_bounds.size.y)
