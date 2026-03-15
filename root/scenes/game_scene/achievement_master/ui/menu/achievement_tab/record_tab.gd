## レコードタブ — プレイ記録の統計データを表示する
class_name RecordTab extends MarginContainer

## インデント付きサブ項目の左マージン
const SUB_ITEM_MARGIN: int = 24

# ---- ノードキャッシュ ----
@onready var _play_time_value: Label = %PlayTimeValue
@onready var _distance_value: Label = %DistanceValue
@onready var _total_kills_value: Label = %TotalKillsValue
@onready var _kills_by_type_container: VBoxContainer = %KillsByTypeContainer
@onready var _attacks_value: Label = %AttacksValue
@onready var _damage_taken_value: Label = %DamageTakenValue
@onready var _deaths_value: Label = %DeathsValue
@onready var _total_harvest_value: Label = %TotalHarvestValue
@onready var _wood_value: Label = %WoodValue
@onready var _gold_value: Label = %GoldValue
@onready var _meat_value: Label = %MeatValue
@onready var _npc_talked_value: Label = %NpcTalkedValue
@onready var _unlocked_value: Label = %UnlockedValue
@onready var _total_ap_value: Label = %TotalApValue
@onready var _clear_button: Button = %ClearButton
@onready var _warning_dialog: WarningDialog = $WarningDialog


## シグナル接続と初期表示を行う
func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_clear_button.pressed.connect(_on_clear_button_pressed)
	_warning_dialog.confirmed.connect(_on_clear_confirmed)
	_refresh()


## タブが表示されたときに値を更新する
func _on_visibility_changed() -> void:
	if visible:
		_refresh()


## 全統計値を更新する
func _refresh() -> void:
	# プレイ時間
	var total_seconds: float = AchievementManager.tracker.get_play_time_seconds()
	var hours: int = int(total_seconds) / 3600
	var minutes: int = (int(total_seconds) % 3600) / 60
	_play_time_value.text = "%d時間%d分" % [hours, minutes]
	# 総移動距離
	var distance_m: int = AchievementManager.tracker.get_stat(&"distance_walked")
	_distance_value.text = "%dm" % distance_m
	# 総討伐数
	_total_kills_value.text = str(AchievementManager.tracker.get_stat(&"enemy_killed"))
	# 敵種別ごとの討伐数
	_refresh_kills_by_type()
	# 攻撃回数
	_attacks_value.text = str(AchievementManager.tracker.get_stat(&"attack_started"))
	# 被ダメージ回数
	_damage_taken_value.text = str(AchievementManager.tracker.get_stat(&"player_damaged"))
	# 死亡回数
	_deaths_value.text = str(AchievementManager.tracker.get_stat(&"player_died"))
	# 総採取数
	_total_harvest_value.text = str(AchievementManager.tracker.get_stat(&"resource_harvested"))
	# 種別ごとの採取数
	_wood_value.text = str(AchievementManager.tracker.get_stat(&"resource_harvested_wood"))
	_gold_value.text = str(AchievementManager.tracker.get_stat(&"resource_harvested_gold"))
	_meat_value.text = str(AchievementManager.tracker.get_stat(&"resource_harvested_meat"))
	# NPC会話回数
	_npc_talked_value.text = str(AchievementManager.tracker.get_stat(&"npc_talked"))
	# 実績
	var unlocked_count: int = AchievementManager.tracker.get_unlocked_ids().size()
	var total_count: int = AchievementManager.tracker.get_all_definitions().size()
	_unlocked_value.text = "%d / %d" % [unlocked_count, total_count]
	_total_ap_value.text = str(AchievementManager.tracker.get_total_ap())


## クリアボタン押下時 → 警告ダイアログを表示する
func _on_clear_button_pressed() -> void:
	_warning_dialog.show_warning("レコードクリア", "この操作は取り消せません。\n本当にレコードをクリアしますか？")


## 警告ダイアログで「はい」が押されたとき
func _on_clear_confirmed() -> void:
	AchievementManager.tracker.reset_records()
	_refresh()


## 敵種別ごとの討伐数を動的に再構築する
func _refresh_kills_by_type() -> void:
	for child: Node in _kills_by_type_container.get_children():
		child.queue_free()
	var kills_by_type: Dictionary = AchievementManager.tracker.get_stat_by_type(&"enemy_killed")
	for type_name: String in kills_by_type.keys():
		var margin: MarginContainer = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", SUB_ITEM_MARGIN)
		margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row: HBoxContainer = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_label: Label = Label.new()
		name_label.text = type_name
		name_label.add_theme_font_size_override("font_size", 11)
		name_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 1.0))
		var value_label: Label = Label.new()
		value_label.text = str(kills_by_type[type_name])
		value_label.add_theme_font_size_override("font_size", 11)
		value_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1.0))
		row.add_child(name_label)
		row.add_child(value_label)
		margin.add_child(row)
		_kills_by_type_container.add_child(margin)
