class_name MainMenu
extends Control
## Main Menu screen (M9): Play, Map Selection, Settings, About.

signal play_quick_requested
signal map_select_requested
signal settings_requested
signal about_requested

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(460, 520)
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "FRONTIER COMMAND"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "Phase A Prototype — Independent Territory Strategy"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	vbox.add_child(sub)

	var buttons := [
		["Play Stage 1", func() -> void: play_quick_requested.emit()],
		["Map Selection", func() -> void: map_select_requested.emit()],
		["Settings", func() -> void: settings_requested.emit()],
		["About & Controls", func() -> void: about_requested.emit()],
	]
	for item in buttons:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(420, 76)
		btn.add_theme_font_size_override("font_size", 24)
		btn.text = item[0]
		btn.pressed.connect(item[1])
		vbox.add_child(btn)
