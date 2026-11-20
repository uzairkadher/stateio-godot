class_name MapSelectMenu
extends Control
## Map & difficulty selector reading data/maps/*.json dynamically.

signal map_chosen(map_path: String, difficulty: String)
signal back_requested

var save_manager: SaveManager = null
var _selected_difficulty: String = "normal"
var _list_box: VBoxContainer = null
var _diff_buttons: Dictionary = {}

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	refresh_maps()

func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 60)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "SELECT MAP & DIFFICULTY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	vbox.add_child(title)

	var diff_bar := HBoxContainer.new()
	diff_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	diff_bar.add_theme_constant_override("separation", 14)
	vbox.add_child(diff_bar)
	for d in ["easy", "normal", "hard"]:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(140, 60)
		btn.text = d.capitalize()
		var d_val: String = d
		btn.pressed.connect(func() -> void: _set_difficulty(d_val))
		diff_bar.add_child(btn)
		_diff_buttons[d] = btn
	_set_difficulty("normal")

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_list_box = VBoxContainer.new()
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_box.add_theme_constant_override("separation", 14)
	scroll.add_child(_list_box)

	var back_btn := Button.new()
	back_btn.custom_minimum_size = Vector2(220, 68)
	back_btn.text = "Back to Menu"
	back_btn.pressed.connect(func() -> void: back_requested.emit())
	vbox.add_child(back_btn)

func _set_difficulty(diff: String) -> void:
	_selected_difficulty = diff
	for k in _diff_buttons.keys():
		var b: Button = _diff_buttons[k]
		b.disabled = (k == diff)

func refresh_maps() -> void:
	if _list_box == null:
		return
	for c in _list_box.get_children():
		c.queue_free()

	var completed: Array = []
	if save_manager != null:
		completed = save_manager.data.get("progression", {}).get("completed_maps", [])

	for path in MapLoader.list_map_paths():
		var mdata: Dictionary = MapLoader.load_map(path)
		if mdata.has("_error"):
			continue
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 96)
		var tag: String = " [CLEARED]" if completed.has(str(mdata["map_id"])) else ""
		btn.text = "Stage %d: %s%s
%s" % [
			int(mdata.get("stage_number", 1)),
			str(mdata.get("display_name", "Map")),
			tag,
			str(mdata.get("description", "")),
		]
		var captured_path: String = path
		btn.pressed.connect(func() -> void: map_chosen.emit(captured_path, _selected_difficulty))
		_list_box.add_child(btn)
