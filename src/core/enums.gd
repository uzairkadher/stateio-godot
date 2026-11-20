class_name GameEnums
extends RefCounted
## Core enumerations shared across simulation, AI, maps, presentation, and UI.
## Zero Node or rendering dependencies.

enum OwnerId {
	NEUTRAL = 0,
	PLAYER = 1,
	BOT_1 = 2,
	BOT_2 = 3,
	BOT_3 = 4,
	BOT_4 = 5,
	BOT_5 = 6,
	BOT_6 = 7,
	BOT_7 = 8,
}

enum MatchPhase {
	MENU = 0,
	MAP_SELECT = 1,
	PRE_START = 2,
	PLAYING = 3,
	PAUSED = 4,
	ENDED = 5,
}

enum MatchOutcome {
	NONE = 0,
	WIN = 1,
	LOSE = 2,
	DRAW = 3,
}

enum ObjectiveType {
	SKIRMISH = 10,
	DOMINATION = 40,
	CAPITAL = 50,
}

enum StatType {
	POPULATION_CAP = 10,
	START_POPULATION = 11,
	SPAWN_RATE = 12,
	MOVEMENT_SPEED = 14,
}

enum StatOperation {
	SUM = 10,
	MULTIPLY_BASE = 20,
	MULTIPLY_CUMULATIVE = 40,
}

enum SpecialMechanicType {
	NONE = 0,
	SHIELD = 10,
	HARD_SHIELD = 11,
	TURRET = 20,
	SPEED_ZONE = 30,
	SLOW_ZONE = 31,
	PROPAGANDA = 40,
	ADDITIONAL_FIGHTERS = 50,
	REINFORCEMENT = 60,
}

static func mechanic_from_string(name_str: String) -> int:
	match name_str.to_lower().strip_edges():
		"shield":
			return SpecialMechanicType.SHIELD
		"hard_shield":
			return SpecialMechanicType.HARD_SHIELD
		"turret":
			return SpecialMechanicType.TURRET
		"speed_zone":
			return SpecialMechanicType.SPEED_ZONE
		"slow_zone":
			return SpecialMechanicType.SLOW_ZONE
		"propaganda":
			return SpecialMechanicType.PROPAGANDA
		"additional_fighters":
			return SpecialMechanicType.ADDITIONAL_FIGHTERS
		"reinforcement":
			return SpecialMechanicType.REINFORCEMENT
		_:
			return SpecialMechanicType.NONE

static func mechanic_to_string(mech_type: int) -> String:
	match mech_type:
		SpecialMechanicType.SHIELD:
			return "shield"
		SpecialMechanicType.HARD_SHIELD:
			return "hard_shield"
		SpecialMechanicType.TURRET:
			return "turret"
		SpecialMechanicType.SPEED_ZONE:
			return "speed_zone"
		SpecialMechanicType.SLOW_ZONE:
			return "slow_zone"
		SpecialMechanicType.PROPAGANDA:
			return "propaganda"
		SpecialMechanicType.ADDITIONAL_FIGHTERS:
			return "additional_fighters"
		SpecialMechanicType.REINFORCEMENT:
			return "reinforcement"
		_:
			return ""

static func owner_color(owner_id: int) -> Color:
	match owner_id:
		OwnerId.NEUTRAL:
			return Color(0.58, 0.62, 0.68, 1.0)
		OwnerId.PLAYER:
			return Color(0.18, 0.62, 0.96, 1.0)
		OwnerId.BOT_1:
			return Color(0.92, 0.28, 0.28, 1.0)
		OwnerId.BOT_2:
			return Color(0.96, 0.68, 0.16, 1.0)
		OwnerId.BOT_3:
			return Color(0.62, 0.34, 0.92, 1.0)
		OwnerId.BOT_4:
			return Color(0.18, 0.78, 0.48, 1.0)
		_:
			return Color(0.85, 0.42, 0.68, 1.0)

static func owner_name(owner_id: int) -> String:
	match owner_id:
		OwnerId.NEUTRAL:
			return "Neutral"
		OwnerId.PLAYER:
			return "Player"
		_:
			return "Bot %d" % (owner_id - 1)
