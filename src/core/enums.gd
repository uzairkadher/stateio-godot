class_name CoreEnums
extends RefCounted
## Locked enumerations shared across simulation, AI, map, and presentation layers.
## Pure RefCounted — zero Godot Node, rendering, or UI dependencies.

enum FactionId {
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

enum GameState {
	BOOT = 0,
	MENU = 1,
	PRE_START = 2,
	PLAYING = 3,
	PAUSED = 4,
	VICTORY = 5,
	DEFEAT = 6,
}

enum StageState {
	CAPTURED = 0,
	CURRENT = 1,
	AWAIT = 2,
}

enum ObjectiveType {
	NONE = 0,
	SKIRMISH = 10,
	BATTLE_ROYAL = 20,
	GOLD_RUSH = 30,
	DOMINATION = 40,
	CAPITAL = 50,
}

enum ObjectiveOutcome {
	NONE = 0,
	WIN = 10,
	LOSE = 20,
}

enum StatType {
	NONE = 0,
	LIMIT = 10,
	START = 11,
	SPAWN_SPEED = 12,
	MOVE_SPEED = 14,
	DUPLICATE_ON_SPAWN = 15,
}

enum StatOp {
	SUM = 10,
	MULTIPLY_BASE = 20,
	MULTIPLY_CUMULATIVE = 40,
}

enum BuildingSpecialType {
	NONE = 0,
	TURRET = 10,
	PROPAGANDA = 20,
	ADDITIONAL_FIGHTERS = 30,
	SHIELD = 40,
	SPEED_DOWN_ZONE = 50,
	SPEED_UP_ZONE = 51,
}

enum CommandType {
	NONE = 0,
	WAIT = 1,
	ATTACK_NEUTRAL = 2,
	ATTACK_PLAYER = 4,
	ATTACK_ENEMY_BOT = 8,
	DEFENCE = 32,
}
