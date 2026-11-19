class_name ConfigLoader
extends RefCounted
## Loads and validates tunable gameplay JSON configs without Node dependencies.

const DEFAULT_CONFIG_PATH := "res://data/gameplay_config.json"

static func load_json_dict(path: String = DEFAULT_CONFIG_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

static func validate_gameplay_config(cfg: Dictionary) -> bool:
	var required_sections := ["simulation", "population", "sending", "movement", "combat", "map_scale"]
	for sec in required_sections:
		if not cfg.has(sec) or typeof(cfg[sec]) != TYPE_DICTIONARY:
			return false
	return true
