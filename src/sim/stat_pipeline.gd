class_name StatPipeline
extends RefCounted
## Evaluates additive and multiplicative stat modifiers per entity and stat type.
## Supports SUM, MULTIPLY_BASE, and MULTIPLY_CUMULATIVE operations.

# entity_id -> { stat_type -> Array[Dictionary{source_id, op, value}] }
var _modifiers: Dictionary = {}

func add_modifier(entity_id: String, stat_type: int, source_id: String, operation: int, value: float) -> void:
	if not _modifiers.has(entity_id):
		_modifiers[entity_id] = {}
	var by_stat: Dictionary = _modifiers[entity_id]
	if not by_stat.has(stat_type):
		by_stat[stat_type] = []
	var list: Array = by_stat[stat_type]
	# Replace existing modifier from the same source_id to prevent accidental double-stacking
	for i in range(list.size() - 1, -1, -1):
		if str(list[i].get("source_id", "")) == source_id:
			list.remove_at(i)
	list.append({
		"source_id": source_id,
		"op": operation,
		"value": value,
	})

func remove_modifier(entity_id: String, stat_type: int, source_id: String) -> void:
	if not _modifiers.has(entity_id):
		return
	var by_stat: Dictionary = _modifiers[entity_id]
	if not by_stat.has(stat_type):
		return
	var list: Array = by_stat[stat_type]
	for i in range(list.size() - 1, -1, -1):
		if str(list[i].get("source_id", "")) == source_id:
			list.remove_at(i)

func remove_all_from_source(source_id: String) -> void:
	for entity_id in _modifiers.keys():
		var by_stat: Dictionary = _modifiers[entity_id]
		for stat_type in by_stat.keys():
			var list: Array = by_stat[stat_type]
			for i in range(list.size() - 1, -1, -1):
				if str(list[i].get("source_id", "")) == source_id:
					list.remove_at(i)

func evaluate(entity_id: String, stat_type: int, base_value: float) -> float:
	if not _modifiers.has(entity_id):
		return base_value
	var by_stat: Dictionary = _modifiers[entity_id]
	if not by_stat.has(stat_type):
		return base_value
	var list: Array = by_stat[stat_type]
	var sum_bonus: float = 0.0
	var mult_base_bonus: float = 0.0
	var mult_cum: float = 1.0
	for mod in list:
		var op: int = int(mod.get("op", GameEnums.StatOperation.SUM))
		var val: float = float(mod.get("value", 0.0))
		match op:
			GameEnums.StatOperation.SUM:
				sum_bonus += val
			GameEnums.StatOperation.MULTIPLY_BASE:
				mult_base_bonus += val
			GameEnums.StatOperation.MULTIPLY_CUMULATIVE:
				mult_cum *= (1.0 + val)
	var result: float = (base_value * (1.0 + mult_base_bonus) + sum_bonus) * mult_cum
	return maxf(0.0, result)

func clear() -> void:
	_modifiers.clear()
