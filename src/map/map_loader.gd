class_name MapLoader
extends RefCounted
## Data-driven JSON map loader and schema validator.
## Zero rendering dependencies; outputs validated map dictionaries and BuildingState instances.

const MAP_DIRECTORY := "res://data/maps"

static func list_map_paths() -> Array[String]:
	var paths: Array[String] = []
	var dir := DirAccess.open(MAP_DIRECTORY)
	if dir == null:
		return [
			"res://data/maps/stage_01_savanna_basin.json",
			"res://data/maps/stage_02_rift_highlands.json",
			"res://data/maps/stage_03_equatorial_crossroads.json",
			"res://data/maps/stage_04_cape_frontier.json",
			"res://data/maps/stage_05_iron_citadel.json",
		]
	dir.list_dir_begin()
	var fname := dir.get_next()
	while not fname.is_empty():
		if not dir.current_is_dir() and fname.ends_with(".json"):
			paths.append(MAP_DIRECTORY + "/" + fname)
		fname = dir.get_next()
	dir.list_dir_end()
	paths.sort()
	return paths

static func load_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"_error": "File not found: " + path}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {"_error": "Failed to open file: " + path}
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"_error": "Invalid JSON root object in: " + path}
	return parsed

static func load_map(path: String) -> Dictionary:
	var data := load_json_file(path)
	if data.has("_error"):
		return data
	var validation := validate_map_dict(data)
	if not validation.get("ok", false):
		return {"_error": "Map validation failed: " + ", ".join(validation.get("errors", []))}
	return data

static func validate_map_dict(data: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	for req_key in ["map_id", "display_name", "buildings", "camera"]:
		if not data.has(req_key):
			errors.append("Missing required key: " + req_key)
	var buildings_raw = data.get("buildings", [])
	if typeof(buildings_raw) != TYPE_ARRAY or buildings_raw.is_empty():
		errors.append("buildings must be a non-empty array")
	else:
		var seen_ids: Dictionary = {}
		var has_player := false
		for entry in buildings_raw:
			if typeof(entry) != TYPE_DICTIONARY:
				errors.append("Building entry must be a Dictionary")
				continue
			var bid := str(entry.get("id", ""))
			if bid.is_empty():
				errors.append("Building missing id")
			elif seen_ids.has(bid):
				errors.append("Duplicate building id: " + bid)
			seen_ids[bid] = true
			if int(entry.get("owner_id", 0)) == GameEnums.OwnerId.PLAYER:
				has_player = true
			if int(entry.get("initial_population", 0)) < 0:
				errors.append("Negative initial_population on " + bid)
		if not has_player:
			errors.append("Map must contain at least one player-owned starting building")
	return {"ok": errors.is_empty(), "errors": errors}

static func build_states_from_map(map_data: Dictionary, default_hard_cap: int = 999) -> Array[BuildingState]:
	var out: Array[BuildingState] = []
	for entry in map_data.get("buildings", []):
		var b := BuildingState.from_map_dict(entry, default_hard_cap)
		out.append(b)
	return out

static func compute_world_bounds_rect(map_data: Dictionary) -> Rect2:
	var ppu: float = float(map_data.get("pixels_per_unit", 100.0))
	var cam: Dictionary = map_data.get("camera", {})
	var bounds: Dictionary = cam.get("bounds", {})
	var min_x: float = float(bounds.get("min_x", -8.0)) * ppu
	var max_x: float = float(bounds.get("max_x", 8.0)) * ppu
	var min_y: float = float(bounds.get("min_y", -8.0)) * ppu
	var max_y: float = float(bounds.get("max_y", 8.0)) * ppu
	return Rect2(Vector2(min_x, min_y), Vector2(maxf(100.0, max_x - min_x), maxf(100.0, max_y - min_y)))
