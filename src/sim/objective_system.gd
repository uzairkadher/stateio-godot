class_name ObjectiveSystem
extends RefCounted
## Evaluates win/lose/draw conditions for SKIRMISH (and extensible objective types).
## Checks both owned buildings and active in-flight troop groups so last-second captures resolve fairly.

func evaluate(state: MatchState) -> Dictionary:
	if state == null or state.phase != GameEnums.MatchPhase.PLAYING:
		return {"outcome": GameEnums.MatchOutcome.NONE, "winner": GameEnums.OwnerId.NEUTRAL}

	var alive_factions: Array[int] = []
	for owner_id in state.active_factions:
		if owner_id == GameEnums.OwnerId.NEUTRAL:
			continue
		var has_buildings: bool = state.get_owner_building_count(owner_id) > 0
		var has_troops: bool = state.get_owner_total_population(owner_id) > 0
		if has_buildings or has_troops:
			alive_factions.append(owner_id)

	var player_alive: bool = alive_factions.has(GameEnums.OwnerId.PLAYER)
	if not player_alive:
		var winner: int = alive_factions[0] if alive_factions.size() == 1 else GameEnums.OwnerId.NEUTRAL
		return {"outcome": GameEnums.MatchOutcome.LOSE, "winner": winner}

	if alive_factions.size() == 1 and player_alive:
		return {"outcome": GameEnums.MatchOutcome.WIN, "winner": GameEnums.OwnerId.PLAYER}

	if alive_factions.is_empty():
		return {"outcome": GameEnums.MatchOutcome.DRAW, "winner": GameEnums.OwnerId.NEUTRAL}

	return {"outcome": GameEnums.MatchOutcome.NONE, "winner": GameEnums.OwnerId.NEUTRAL}
