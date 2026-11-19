extends RefCounted
## Milestone 2 unit system: spawn units on the grid and step them toward targets.
## Pure RefCounted (no Nodes) so it runs in the headless test runner.

const TerritoryScript = preload("res://src/logic/territory.gd")

const DEFAULT_HP: int = 10

class Unit extends RefCounted:
	var pos: Vector2i = Vector2i.ZERO
	var owner: int = 0
	var hp: int = 10
	var target: Vector2i = Vector2i.ZERO
	var has_target: bool = false

	func _init(p_pos: Vector2i, p_owner: int, p_hp: int = 10) -> void:
		pos = p_pos
		owner = p_owner
		hp = p_hp

## All live units, in spawn order.
var list: Array = []

## Creates a unit at pos. Returns null (and spawns nothing) if pos is off-grid.
func spawn(pos: Vector2i, owner: int) -> Unit:
	if not TerritoryScript.is_in_bounds(pos):
		return null
	var unit := Unit.new(pos, owner, DEFAULT_HP)
	list.append(unit)
	return unit

## Orders the unit to walk to target, one cell per tick(). Returns false if the
## unit is unknown/null or the target is off-grid (the old order is kept).
func move_to(unit: Unit, target: Vector2i) -> bool:
	if unit == null or not list.has(unit):
		return false
	if not TerritoryScript.is_in_bounds(target):
		return false
	unit.target = target
	unit.has_target = unit.pos != target
	return true

## Advances every unit with an order by one cell (x axis first, then y).
func tick() -> void:
	for unit in list:
		if not unit.has_target:
			continue
		var dx: int = signi(unit.target.x - unit.pos.x)
		var dy: int = signi(unit.target.y - unit.pos.y)
		if dx != 0:
			unit.pos.x += dx
		elif dy != 0:
			unit.pos.y += dy
		if unit.pos == unit.target:
			unit.has_target = false
