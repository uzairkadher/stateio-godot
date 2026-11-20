class_name InputController
extends Node2D
## Handles mobile tap source -> tap destination, drag-to-send, multi-select, and cancel.
## Emits unified SendCommand structs via on_command_ready callback.

var pixels_per_unit: float = 100.0
var touch_radius_px: float = 52.0
var send_ratio: float = 1.0
var on_command_ready: Callable = Callable()
var on_selection_changed: Callable = Callable()

var _snapshot: SimSnapshot = null
var _selected_sources: Array[String] = []
var _is_dragging: bool = false
var _drag_world_pos: Vector2 = Vector2.ZERO
var _hovered_target_id: String = ""
var _cmd_counter: int = 1

func update_snapshot(snapshot: SimSnapshot, ppu: float = 100.0) -> void:
	_snapshot = snapshot
	pixels_per_unit = ppu
	# Drop any selected building no longer owned by the player
	for i in range(_selected_sources.size() - 1, -1, -1):
		var bid: String = _selected_sources[i]
		if not _snapshot.buildings.has(bid) or int(_snapshot.buildings[bid]["owner_id"]) != GameEnums.OwnerId.PLAYER:
			_selected_sources.remove_at(i)
	queue_redraw()

func clear_selection() -> void:
	_selected_sources.clear()
	_is_dragging = false
	_hovered_target_id = ""
	if on_selection_changed.is_valid():
		on_selection_changed.call(_selected_sources, _hovered_target_id)
	queue_redraw()

func get_selected_sources() -> Array[String]:
	return _selected_sources.duplicate()

func _unhandled_input(event: InputEvent) -> void:
	if _snapshot == null or _snapshot.phase != GameEnums.MatchPhase.PLAYING or _snapshot.is_paused:
		return

	if event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event
		var world_pos := get_global_mouse_position()
		if st.pressed:
			_handle_press(world_pos)
		else:
			_handle_release(world_pos)
	elif event is InputEventScreenDrag:
		_handle_drag(get_global_mouse_position())
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT:
			var world_pos := get_global_mouse_position()
			if mb.pressed:
				_handle_press(world_pos)
			else:
				_handle_release(world_pos)
	elif event is InputEventMouseMotion and _is_dragging:
		_handle_drag(get_global_mouse_position())

func _handle_press(world_pos: Vector2) -> void:
	var hit_id: String = _pick_building_at(world_pos)
	if hit_id.is_empty():
		clear_selection()
		return

	var b: Dictionary = _snapshot.buildings[hit_id]
	var owner_id: int = int(b["owner_id"])

	# Tap-to-send if we already had selected source(s) and tapped a different building
	if not _selected_sources.is_empty() and not _selected_sources.has(hit_id):
		_dispatch_send(hit_id)
		clear_selection()
		return

	if owner_id == GameEnums.OwnerId.PLAYER:
		if not _selected_sources.has(hit_id):
			_selected_sources.append(hit_id)
		_is_dragging = true
		_drag_world_pos = world_pos
		_hovered_target_id = ""
		if on_selection_changed.is_valid():
			on_selection_changed.call(_selected_sources, _hovered_target_id)
		queue_redraw()
	else:
		clear_selection()

func _handle_drag(world_pos: Vector2) -> void:
	if not _is_dragging or _selected_sources.is_empty():
		return
	_drag_world_pos = world_pos
	var hit_id: String = _pick_building_at(world_pos)
	_hovered_target_id = ""
	if not hit_id.is_empty():
		var b: Dictionary = _snapshot.buildings[hit_id]
		if int(b["owner_id"]) == GameEnums.OwnerId.PLAYER and not _selected_sources.has(hit_id):
			_selected_sources.append(hit_id)
		elif not _selected_sources.has(hit_id):
			_hovered_target_id = hit_id
	if on_selection_changed.is_valid():
		on_selection_changed.call(_selected_sources, _hovered_target_id)
	queue_redraw()

func _handle_release(world_pos: Vector2) -> void:
	if not _is_dragging:
		return
	_is_dragging = false
	var hit_id: String = _pick_building_at(world_pos)
	if not hit_id.is_empty() and not _selected_sources.has(hit_id):
		_dispatch_send(hit_id)
		clear_selection()
	else:
		queue_redraw()

func _dispatch_send(target_id: String) -> void:
	if _selected_sources.is_empty() or target_id.is_empty():
		return
	var cmd_id := "player_%d" % _cmd_counter
	_cmd_counter += 1
	var cmd := SendCommand.new(
		GameEnums.OwnerId.PLAYER,
		_selected_sources,
		target_id,
		send_ratio,
		cmd_id,
		_snapshot.elapsed_time
	)
	if on_command_ready.is_valid():
		on_command_ready.call(cmd)

func _pick_building_at(world_pos: Vector2) -> String:
	if _snapshot == null:
		return ""
	var best_id: String = ""
	var best_dist: float = touch_radius_px
	for bid in _snapshot.building_order:
		var b: Dictionary = _snapshot.buildings[bid]
		var b_pos: Vector2 = b["position"] * pixels_per_unit
		var d: float = world_pos.distance_to(b_pos)
		if d <= best_dist:
			best_dist = d
			best_id = bid
	return best_id

func _draw() -> void:
	if not _is_dragging or _snapshot == null or _selected_sources.is_empty():
		return
	var target_pos: Vector2 = _drag_world_pos
	if not _hovered_target_id.is_empty() and _snapshot.buildings.has(_hovered_target_id):
		target_pos = _snapshot.buildings[_hovered_target_id]["position"] * pixels_per_unit
	for sid in _selected_sources:
		if not _snapshot.buildings.has(sid):
			continue
		var s_pos: Vector2 = _snapshot.buildings[sid]["position"] * pixels_per_unit
		draw_line(s_pos, target_pos, Color(1.0, 0.92, 0.35, 0.85), 5.0)
