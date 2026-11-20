class_name AppRouter
extends Node
## Main entry scene controller (res://scenes/main.tscn).
## Manages screen switching between MainMenu, MapSelectMenu, SettingsMenu, AboutMenu, and MatchScene.

var save_manager: SaveManager
var audio_manager: AudioManager
var _active_screen: Node = null

func _ready() -> void:
	save_manager = SaveManager.new()
	save_manager.load_save()

	audio_manager = AudioManager.new()
	audio_manager.name = "AudioManager"
	add_child(audio_manager)
	audio_manager.apply_settings(save_manager)

	_show_main_menu()

func _clear_active() -> void:
	if _active_screen != null and is_instance_valid(_active_screen):
		_active_screen.queue_free()
	_active_screen = null

func _show_main_menu() -> void:
	_clear_active()
	var scene: PackedScene = load("res://scenes/main_menu.tscn")
	var menu: MainMenu = scene.instantiate()
	add_child(menu)
	_active_screen = menu
	menu.play_quick_requested.connect(func() -> void:
		audio_manager.play_sfx("ui_click")
		_start_match("res://data/maps/stage_01_savanna_basin.json", "easy")
	)
	menu.map_select_requested.connect(func() -> void:
		audio_manager.play_sfx("ui_click")
		_show_map_select()
	)
	menu.settings_requested.connect(func() -> void:
		audio_manager.play_sfx("ui_click")
		_show_settings()
	)
	menu.about_requested.connect(func() -> void:
		audio_manager.play_sfx("ui_click")
		_show_about()
	)

func _show_map_select() -> void:
	_clear_active()
	var scene: PackedScene = load("res://scenes/map_select_menu.tscn")
	var m: MapSelectMenu = scene.instantiate()
	m.save_manager = save_manager
	add_child(m)
	_active_screen = m
	m.map_chosen.connect(func(map_path: String, diff: String) -> void:
		audio_manager.play_sfx("ui_click")
		_start_match(map_path, diff)
	)
	m.back_requested.connect(func() -> void:
		audio_manager.play_sfx("ui_click")
		_show_main_menu()
	)

func _show_settings() -> void:
	_clear_active()
	var scene: PackedScene = load("res://scenes/settings_menu.tscn")
	var s: SettingsMenu = scene.instantiate()
	s.save_manager = save_manager
	add_child(s)
	_active_screen = s
	s.settings_updated.connect(func() -> void: audio_manager.apply_settings(save_manager))
	s.back_requested.connect(func() -> void:
		audio_manager.play_sfx("ui_click")
		_show_main_menu()
	)

func _show_about() -> void:
	_clear_active()
	var scene: PackedScene = load("res://scenes/about_menu.tscn")
	var a: AboutMenu = scene.instantiate()
	add_child(a)
	_active_screen = a
	a.back_requested.connect(func() -> void:
		audio_manager.play_sfx("ui_click")
		_show_main_menu()
	)

func _start_match(map_path: String, difficulty: String) -> void:
	_clear_active()
	var scene: PackedScene = load("res://scenes/match_scene.tscn")
	var mc: MatchController = scene.instantiate()
	mc.save_manager = save_manager
	mc.audio_manager = audio_manager
	add_child(mc)
	_active_screen = mc
	mc.return_to_menu_requested.connect(func() -> void: _show_main_menu())
	mc.next_map_requested.connect(func(next_stage: int) -> void:
		var paths: Array[String] = MapLoader.list_map_paths()
		for p in paths:
			var md: Dictionary = MapLoader.load_map(p)
			if int(md.get("stage_number", 0)) == next_stage:
				_start_match(p, str(md.get("default_difficulty", difficulty)))
				return
		_show_map_select()
	)
	mc.start_map(map_path, difficulty)
