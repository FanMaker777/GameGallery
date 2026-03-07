## セーブ/ロードタブ — セーブスロットの一覧表示・操作を行う
class_name SaveTab extends MarginContainer

# ---- ノードキャッシュ ----
@onready var _slot_container: VBoxContainer = %SlotContainer
@onready var _confirm_dialog: ConfirmationDialog = $ConfirmationDialog

# ---- 状態 ----
## 確認ダイアログの操作種別
enum _PendingAction { NONE, SAVE, LOAD, DELETE }
var _pending_action: _PendingAction = _PendingAction.NONE
var _pending_slot: int = -1


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_confirm_dialog.confirmed.connect(_on_confirmed)
	_build_slot_panels()
	_refresh()


## タブが表示されたときにスロット情報を更新する
func _on_visibility_changed() -> void:
	if visible:
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

	# 右側: ボタン
	var button_hbox := HBoxContainer.new()
	button_hbox.add_theme_constant_override("separation", 8)
	hbox.add_child(button_hbox)

	# セーブボタン（オートセーブスロットには表示しない）
	if slot > 0:
		var save_btn := Button.new()
		save_btn.name = "SaveButton"
		save_btn.text = "セーブ"
		save_btn.custom_minimum_size = Vector2(80, 32)
		save_btn.pressed.connect(_on_save_pressed.bind(slot))
		button_hbox.add_child(save_btn)

	# ロードボタン
	var load_btn := Button.new()
	load_btn.name = "LoadButton"
	load_btn.text = "ロード"
	load_btn.custom_minimum_size = Vector2(80, 32)
	load_btn.pressed.connect(_on_load_pressed.bind(slot))
	button_hbox.add_child(load_btn)

	# 削除ボタン
	var delete_btn := Button.new()
	delete_btn.name = "DeleteButton"
	delete_btn.text = "削除"
	delete_btn.custom_minimum_size = Vector2(80, 32)
	delete_btn.pressed.connect(_on_delete_pressed.bind(slot))
	button_hbox.add_child(delete_btn)

	return panel


## スロットパネルの表示を更新する
func _refresh_slot_panel(panel: Node, slot: int) -> void:
	var detail_label: Label = panel.find_child("DetailLabel", true, false)
	var load_btn: Button = panel.find_child("LoadButton", true, false)
	var delete_btn: Button = panel.find_child("DeleteButton", true, false)

	if SaveManager.is_slot_used(slot):
		var meta: Dictionary = SaveManager.get_slot_info(slot)
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


## セーブボタン押下
func _on_save_pressed(slot: int) -> void:
	_pending_action = _PendingAction.SAVE
	_pending_slot = slot
	if SaveManager.is_slot_used(slot):
		_confirm_dialog.dialog_text = "スロット %d のデータを上書きしますか？" % slot
		_confirm_dialog.popup_centered()
	else:
		_execute_pending_action()


## ロードボタン押下
func _on_load_pressed(slot: int) -> void:
	_pending_action = _PendingAction.LOAD
	_pending_slot = slot
	_confirm_dialog.dialog_text = "スロット %d からデータをロードしますか？\n現在の進行状況は失われます。" % slot
	if slot == 0:
		_confirm_dialog.dialog_text = "オートセーブからデータをロードしますか？\n現在の進行状況は失われます。"
	_confirm_dialog.popup_centered()


## 削除ボタン押下
func _on_delete_pressed(slot: int) -> void:
	_pending_action = _PendingAction.DELETE
	_pending_slot = slot
	_confirm_dialog.dialog_text = "スロット %d のデータを削除しますか？\nこの操作は取り消せません。" % slot
	if slot == 0:
		_confirm_dialog.dialog_text = "オートセーブのデータを削除しますか？\nこの操作は取り消せません。"
	_confirm_dialog.popup_centered()


## 確認ダイアログで「OK」が押されたとき
func _on_confirmed() -> void:
	_execute_pending_action()


## 保留中のアクションを実行する
func _execute_pending_action() -> void:
	match _pending_action:
		_PendingAction.SAVE:
			SaveManager.save_to_slot(_pending_slot)
			_refresh()
		_PendingAction.LOAD:
			SaveManager.load_from_slot(_pending_slot)
		_PendingAction.DELETE:
			SaveManager.delete_slot(_pending_slot)
			_refresh()
	_pending_action = _PendingAction.NONE
	_pending_slot = -1
