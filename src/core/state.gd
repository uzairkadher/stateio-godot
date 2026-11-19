extends RefCounted
## Milestone 2 aggregate world state: the territory grid plus all units.
## tick() advances the whole simulation by one step.
## Pure RefCounted (no Nodes) so it runs in the headless test runner.

const TerritoryScript = preload("res://src/logic/territory.gd")
const UnitsScript = preload("res://src/logic/units.gd")

var territories: TerritoryScript = TerritoryScript.new()
var units: UnitsScript = UnitsScript.new()
var tick_count: int = 0

## Spawns a unit and claims its starting cell. Returns null if pos is off-grid.
func spawn_unit(pos: Vector2i, owner: int) -> RefCounted:
	var unit = units.spawn(pos, owner)
	if unit != null:
		territories.capture(pos, owner)
	return unit

## One simulation step: move every unit, then each unit claims the cell it stands on.
func tick() -> void:
	units.tick()
	for unit in units.list:
		territories.capture(unit.pos, unit.owner)
	tick_count += 1
