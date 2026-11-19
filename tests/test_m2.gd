extends RefCounted
## Milestone 2 core-loop tests: territory capture, unit spawn, unit move (+ state tick).
##
## The implementation is load()ed at runtime (not preload()ed) on purpose: if a file
## is missing or broken this suite records a FAILURE instead of failing to compile.
## Every test must also run to completion; a test that aborts on a runtime error
## (e.g. a missing method) is reported as a failure too, so stubs cannot pass.

const TERRITORY_PATH := "res://src/logic/territory.gd"
const UNITS_PATH := "res://src/logic/units.gd"
const STATE_PATH := "res://src/core/state.gd"

# Mirrors CoreEnums.FactionId (src/core/enums.gd); kept literal so this file has no deps.
const NEUTRAL: int = 0
const PLAYER: int = 1
const BOT_1: int = 2

const ALL_TESTS: Array[String] = ["test_capture", "test_spawn", "test_move", "test_state_tick"]

var passed: int = 0
var failed: int = 0
var failures: Array[String] = []
var _completed: Array[String] = []

func _assert_true(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		failures.append(msg)
		push_error("FAIL: " + msg)

func run_all() -> Dictionary:
	test_capture()
	test_spawn()
	test_move()
	test_state_tick()
	for test_name in ALL_TESTS:
		_assert_true(_completed.has(test_name), "%s did not run to completion (missing or broken implementation)" % test_name)
	return {"passed": passed, "failed": failed, "failures": failures}

func _new_instance(path: String, label: String) -> Object:
	var script = load(path)
	if script == null or not script.can_instantiate():
		_assert_true(false, "%s could not be loaded from %s" % [label, path])
		return null
	return script.new()

func _has_methods(obj: Object, label: String, methods: Array) -> bool:
	var ok: bool = true
	for m in methods:
		if not obj.has_method(m):
			_assert_true(false, "%s is missing method %s()" % [label, m])
			ok = false
	return ok

func test_capture() -> void:
	var t = _new_instance(TERRITORY_PATH, "Territory")
	if t == null or not _has_methods(t, "Territory", ["capture", "get_owner", "get_color"]):
		return
	var cell := Vector2i(3, 4)
	_assert_true(t.get_owner(cell) == NEUTRAL, "a fresh cell must be neutral")
	t.capture(cell, PLAYER)
	_assert_true(t.get_owner(cell) == PLAYER, "capture(cell, PLAYER) must make PLAYER the owner")
	_assert_true(t.get_owner(Vector2i(4, 3)) == NEUTRAL, "capturing one cell must not change its neighbours")
	t.capture(cell, BOT_1)
	_assert_true(t.get_owner(cell) == BOT_1, "capturing an owned cell must transfer ownership")
	t.capture(Vector2i(10, 10), PLAYER)
	_assert_true(t.get_owner(Vector2i(10, 10)) != PLAYER, "off-grid capture must be ignored")
	_assert_true(t.get_owner(Vector2i(9, 9)) == NEUTRAL, "last in-bounds cell (9,9) must exist and be neutral")
	_assert_true(t.get_color(PLAYER) != t.get_color(NEUTRAL), "player and neutral colors must differ")
	_assert_true(t.get_color(PLAYER) != t.get_color(BOT_1), "player and bot colors must differ")
	_assert_true(t.grid.size() == 100, "grid must be 10x10 = 100 cells")
	_completed.append("test_capture")

func test_spawn() -> void:
	var u = _new_instance(UNITS_PATH, "Units")
	if u == null or not _has_methods(u, "Units", ["spawn", "move_to", "tick"]):
		return
	var unit = u.spawn(Vector2i(2, 5), PLAYER)
	_assert_true(unit != null, "spawn() must return the new unit")
	if unit != null:
		_assert_true(unit.pos == Vector2i(2, 5), "spawned unit must be at the requested cell")
		_assert_true(unit.owner == PLAYER, "spawned unit must belong to the requested owner")
		_assert_true(unit.hp > 0, "spawned unit must start with positive hp")
	_assert_true(u.list.size() == 1, "one spawn must leave exactly one unit")
	var second = u.spawn(Vector2i(7, 7), BOT_1)
	_assert_true(second != null and second.owner == BOT_1, "a second spawn must keep its own owner")
	_assert_true(u.list.size() == 2, "two spawns must leave exactly two units")
	var bad = u.spawn(Vector2i(-1, 3), PLAYER)
	_assert_true(bad == null, "spawning off-grid must return null")
	_assert_true(u.list.size() == 2, "a rejected spawn must not add a unit")
	_completed.append("test_spawn")

func test_move() -> void:
	var u = _new_instance(UNITS_PATH, "Units")
	if u == null or not _has_methods(u, "Units", ["spawn", "move_to", "tick"]):
		return
	var unit = u.spawn(Vector2i(0, 0), PLAYER)
	if unit == null:
		_assert_true(false, "move test needs spawn() to return a unit")
		return
	var target := Vector2i(3, 2)
	_assert_true(u.move_to(unit, target) == true, "move_to a valid cell must be accepted")
	_assert_true(unit.pos == Vector2i(0, 0), "move_to alone must not teleport the unit")
	u.tick()
	_assert_true(unit.pos == Vector2i(1, 0), "one tick must move the unit exactly one cell toward the target")
	for i in range(4):
		u.tick()
	_assert_true(unit.pos == target, "unit must reach (3,2) after 5 ticks (Manhattan distance 5)")
	u.tick()
	_assert_true(unit.pos == target, "unit must stay put once it has arrived")
	_assert_true(u.move_to(unit, Vector2i(10, 0)) == false, "move_to an off-grid cell must be rejected")
	u.tick()
	_assert_true(unit.pos == target, "a rejected order must not move the unit")
	_completed.append("test_move")

func test_state_tick() -> void:
	var s = _new_instance(STATE_PATH, "State")
	if s == null or not _has_methods(s, "State", ["spawn_unit", "tick"]):
		return
	if s.get("territories") == null or s.get("units") == null:
		_assert_true(false, "State must expose territories and units")
		return
	var unit = s.spawn_unit(Vector2i(0, 0), PLAYER)
	if unit == null:
		_assert_true(false, "state test needs spawn_unit() to return a unit")
		return
	_assert_true(s.territories.get_owner(Vector2i(0, 0)) == PLAYER, "spawning must claim the starting cell")
	s.units.move_to(unit, Vector2i(2, 0))
	s.tick()
	_assert_true(s.territories.get_owner(Vector2i(1, 0)) == PLAYER, "tick must claim the cell the unit moved onto")
	_assert_true(s.territories.get_owner(Vector2i(2, 0)) == NEUTRAL, "tick must not claim cells the unit has not reached")
	s.tick()
	_assert_true(s.territories.get_owner(Vector2i(2, 0)) == PLAYER, "second tick must claim the destination cell")
	_assert_true(s.territories.get_owner(Vector2i(5, 5)) == NEUTRAL, "untouched cells must stay neutral")
	_assert_true(s.tick_count == 2, "tick_count must equal the number of ticks run")
	_completed.append("test_state_tick")
