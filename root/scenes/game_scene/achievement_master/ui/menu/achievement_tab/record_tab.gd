## レコードタブ — プレイ記録の統計データを表示する
class_name RecordTab extends MarginContainer

## 距離変換定数（ピクセル → メートル）
const PIXELS_PER_METER: float = 100.0

## セクションヘッダーの色
const SECTION_COLOR: Color = Color(1.0, 0.84, 0.0, 0.8)

## インデント付きサブ項目の左マージン
const SUB_ITEM_MARGIN: int = 24

# ---- ノードキャッシュ ----
@onready var _records_container: VBoxContainer = %RecordsContainer


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_rebuild()


## タブが表示されたときに再構築する
func _on_visibility_changed() -> void:
	if visible:
		_rebuild()


## レコード一覧を再構築する
func _rebuild() -> void:
	# 既存の子ノードを削除する
	for child: Node in _records_container.get_children():
		child.queue_free()
	# 各カテゴリを構築する
	_build_basic_stats()
	_build_combat_stats()
	_build_harvest_stats()
	_build_exploration_stats()
	_build_achievement_stats()


# ========== カテゴリ別構築 ==========

## 基本統計
func _build_basic_stats() -> void:
	_add_section_header("基本統計")
	# プレイ時間
	var total_seconds: float = AchievementManager.get_play_time_seconds()
	var hours: int = int(total_seconds) / 3600
	var minutes: int = (int(total_seconds) % 3600) / 60
	_add_stat_row("プレイ時間", "%d時間%d分" % [hours, minutes])
	# 総移動距離
	var distance_px: int = AchievementManager.get_stat(&"distance_walked")
	var distance_m: float = float(distance_px) / PIXELS_PER_METER
	_add_stat_row("総移動距離", "%dm" % int(distance_m))


## 戦闘統計
func _build_combat_stats() -> void:
	_add_section_header("戦闘")
	# 総討伐数
	var total_kills: int = AchievementManager.get_stat(&"enemy_killed")
	_add_stat_row("総討伐数", str(total_kills))
	# 敵種別ごと
	var kills_by_type: Dictionary = AchievementManager.get_stat_by_type(&"enemy_killed")
	for type_name: String in kills_by_type.keys():
		_add_stat_row(type_name, str(kills_by_type[type_name]), true)
	# 攻撃回数
	_add_stat_row("攻撃回数", str(AchievementManager.get_stat(&"attack_started")))
	# 被ダメージ回数
	_add_stat_row("被ダメージ回数", str(AchievementManager.get_stat(&"player_damaged")))
	# 死亡回数
	_add_stat_row("死亡回数", str(AchievementManager.get_stat(&"player_died")))


## 採取統計
func _build_harvest_stats() -> void:
	_add_section_header("採取")
	# 総採取数
	_add_stat_row("総採取数", str(AchievementManager.get_stat(&"resource_harvested")))
	# 種別ごと
	_add_stat_row("木材", str(AchievementManager.get_stat(&"resource_harvested_wood")), true)
	_add_stat_row("金鉱石", str(AchievementManager.get_stat(&"resource_harvested_gold")), true)
	_add_stat_row("羊肉", str(AchievementManager.get_stat(&"resource_harvested_meat")), true)


## 探索統計
func _build_exploration_stats() -> void:
	_add_section_header("探索")
	_add_stat_row("NPC会話回数", str(AchievementManager.get_stat(&"npc_talked")))


## 実績統計
func _build_achievement_stats() -> void:
	_add_section_header("実績")
	var unlocked_count: int = AchievementManager.get_unlocked_ids().size()
	var total_count: int = AchievementManager.get_all_definitions().size()
	_add_stat_row("解除済み", "%d / %d" % [unlocked_count, total_count])
	_add_stat_row("合計AP", str(AchievementManager.get_total_ap()))


# ========== UI ヘルパー ==========

## セクションヘッダーを追加する
func _add_section_header(text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", SECTION_COLOR)
	# 最初のセクション以外は上にスペースを追加する
	if _records_container.get_child_count() > 0:
		var spacer: Control = Control.new()
		spacer.custom_minimum_size.y = 8
		_records_container.add_child(spacer)
	_records_container.add_child(label)
	# 区切り線
	var separator: HSeparator = HSeparator.new()
	_records_container.add_child(separator)


## 統計行を追加する（左: 項目名、右: 値）
func _add_stat_row(label_text: String, value_text: String, is_sub: bool = false) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	# サブ項目の場合は左マージンを追加する
	if is_sub:
		var margin: MarginContainer = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", SUB_ITEM_MARGIN)
		margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var inner_row: HBoxContainer = HBoxContainer.new()
		inner_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_label: Label = Label.new()
		name_label.text = label_text
		name_label.add_theme_font_size_override("font_size", 11)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
		var value_label: Label = Label.new()
		value_label.text = value_text
		value_label.add_theme_font_size_override("font_size", 11)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
		inner_row.add_child(name_label)
		inner_row.add_child(value_label)
		margin.add_child(inner_row)
		_records_container.add_child(margin)
	else:
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_label: Label = Label.new()
		name_label.text = label_text
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var value_label: Label = Label.new()
		value_label.text = value_text
		value_label.add_theme_font_size_override("font_size", 12)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(name_label)
		row.add_child(value_label)
		_records_container.add_child(row)
