class_name AboutMenu
extends Control
## About & Controls screen (M9).

signal back_requested

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
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
	title.text = "ABOUT FRONTIER COMMAND"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	vbox.add_child(title)

	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 20)
	var lines: PackedStringArray = PackedStringArray([
		"Frontier Command (Phase A Prototype) is an independent Godot 4.3 mobile territory strategy game.",
		"",
		"CONTROLS:",
		"- Tap your building, then tap a target building to send troops.",
		"- Or drag from your building across multiple friendly nodes to a target.",
		"- Tap empty space to cancel selection.",
		"- Use 25% / 50% / 100% buttons to choose troop send ratio.",
		"- Use Reinforce +20 once per match on a selected friendly node.",
		"- Pinch or scroll to zoom; right-drag to pan camera.",
	])
	body.text = "\n".join(lines)
	vbox.add_child(body)

	var back_btn := Button.new()
	back_btn.custom_minimum_size = Vector2(220, 68)
	back_btn.text = "Back to Menu"
	back_btn.pressed.connect(func() -> void: back_requested.emit())
	vbox.add_child(back_btn)
