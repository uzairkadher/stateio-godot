class_name BotConfig
extends RefCounted
## Holds difficulty parameters for a BotController preset (Easy / Normal / Hard).

var difficulty_key: String = "normal"
var display_name: String = "Normal"
var decision_interval_sec: float = 0.80
var reaction_delay_sec: float = 0.60
var command_cooldown_sec: float = 0.70
var min_attack_surplus: int = 4
var min_garrison_keep: int = 4
var send_ratio_attack: float = 0.75
var send_ratio_defend: float = 0.75
var send_ratio_expand: float = 0.65
var aggression_weight: float = 1.05
var defense_weight: float = 1.35
var expand_weight: float = 1.25
var reinforce_weight: float = 0.85
var idle_timeout_sec: float = 4.5
var max_commands_per_tick: int = 2

static func from_dict(key: String, d: Dictionary) -> BotConfig:
	var cfg := BotConfig.new()
	cfg.difficulty_key = key
	cfg.display_name = str(d.get("display_name", key.capitalize()))
	cfg.decision_interval_sec = maxf(0.15, float(d.get("decision_interval_sec", 0.80)))
	cfg.reaction_delay_sec = maxf(0.10, float(d.get("reaction_delay_sec", 0.60)))
	cfg.command_cooldown_sec = maxf(0.15, float(d.get("command_cooldown_sec", 0.70)))
	cfg.min_attack_surplus = maxi(1, int(d.get("min_attack_surplus", 4)))
	cfg.min_garrison_keep = maxi(0, int(d.get("min_garrison_keep", 4)))
	cfg.send_ratio_attack = clampf(float(d.get("send_ratio_attack", 0.75)), 0.25, 1.0)
	cfg.send_ratio_defend = clampf(float(d.get("send_ratio_defend", 0.75)), 0.25, 1.0)
	cfg.send_ratio_expand = clampf(float(d.get("send_ratio_expand", 0.65)), 0.25, 1.0)
	cfg.aggression_weight = maxf(0.1, float(d.get("aggression_weight", 1.05)))
	cfg.defense_weight = maxf(0.1, float(d.get("defense_weight", 1.35)))
	cfg.expand_weight = maxf(0.1, float(d.get("expand_weight", 1.25)))
	cfg.reinforce_weight = maxf(0.1, float(d.get("reinforce_weight", 0.85)))
	cfg.idle_timeout_sec = maxf(1.5, float(d.get("idle_timeout_sec", 4.5)))
	cfg.max_commands_per_tick = maxi(1, int(d.get("max_commands_per_tick", 2)))
	return cfg

static func load_preset(presets_json: Dictionary, difficulty: String) -> BotConfig:
	var presets: Dictionary = presets_json.get("presets", {})
	var key: String = difficulty.to_lower()
	if not presets.has(key):
		key = "normal"
	return from_dict(key, presets.get(key, {}))
