extends Node2D
## Milestone 2 core loop view: draws the 10x10 grid, tap/click captures a cell
## for the player, and a demo bot unit walks around painting cells as it goes.

const Enums = preload("res://src/core/enums.gd")
const StateScript = preload("res://src/core/state.gd")
const TerritoryScript = preload("res://src/logic/territory.gd")

const CELL_SIZE: float = 100.0
const CELL_GAP: float = 4.0
const TICK_SECONDS: float = 0.5

@onready var hud_label: Label = $Hud/Label

var state: StateScript
var _bot_unit = null
var _tick_accum: float = 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	state = StateScript.new()
	_bot_unit = state.spawn_unit(Vector2i(TerritoryScript.SIZE - 1, TerritoryScript.SIZE - 1), Enums.FactionId.BOT_1)
	state.units.move_to(_bot_unit, Vector2i(0, 0))
	get_viewport().size_changed.connect(queue_redraw)
	_refresh()

func _process(delta: float) -> void:
	_tick_accum += delta
	var stepped: bool = false
	while _tick_accum >= TICK_SECONDS:
		_tick_accum -= TICK_SECONDS
		state.tick()
		stepped = true
		if _bot_unit != null and not _bot_unit.has_target:
			var next := Vector2i(
				_rng.randi_range(0, TerritoryScript.SIZE - 1),
				_rng.randi_range(0, TerritoryScript.SIZE - 1))
			state.units.move_to(_bot_unit, next)
	if stepped:
		_refresh()

func _unhandled_input(event: InputEvent) -> void:
	# Touch is emulated as left mouse button, so this covers desktop and Android taps.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell := _cell_at(get_local_mouse_position())
		if TerritoryScript.is_in_bounds(cell):
			state.territories.capture(cell, Enums.FactionId.PLAYER)
			_refresh()

func _grid_origin() -> Vector2:
	var grid_px := CELL_SIZE * TerritoryScript.SIZE
	var view := get_viewport_rect().size
	return Vector2((view.x - grid_px) * 0.5, (view.y - grid_px) * 0.5)

func _cell_at(local_pos: Vector2) -> Vector2i:
	var rel := local_pos - _grid_origin()
	return Vector2i(floori(rel.x / CELL_SIZE), floori(rel.y / CELL_SIZE))

func _refresh() -> void:
	hud_label.text = "Tick %d   You: %d   Bot: %d\nTap a cell to capture it" % [
		state.tick_count,
		state.territories.count_owned(Enums.FactionId.PLAYER),
		state.territories.count_owned(Enums.FactionId.BOT_1),
	]
	queue_redraw()

func _draw() -> void:
	var origin := _grid_origin()
	var cell_vec := Vector2(CELL_SIZE, CELL_SIZE)
	for y in range(TerritoryScript.SIZE):
		for x in range(TerritoryScript.SIZE):
			var cell := Vector2i(x, y)
			var rect := Rect2(origin + Vector2(x, y) * CELL_SIZE, cell_vec).grow(-CELL_GAP * 0.5)
			var color := state.territories.get_color(state.territories.get_owner(cell))
			draw_rect(rect, color, true)
	for unit in state.units.list:
		var center: Vector2 = origin + (Vector2(unit.pos) + Vector2(0.5, 0.5)) * CELL_SIZE
		draw_circle(center, CELL_SIZE * 0.28, Color.WHITE)
		draw_circle(center, CELL_SIZE * 0.20, state.territories.get_color(unit.owner))
