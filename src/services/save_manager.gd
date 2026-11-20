class_name SaveManager
extends RefCounted
## Atomic JSON persistence for settings, stage progression, statistics, and match history.

const DEFAULT_SAVE_PATH := "user://save_v1.json"

var save_path: String = DEFAULT_SAVE_PATH
var data: Dictionary = {}

func _init(p_path: String = DEFAULT_SAVE_PATH) -> void:
	save_path = p_path
	data = _default_data()

static func _default_data() -> Dictionary:
	return {
		"schema_version": 1,
		"settings": {
			"music_enabled": true,
			"sfx_enabled": true,
			"music_volume": 0.6,
			"sfx_volume": 0.85,
			"vibration_enabled": true,
			"safe_area_margin": 48,
			"language": "en",
		},
		"progression": {
			"unlocked_stage": 1,
			"completed_maps": [],
			"best_times": {},
		},
		"stats": {
			"matches_played": 0,
			"wins": 0,
			"losses": 0,
			"total_captures": 0,
		},
		"match_history": [],
	}

func load_save() -> Dictionary:
	if not FileAccess.file_exists(save_path):
		data = _default_data()
		return data
	var f := FileAccess.open(save_path, FileAccess.READ)
	if f == null:
		data = _default_data()
		return data
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		data = _default_data()
		return data
	data = _merge_defaults(_default_data(), parsed)
	return data

func save() -> bool:
	var tmp_path := save_path + ".tmp"
	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "	") + "
")
	f.flush()
	f.close()
	var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp_path), ProjectSettings.globalize_path(save_path))
	if err != OK:
		var direct := FileAccess.open(save_path, FileAccess.WRITE)
		if direct == null:
			return false
		direct.store_string(JSON.stringify(data, "	") + "
")
		direct.close()
	return true

func get_setting(key: String, fallback = null):
	var s: Dictionary = data.get("settings", {})
	return s.get(key, fallback)

func set_setting(key: String, value) -> void:
	if not data.has("settings"):
		data["settings"] = {}
	data["settings"][key] = value
	save()

func record_match_result(map_id: String, stage_number: int, won: bool, elapsed_sec: float, captures: int) -> void:
	var stats: Dictionary = data["stats"]
	stats["matches_played"] = int(stats.get("matches_played", 0)) + 1
	stats["total_captures"] = int(stats.get("total_captures", 0)) + maxi(0, captures)
	if won:
		stats["wins"] = int(stats.get("wins", 0)) + 1
		var prog: Dictionary = data["progression"]
		prog["unlocked_stage"] = maxi(int(prog.get("unlocked_stage", 1)), stage_number + 1)
		var completed: Array = prog.get("completed_maps", [])
		if not completed.has(map_id):
			completed.append(map_id)
		prog["completed_maps"] = completed
		var best: Dictionary = prog.get("best_times", {})
		if not best.has(map_id) or elapsed_sec < float(best[map_id]):
			best[map_id] = snappedf(elapsed_sec, 0.1)
		prog["best_times"] = best
	else:
		stats["losses"] = int(stats.get("losses", 0)) + 1

	var history: Array = data.get("match_history", [])
	history.push_front({
		"map_id": map_id,
		"won": won,
		"duration_sec": snappedf(elapsed_sec, 0.1),
		"captures": captures,
	})
	if history.size() > 25:
		history.resize(25)
	data["match_history"] = history
	save()

func _merge_defaults(defaults: Dictionary, loaded: Dictionary) -> Dictionary:
	var out := defaults.duplicate(true)
	for k in loaded.keys():
		if out.has(k) and typeof(out[k]) == TYPE_DICTIONARY and typeof(loaded[k]) == TYPE_DICTIONARY:
			out[k] = _merge_defaults(out[k], loaded[k])
		else:
			out[k] = loaded[k]
	return out
