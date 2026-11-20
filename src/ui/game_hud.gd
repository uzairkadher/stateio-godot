class_name GameHUD
extends CanvasLayer
## Responsive mobile HUD: power bar, send percentage toggles (25%/50%/100%),
## pause/resume, restart, reinforcement trigger, countdown, and victory/defeat overlay.

signal pause_toggled(paused: bool)
signal restart_requested
signal menu_requested
signal send_ratio_changed(ratio: float)
signal reinforcement_requested
signal next_stage_requested

var _status_label: Label
var _power_label: Label
var _countdown_label: Label
var _pause_btn: Button
var _reinforce_btn: Button
var _ratio_buttons: Dictionary = {}
var _result_panel: PanelContainer
var _result_title: Label
var _result_details: Label
var _next_btn: Button
var _is_paused: bool = false

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_theme_constant_override("margin_left", 24)
	root.add_theme_constant_override("margin_right", 24)
	root.add_theme_constant_override("margin_top", 48)
	root.add_theme_constant_override("margin_bottom", 48)
	add_child(root)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(vbox)

	# Top bar
	var top_bar := HBoxContainer.new()
	vbox.add_child(top_bar)

	_status_label = Label.new()
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.add_theme_font_size_override("font_size", 24)
	_status_label.text = "Frontier Command"
	top_bar.add_child(_status_label)

	_pause_btn = Button.new()
	_pause_btn.custom_minimum_size = Vector2(120, 64)
	_pause_btn.text = "Pause"
	_pause_btn.pressed.connect(func() -> void:
		_is_paused = not _is_paused
		pause_toggled.emit(_is_paused)
	)
	top_bar.add_child(_pause_btn)

	var restart_btn := Button.new()
	restart_btn.custom_minimum_size = Vector2(120, 64)
	restart_btn.text = "Restart"
	restart_btn.pressed.connect(func() -> void: restart_requested.emit())
	top_bar.add_child(restart_btn)

	var menu_btn := Button.new()
	menu_btn.custom_minimum_size = Vector2(110, 64)
	menu_btn.text = "Menu"
	menu_btn.pressed.connect(func() -> void: menu_requested.emit())
	top_bar.add_child(menu_btn)

	# Power balance bar
	_power_label = Label.new()
	_power_label.add_theme_font_size_override("font_size", 20)
	_power_label.text = "Player: 0 | Bots: 0"
	vbox.add_child(_power_label)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(spacer)

	# Countdown label
	_countdown_label = Label.new()
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.add_theme_font_size_override("font_size", 56)
	_countdown_label.visible = false
	vbox.add_child(_countdown_label)

	# Bottom controls (Send % + Reinforcement)
	var bottom_bar := HBoxContainer.new()
	bottom_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_bar.add_theme_constant_override("separation", 16)
	vbox.add_child(bottom_bar)

	for pair in [["25%", 0.25], ["50%", 0.5], ["100%", 1.0]]:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(130, 72)
		btn.text = pair[0]
		var ratio_val: float = float(pair[1])
		btn.pressed.connect(func() -> void:
			_highlight_ratio(ratio_val)
			send_ratio_changed.emit(ratio_val)
		)
		bottom_bar.add_child(btn)
		_ratio_buttons[ratio_val] = btn
	_highlight_ratio(1.0)

	_reinforce_btn = Button.new()
	_reinforce_btn.custom_minimum_size = Vector2(180, 72)
	_reinforce_btn.text = "Reinforce +20"
	_reinforce_btn.pressed.connect(func() -> void: reinforcement_requested.emit())
	bottom_bar.add_child(_reinforce_btn)

	# Result overlay
	_result_panel = PanelContainer.new()
	_result_panel.set_anchors_preset(Control.PRESET_CENTER)
	_result_panel.custom_minimum_size = Vector2(520, 320)
	_result_panel.visible = false
	add_child(_result_panel)

	var rv := VBoxContainer.new()
	rv.alignment = BoxContainer.ALIGNMENT_CENTER
	rv.add_theme_constant_override("separation", 18)
	_result_panel.add_child(rv)

	_result_title = Label.new()
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_title.add_theme_font_size_override("font_size", 42)
	rv.add_child(_result_title)

	_result_details = Label.new()
	_result_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_details.add_theme_font_size_override("font_size", 22)
	rv.add_child(_result_details)

	var rbtns := HBoxContainer.new()
	rbtns.alignment = BoxContainer.ALIGNMENT_CENTER
	rbtns.add_theme_constant_override("separation", 16)
	rv.add_child(rbtns)

	_next_btn = Button.new()
	_next_btn.custom_minimum_size = Vector2(150, 64)
	_next_btn.text = "Next Stage"
	_next_btn.pressed.connect(func() -> void: next_stage_requested.emit())
	rbtns.add_child(_next_btn)

	var replay_btn := Button.new()
	replay_btn.custom_minimum_size = Vector2(140, 64)
	replay_btn.text = "Replay"
	replay_btn.pressed.connect(func() -> void: restart_requested.emit())
	rbtns.add_child(replay_btn)

	var back_btn := Button.new()
	back_btn.custom_minimum_size = Vector2(140, 64)
	back_btn.text = "Main Menu"
	back_btn.pressed.connect(func() -> void: menu_requested.emit())
	rbtns.add_child(back_btn)

func _highlight_ratio(active_ratio: float) -> void:
	for r in _ratio_buttons.keys():
		var b: Button = _ratio_buttons[r]
		b.disabled = is_equal_approx(float(r), active_ratio)

func update_from_snapshot(snap: SimSnapshot, reinforcement_available: bool) -> void:
	_is_paused = snap.is_paused
	_pause_btn.text = "Resume" if _is_paused else "Pause"
	_reinforce_btn.disabled = not reinforcement_available or snap.phase != GameEnums.MatchPhase.PLAYING

	_status_label.text = "%s  |  %.1fs" % [snap.map_display_name, snap.elapsed_time]
	var player_pop: int = int(snap.faction_power.get(GameEnums.OwnerId.PLAYER, 0))
	var bot_pop: int = 0
	for fid in snap.faction_power.keys():
		if int(fid) > GameEnums.OwnerId.PLAYER:
			bot_pop += int(snap.faction_power[fid])
	_power_label.text = "You: %d troops (%d nodes)  |  Opponents: %d troops" % [
		player_pop,
		int(snap.faction_buildings.get(GameEnums.OwnerId.PLAYER, 0)),
		bot_pop,
	]

	_countdown_label.visible = (snap.phase == GameEnums.MatchPhase.PRE_START)
	if _countdown_label.visible:
		_countdown_label.text = "GET READY: %.1f" % snap.countdown_remaining

	_result_panel.visible = (snap.phase == GameEnums.MatchPhase.ENDED)
	if _result_panel.visible:
		if snap.outcome == GameEnums.MatchOutcome.WIN:
			_result_title.text = "VICTORY"
			_next_btn.visible = true
		elif snap.outcome == GameEnums.MatchOutcome.LOSE:
			_result_title.text = "DEFEAT"
			_next_btn.visible = false
		else:
			_result_title.text = "DRAW"
			_next_btn.visible = false
		_result_details.text = "Time: %.1fs | Map: %s" % [snap.elapsed_time, snap.map_display_name]
