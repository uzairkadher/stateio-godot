class_name SettingsMenu
extends Control
## Settings menu (M9): audio toggles, volume sliders, vibration, safe area, language hook.

signal settings_updated
signal back_requested

var save_manager: SaveManager = null

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func _build_ui() -> void:
	if save_manager == null:
		save_manager = SaveManager.new()
		save_manager.load_save()

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 64)
	margin.add_theme_constant_override("margin_bottom", 64)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	vbox.add_child(title)

	var music_cb := CheckButton.new()
	music_cb.text = "Music Enabled"
	music_cb.button_pressed = bool(save_manager.get_setting("music_enabled", true))
	music_cb.toggled.connect(func(v: bool) -> void:
		save_manager.set_setting("music_enabled", v)
		settings_updated.emit()
	)
	vbox.add_child(music_cb)

	var sfx_cb := CheckButton.new()
	sfx_cb.text = "Sound Effects Enabled"
	sfx_cb.button_pressed = bool(save_manager.get_setting("sfx_enabled", true))
	sfx_cb.toggled.connect(func(v: bool) -> void:
		save_manager.set_setting("sfx_enabled", v)
		settings_updated.emit()
	)
	vbox.add_child(sfx_cb)

	var vib_cb := CheckButton.new()
	vib_cb.text = "Haptic Vibration"
	vib_cb.button_pressed = bool(save_manager.get_setting("vibration_enabled", true))
	vib_cb.toggled.connect(func(v: bool) -> void:
		save_manager.set_setting("vibration_enabled", v)
		settings_updated.emit()
	)
	vbox.add_child(vib_cb)

	var vol_label := Label.new()
	vol_label.text = "SFX Volume"
	vbox.add_child(vol_label)

	var vol_slider := HSlider.new()
	vol_slider.min_value = 0.0
	vol_slider.max_value = 1.0
	vol_slider.step = 0.05
	vol_slider.value = float(save_manager.get_setting("sfx_volume", 0.85))
	vol_slider.value_changed.connect(func(val: float) -> void:
		save_manager.set_setting("sfx_volume", val)
		settings_updated.emit()
	)
	vbox.add_child(vol_slider)

	var back_btn := Button.new()
	back_btn.custom_minimum_size = Vector2(220, 68)
	back_btn.text = "Back to Menu"
	back_btn.pressed.connect(func() -> void: back_requested.emit())
	vbox.add_child(back_btn)
