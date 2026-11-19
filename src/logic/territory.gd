extends RefCounted
## Milestone 2 territory grid: a 10x10 board mapping cell -> owning player id.
## Pure RefCounted (no Nodes) so it runs in the headless test runner.

const Enums = preload("res://src/core/enums.gd")

const SIZE: int = 10
const INVALID_OWNER: int = -1  # returned by get_owner() for off-grid cells

const FALLBACK_COLOR := Color(0.5, 0.5, 0.5)
const COLORS := {
	Enums.FactionId.NEUTRAL: Color(0.20, 0.24, 0.31),
	Enums.FactionId.PLAYER: Color(0.23, 0.51, 0.96),
	Enums.FactionId.BOT_1: Color(0.94, 0.27, 0.27),
	Enums.FactionId.BOT_2: Color(0.96, 0.62, 0.04),
	Enums.FactionId.BOT_3: Color(0.13, 0.77, 0.37),
	Enums.FactionId.BOT_4: Color(0.66, 0.33, 0.97),
	Enums.FactionId.BOT_5: Color(0.93, 0.28, 0.60),
	Enums.FactionId.BOT_6: Color(0.08, 0.72, 0.65),
	Enums.FactionId.BOT_7: Color(0.52, 0.80, 0.09),
}

## Vector2i cell -> int player id. Every in-bounds cell always has an entry.
var grid: Dictionary = {}

func _init() -> void:
	reset()

func reset() -> void:
	grid.clear()
	for y in range(SIZE):
		for x in range(SIZE):
			grid[Vector2i(x, y)] = Enums.FactionId.NEUTRAL

static func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < SIZE and pos.y < SIZE

## Gives the cell to player_id. Returns false (and changes nothing) if off-grid.
func capture(pos: Vector2i, player_id: int) -> bool:
	if not is_in_bounds(pos):
		return false
	grid[pos] = player_id
	return true

## Owner of the cell, NEUTRAL (0) if unowned, INVALID_OWNER (-1) if off-grid.
func get_owner(pos: Vector2i) -> int:
	if not is_in_bounds(pos):
		return INVALID_OWNER
	return grid[pos]

func get_color(player_id: int) -> Color:
	var c: Color = COLORS.get(player_id, FALLBACK_COLOR)
	return c

func count_owned(player_id: int) -> int:
	var n: int = 0
	for pos in grid:
		if grid[pos] == player_id:
			n += 1
	return n
