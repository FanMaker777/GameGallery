## セーブスロット選択画面 — ロードまたはニューゲームを選択する
class_name SaveSelect extends Control

@onready var _slot_container: VBoxContainer = %SlotContainer
@onready var _new_game_button: Button = %NewGameButton
@onready var _back_button: Button = %BackButton

## スロットごとのノードキャッシュ [{detail_label, load_btn}]
var _slot_cache: Array[Dictionary] = []


func _ready() -> void:
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_back_button.pressed.connect(_on_back_pressed)
	_build_slot_panels()
	_refresh()


## スロットパネルを初期構築する
func _build_slot_panels() -> void:
	for slot: int in SaveManager.SLOT_COUNT:
		var panel: PanelContainer = _create_slot_panel(slot)
		_slot_container.add_child(panel)


## 全スロットの表示を更新する
func _refresh() -> void:
	var panels: Array[Node] = _slot_container.get_children()
	for i: int in panels.size():
		_refresh_slot_panel(panels[i], i)


## 1スロット分のパネルを生成する
func _create_slot_panel(slot: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "Slot%d" % slot

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(hbox)

	# 左側: スロット情報
	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var slot_label := Label.new()
	slot_label.name = "SlotLabel"
	if slot == 0:
		slot_label.text = "オートセーブ"
	else:
		slot_label.text = "スロット %d" % slot
	slot_label.add_theme_font_size_override("font_size", 14)
	info_vbox.add_child(slot_label)

	var detail_label := Label.new()
	detail_label.name = "DetailLabel"
	detail_label.text = "-- 空きスロット --"
	detail_label.add_theme_font_size_override("font_size", 11)
	detail_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	info_vbox.add_child(detail_label)

	# 右側: ロードボタン
	var load_btn := Button.new()
	load_btn.name = "LoadButton"
	load_btn.text = "ロード"
	load_btn.custom_minimum_size = Vector2(80, 32)
	load_btn.pressed.connect(_on_load_pressed.bind(slot))
	hbox.add_child(load_btn)

	# 削除ボタン
	var delete_btn := Button.new()
	delete_btn.name = "DeleteButton"
	delete_btn.text = "削除"
	delete_btn.custom_minimum_size = Vector2(60, 32)
	delete_btn.pressed.connect(_on_delete_pressed.bind(slot))
	hbox.add_child(delete_btn)

	_slot_cache.append({
		"detail_label": detail_label,
		"load_btn": load_btn,
		"delete_btn": delete_btn,
	})
	return panel


## スロットパネルの表示を更新する
@warning_ignore("integer_division")
func _refresh_slot_panel(_panel: Node, slot: int) -> void:
	var cache: Dictionary = _slot_cache[slot]
	var detail_label: Label = cache["detail_label"]
	var load_btn: Button = cache["load_btn"]
	var delete_btn: Button = cache["delete_btn"]

	var meta: Dictionary = SaveManager.get_slot_info(slot)
	if not meta.is_empty():
		var timestamp: String = meta.get("timestamp", "")
		var map_name: String = meta.get("map_name", "")
		var play_time: float = float(meta.get("play_time_seconds", 0.0))
		var hours: int = int(play_time) / 3600
		var minutes: int = (int(play_time) % 3600) / 60
		detail_label.text = "%s | %s | %d時間%d分" % [timestamp, map_name, hours, minutes]
		detail_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		load_btn.disabled = false
		delete_btn.disabled = false
	else:
		detail_label.text = "-- 空きスロット --"
		detail_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		load_btn.disabled = true
		delete_btn.disabled = true


## ロードボタン押下
func _on_load_pressed(slot: int) -> void:
	SaveManager.load_from_slot(slot)


## 削除ボタン押下
func _on_delete_pressed(slot: int) -> void:
	SaveManager.delete_slot(slot)
	_refresh()


## ニューゲームボタン押下
func _on_new_game_pressed() -> void:
	SaveManager.reset_all_managers()
	GameManager.load_scene_with_transition(PathConsts.AM_VILLAGE_SCENE)


## 戻るボタン押下
func _on_back_pressed() -> void:
	GameManager.load_scene_with_transition(PathConsts.MAIN_MENU_SCENE)
