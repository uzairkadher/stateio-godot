class_name PathCache
extends RefCounted
## Pre-baked building-to-building pathfinder using Godot 4.3 AStarGrid2D (0.5u cells).
## Pure RefCounted, zero rendering dependency, deterministic waypoint output.

var cell_size: float = 0.5
var _grid: AStarGrid2D = null
var _origin: Vector2 = Vector2.ZERO
var _grid_size: Vector2i = Vector2i(32, 32)
var _cache: Dictionary = {}  # "src_id->dst_id" -> Array[Vector2]

func build_for_buildings(buildings: Dictionary, building_order: Array[String], p_cell_size: float = 0.5) -> void:
	_cache.clear()
	cell_size = maxf(0.1, p_cell_size)
	if building_order.is_empty():
		return

	var min_x := INF
	var max_x := -INF
	var min_y := INF
	var max_y := -INF
	for bid in building_order:
		var b: BuildingState = buildings[bid]
		min_x = minf(min_x, b.position.x)
		max_x = maxf(max_x, b.position.x)
		min_y = minf(min_y, b.position.y)
		max_y = maxf(max_y, b.position.y)

	var pad: float = 2.0
	_origin = Vector2(min_x - pad, min_y - pad)
	var width_cells: int = maxi(4, int(ceil((max_x - min_x + pad * 2.0) / cell_size)) + 1)
	var height_cells: int = maxi(4, int(ceil((max_y - min_y + pad * 2.0) / cell_size)) + 1)
	_grid_size = Vector2i(width_cells, height_cells)

	_grid = AStarGrid2D.new()
	_grid.region = Rect2i(Vector2i.ZERO, _grid_size)
	_grid.cell_size = Vector2(cell_size, cell_size)
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS
	_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	_grid.update()

	# Pre-bake all directed building pairs
	for src_id in building_order:
		var src: BuildingState = buildings[src_id]
		for dst_id in building_order:
			if src_id == dst_id:
				continue
			var dst: BuildingState = buildings[dst_id]
			_cache[_pair_key(src_id, dst_id)] = _compute_route(src.position, dst.position)

func get_route(src_id: String, dst_id: String, fallback_src: Vector2, fallback_dst: Vector2) -> Array[Vector2]:
	var key := _pair_key(src_id, dst_id)
	if _cache.has(key):
		var cached: Array[Vector2] = _cache[key]
		return cached.duplicate()
	return _compute_route(fallback_src, fallback_dst)

func get_cached_pair_count() -> int:
	return _cache.size()

static func compute_route_length(points: Array[Vector2]) -> float:
	var total: float = 0.0
	for i in range(1, points.size()):
		total += points[i - 1].distance_to(points[i])
	return total

func _compute_route(from_pos: Vector2, to_pos: Vector2) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if _grid == null:
		out.append(from_pos)
		out.append(to_pos)
		return out

	var start_cell := _world_to_cell(from_pos)
	var end_cell := _world_to_cell(to_pos)
	var raw_pts: PackedVector2Array = _grid.get_point_path(start_cell, end_cell)
	if raw_pts.size() < 2:
		out.append(from_pos)
		out.append(to_pos)
		return out

	out.append(from_pos)
	# Simplify intermediate waypoints by keeping every 2nd cell converted back to world space
	for i in range(1, raw_pts.size() - 1):
		if i % 2 == 0:
			out.append(_origin + raw_pts[i])
	out.append(to_pos)
	return out

func _world_to_cell(pos: Vector2) -> Vector2i:
	var cx := clampi(int(round((pos.x - _origin.x) / cell_size)), 0, _grid_size.x - 1)
	var cy := clampi(int(round((pos.y - _origin.y) / cell_size)), 0, _grid_size.y - 1)
	return Vector2i(cx, cy)

static func _pair_key(src_id: String, dst_id: String) -> String:
	return src_id + "->" + dst_id
