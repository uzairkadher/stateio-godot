class_name MovementSystem
extends RefCounted
## Pure time-based waypoint movement, speed-zone evaluation, arrival flagging,
## and spatial-hash 1:1 mid-air collision resolution between opposing troop groups.

var event_bus: EventBus = null
var arrival_radius: float = 0.45
var mid_air_collision_radius: float = 0.28
var allow_mid_air_clashes: bool = true

func _init(p_event_bus: EventBus = null) -> void:
	event_bus = p_event_bus

func configure(config: Dictionary) -> void:
	var move_cfg: Dictionary = config.get("movement", {})
	arrival_radius = maxf(0.05, float(move_cfg.get("arrival_radius_units", 0.45)))
	var combat_cfg: Dictionary = config.get("combat", {})
	mid_air_collision_radius = maxf(0.05, float(combat_cfg.get("mid_air_collision_radius_units", 0.28)))
	allow_mid_air_clashes = bool(combat_cfg.get("allow_mid_air_clashes", true))

func tick(state: MatchState, dt: float, speed_modifier_fn: Callable = Callable()) -> Array:
	var arrived_groups: Array = []
	if state == null or state.is_paused or dt <= 0.0:
		return arrived_groups
	if state.phase != GameEnums.MatchPhase.PLAYING:
		return arrived_groups

	for g in state.troop_groups:
		var grp: TroopGroupState = g
		if grp.is_eliminated or grp.is_arrived or grp.amount <= 0:
			grp.is_eliminated = true
			continue

		var target: BuildingState = state.get_building(grp.target_id)
		if target == null:
			# Safe handling of invalid destination: eliminate cleanly without crashing
			grp.is_eliminated = true
			continue

		var mult: float = 1.0
		if speed_modifier_fn.is_valid():
			mult = maxf(0.15, float(speed_modifier_fn.call(state, grp)))
		grp.speed_multiplier = mult
		grp.current_speed = grp.base_speed * mult
		grp.elapsed_time += dt

		var step_dist: float = grp.current_speed * dt
		_advance_along_waypoints(grp, target.position, step_dist)

		if grp.position.distance_to(target.position) <= arrival_radius or grp.current_waypoint_index >= grp.waypoints.size():
			grp.position = target.position
			grp.is_arrived = true
			arrived_groups.append(grp)

	if allow_mid_air_clashes:
		_resolve_mid_air_collisions(state)

	return arrived_groups

func _advance_along_waypoints(grp: TroopGroupState, final_target_pos: Vector2, remaining_step: float) -> void:
	var budget: float = remaining_step
	if grp.waypoints.is_empty():
		grp.waypoints.assign([grp.position, final_target_pos])
		grp.current_waypoint_index = 1

	while budget > 0.0 and grp.current_waypoint_index < grp.waypoints.size():
		var wp: Vector2 = grp.waypoints[grp.current_waypoint_index]
		var delta: Vector2 = wp - grp.position
		var dist: float = delta.length()
		if dist <= 0.0001:
			grp.current_waypoint_index += 1
			continue
		grp.direction = delta / dist
		if budget >= dist:
			grp.position = wp
			grp.distance_traveled += dist
			budget -= dist
			grp.current_waypoint_index += 1
		else:
			grp.position += grp.direction * budget
			grp.distance_traveled += budget
			budget = 0.0

func _resolve_mid_air_collisions(state: MatchState) -> void:
	var cell_dim: float = maxf(0.25, mid_air_collision_radius * 2.0)
	var grid: Dictionary = {}  # Vector2i -> Array[TroopGroupState]
	for g in state.troop_groups:
		var grp: TroopGroupState = g
		if grp.is_eliminated or grp.is_arrived or grp.amount <= 0:
			continue
		var key := Vector2i(int(floor(grp.position.x / cell_dim)), int(floor(grp.position.y / cell_dim)))
		if not grid.has(key):
			grid[key] = []
		grid[key].append(grp)

	var r_sq: float = mid_air_collision_radius * mid_air_collision_radius
	var visited_pairs: Dictionary = {}
	for key in grid.keys():
		var bucket: Array = grid[key]
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var nkey := Vector2i(key.x + dx, key.y + dy)
				if not grid.has(nkey):
					continue
				var other_bucket: Array = grid[nkey]
				for ga in bucket:
					var a: TroopGroupState = ga
					if a.is_eliminated or a.is_arrived or a.amount <= 0:
						continue
					for gb in other_bucket:
						var b: TroopGroupState = gb
						if b.id <= a.id:
							continue
						if b.is_eliminated or b.is_arrived or b.amount <= 0:
							continue
						if a.owner_id == b.owner_id:
							continue
						var pair_key := "%d_%d" % [a.id, b.id]
						if visited_pairs.has(pair_key):
							continue
						visited_pairs[pair_key] = true
						if a.position.distance_squared_to(b.position) <= r_sq:
							var losses: int = mini(a.amount, b.amount)
							a.amount -= losses
							b.amount -= losses
							state.total_troops_lost[a.owner_id] = int(state.total_troops_lost.get(a.owner_id, 0)) + losses
							state.total_troops_lost[b.owner_id] = int(state.total_troops_lost.get(b.owner_id, 0)) + losses
							if a.amount <= 0:
								a.is_eliminated = true
							if b.amount <= 0:
								b.is_eliminated = true
							if event_bus != null:
								event_bus.emit_event("mid_air_clash", {
									"position": (a.position + b.position) * 0.5,
									"losses": losses,
									"owner_a": a.owner_id,
									"owner_b": b.owner_id,
								})
