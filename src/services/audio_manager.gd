class_name AudioManager
extends Node
## Modular voice-limiting AudioManager subscribing to EventBus events.

const SFX_PATHS: Dictionary = {
	"ui_click": "res://assets/audio/ui_click.wav",
	"send": "res://assets/audio/send_troops.wav",
	"hit": "res://assets/audio/combat_hit.wav",
	"capture": "res://assets/audio/capture.wav",
	"shield": "res://assets/audio/shield_block.wav",
	"turret": "res://assets/audio/turret_shot.wav",
	"victory": "res://assets/audio/victory.wav",
	"defeat": "res://assets/audio/defeat.wav",
}
const MUSIC_PATH := "res://assets/audio/ambient_loop.wav"

var music_enabled: bool = true
var sfx_enabled: bool = true
var music_volume: float = 0.6
var sfx_volume: float = 0.85
var min_sfx_interval_sec: float = 0.05

var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer = null
var _streams: Dictionary = {}
var _last_play_msec: Dictionary = {}
var _pool_index: int = 0

func _ready() -> void:
	for i in range(6):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_players.append(p)
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	_preload_streams()

func _preload_streams() -> void:
	for key in SFX_PATHS.keys():
		var path: String = SFX_PATHS[key]
		if ResourceLoader.exists(path):
			_streams[key] = load(path)
	if ResourceLoader.exists(MUSIC_PATH):
		_streams["music"] = load(MUSIC_PATH)

func apply_settings(save_mgr: SaveManager) -> void:
	if save_mgr == null:
		return
	music_enabled = bool(save_mgr.get_setting("music_enabled", true))
	sfx_enabled = bool(save_mgr.get_setting("sfx_enabled", true))
	music_volume = clampf(float(save_mgr.get_setting("music_volume", 0.6)), 0.0, 1.0)
	sfx_volume = clampf(float(save_mgr.get_setting("sfx_volume", 0.85)), 0.0, 1.0)
	_refresh_music_state()

func bind_event_bus(bus: EventBus) -> void:
	if bus == null:
		return
	bus.subscribe("troops_sent", func(_p: Dictionary) -> void: play_sfx("send"))
	bus.subscribe("owner_changed", func(_p: Dictionary) -> void: play_sfx("capture"))
	bus.subscribe("mid_air_clash", func(_p: Dictionary) -> void: play_sfx("hit"))
	bus.subscribe("shield_absorbed", func(_p: Dictionary) -> void: play_sfx("shield"))
	bus.subscribe("turret_fired", func(_p: Dictionary) -> void: play_sfx("turret"))
	bus.subscribe("match_ended", func(p: Dictionary) -> void:
		if int(p.get("outcome", 0)) == GameEnums.MatchOutcome.WIN:
			play_sfx("victory")
		else:
			play_sfx("defeat")
	)

func play_sfx(key: String) -> void:
	if not sfx_enabled or sfx_volume <= 0.001:
		return
	if not _streams.has(key) or _sfx_players.is_empty():
		return
	var now_ms: int = Time.get_ticks_msec()
	var last_ms: int = int(_last_play_msec.get(key, 0))
	if float(now_ms - last_ms) < min_sfx_interval_sec * 1000.0:
		return
	_last_play_msec[key] = now_ms
	var p: AudioStreamPlayer = _sfx_players[_pool_index]
	_pool_index = (_pool_index + 1) % _sfx_players.size()
	p.stream = _streams[key]
	p.volume_db = linear_to_db(sfx_volume)
	p.play()

func _refresh_music_state() -> void:
	if _music_player == null:
		return
	if not music_enabled or music_volume <= 0.001:
		_music_player.stop()
		return
	_music_player.volume_db = linear_to_db(music_volume)
	if not _music_player.playing and _streams.has("music"):
		_music_player.stream = _streams["music"]
		_music_player.play()
