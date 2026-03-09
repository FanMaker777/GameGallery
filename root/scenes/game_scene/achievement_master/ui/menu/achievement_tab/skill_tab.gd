## スキルタブの本体 — 左にカテゴリ別リスト、右に詳細パネルを表示する
## SkillManager のスキルツリーを UI から操作するためのタブ
class_name SkillTab extends MarginContainer

# ---- 定数 ----
## リスト項目シーン（.tscn に UID 未割当のため res:// を使用）
const LIST_ITEM_SCENE: PackedScene = preload(
	"res://root/scenes/game_scene/achievement_master/ui/menu/achievement_tab/skill_list_item.tscn"
)

## カテゴリフィルタの選択肢（index 0 = 全て）
const CATEGORY_OPTIONS: Array[String] = [
	"全て", "グローバルQoL", "戦闘", "農業", "探索"
]

## カテゴリヘッダーの表示名
const CATEGORY_HEADERS: Dictionary = {
	SkillDefinition.Category.GLOBAL_QOL: "グローバルQoL",
	SkillDefinition.Category.COMBAT: "戦闘",
	SkillDefinition.Category.FARMING: "農業",
	SkillDefinition.Category.EXPLORATION: "探索",
}

## セクションラベル色（ゴールド）
const SECTION_LABEL_COLOR: Color = Color(1.0, 0.84, 0.0, 0.8)

## 効果サマリの表示名マッピング
const EFFECT_LABELS: Array[Array] = [
	["hp_percent_up", "HP +%s%%"],
	["attack_percent_up", "攻撃 +%s%%"],
	["respawn_time_down", "復帰短縮 %s%%"],
	["stamina_max_up", "スタミナ +%s%%"],
	["stamina_recovery_up", "スタミナ回復 +%s%%"],
	["harvest_bonus", "収穫 +%s%%"],
	["gather_speed_up", "採取速度 +%s%%"],
	["move_speed_up", "移動速度 +%s%%"],
	["shop_discount", "店割引 %s%%"],
]

# ---- ノードキャッシュ ----
## 利用可能APの表示ラベル
@onready var _ap_label: Label = %ApLabel
## カテゴリフィルタ
@onready var _category_filter: OptionButton = %CategoryFilter
## リスト項目のコンテナ
@onready var _list_container: VBoxContainer = %ListContainer
## 詳細パネルのスキル名ラベル
@onready var _detail_name_label: Label = %DetailNameLabel
## 詳細パネルの説明ラベル
@onready var _detail_desc_label: Label = %DetailDescLabel
## 詳細パネルのAPコストラベル
@onready var _detail_cost_label: Label = %DetailCostLabel
## 詳細パネルの前提ノード表示ラベル
@onready var _detail_prereq_label: Label = %DetailPrereqLabel
## 解放ボタン
@onready var _unlock_button: Button = %UnlockButton
## 解放不可の理由ラベル
@onready var _lock_reason_label: Label = %LockReasonLabel
## 効果サマリラベル
@onready var _effect_summary_label: Label = %EffectSummaryLabel
## 未選択時の案内ラベル
@onready var _empty_label: Label = %EmptyLabel
## 詳細コンテンツのコンテナ
@onready var _detail_content: VBoxContainer = %DetailContent

# ---- 状態 ----
## 現在選択中のスキル定義
var _selected_def: SkillDefinition = null
## 現在表示中のリスト項目への参照（選択状態管理用）
var _current_items: Array[SkillListItem] = []


## 初期化処理 — フィルタ設定・シグナル接続・リスト構築を行う
func _ready() -> void:
	# フィルタの選択肢を設定する
	_setup_filters()
	# フィルタ変更シグナルを接続する
	_category_filter.item_selected.connect(_on_filter_changed)
	# 解放ボタンのシグナルを接続する
	_unlock_button.pressed.connect(_on_unlock_button_pressed)
	# タブ表示切替時にリストを更新するためシグナルを接続する
	visibility_changed.connect(_on_visibility_changed)
	# SkillManager のシグナルを購読する（遅延接続）
	_connect_to_manager.call_deferred()
	# 初期状態: 詳細パネルを空表示にする
	_show_empty_detail()
	# リストを構築する
	_rebuild_list()


## SkillManager のシグナルを購読する（遅延接続）
func _connect_to_manager() -> void:
	SkillManager.skill_unlocked.connect(_on_skill_unlocked)
	SkillManager.available_ap_changed.connect(_on_available_ap_changed)


## フィルタ OptionButton の選択肢を設定する
func _setup_filters() -> void:
	_category_filter.clear()
	# カテゴリフィルタの選択肢を追加する
	for option: String in CATEGORY_OPTIONS:
		_category_filter.add_item(option)


# ========== リスト構築 ==========

## フィルタ条件に基づいてリストを再構築する
func _rebuild_list() -> void:
	# 既存の項目を全て削除する
	_current_items.clear()
	for child: Node in _list_container.get_children():
		child.queue_free()
	# APラベルを更新する
	_update_ap_label()
	# フィルタ条件を取得する
	var cat_idx: int = _category_filter.selected
	if cat_idx == 0:
		# 「全て」選択時はカテゴリごとにセクションヘッダーを挿入する
		for category: int in CATEGORY_HEADERS:
			var defs: Array[SkillDefinition] = SkillManager.get_definitions_by_category(
				category as SkillDefinition.Category
			)
			if defs.is_empty():
				continue
			# セクションヘッダーを追加する
			_add_section_label(CATEGORY_HEADERS[category])
			# スキル項目を追加する
			for def: SkillDefinition in defs:
				_add_list_item(def)
	else:
		# 特定カテゴリ選択時はそのカテゴリのみ表示する
		var category: SkillDefinition.Category = (cat_idx - 1) as SkillDefinition.Category
		var defs: Array[SkillDefinition] = SkillManager.get_definitions_by_category(category)
		for def: SkillDefinition in defs:
			_add_list_item(def)
		# リストが空の場合はメッセージを表示する
		if defs.is_empty():
			var empty: Label = Label.new()
			empty.text = "該当するスキルがありません"
			empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty.add_theme_font_size_override("font_size", 11)
			_list_container.add_child(empty)
	# 効果サマリを更新する
	_update_effect_summary()


## リストにセクション区切りラベルを追加する
func _add_section_label(text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", SECTION_LABEL_COLOR)
	_list_container.add_child(label)


## リストに1件のスキル項目を追加する
func _add_list_item(def: SkillDefinition) -> void:
	var item: SkillListItem = LIST_ITEM_SCENE.instantiate() as SkillListItem
	_list_container.add_child(item)
	# スキルデータを設定する
	item.setup(def)
	# 選択シグナルを接続する
	item.item_selected.connect(_on_item_selected)
	_current_items.append(item)
	# 選択状態を復元する
	if _selected_def != null and def.id == _selected_def.id:
		item.set_selected(true)


# ========== 詳細パネル ==========

## 詳細パネルにスキル情報を表示する
func _show_detail(def: SkillDefinition) -> void:
	# 空表示を非表示にする
	_empty_label.visible = false
	# 詳細コンテンツを表示する
	_detail_content.visible = true
	# スキル名
	_detail_name_label.text = def.name_ja
	# 説明
	_detail_desc_label.text = def.description_ja
	# APコスト
	_detail_cost_label.text = "コスト: %d AP" % def.ap_cost
	# 前提ノードの充足状況
	_update_prereq_label(def)
	# 解放ボタンの状態更新
	_update_unlock_button(def)


## 詳細パネルを空表示にする（スキル未選択時）
func _show_empty_detail() -> void:
	_empty_label.visible = true
	_detail_content.visible = false


## 前提ノードの表示を更新する
func _update_prereq_label(def: SkillDefinition) -> void:
	if def.prerequisites.is_empty():
		# 前提なし
		_detail_prereq_label.text = "前提: なし"
		_detail_prereq_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		return
	# 前提ノードの名前と充足状態を表示する
	var parts: PackedStringArray = []
	for prereq_id: StringName in def.prerequisites:
		var prereq_def: SkillDefinition = SkillManager.get_definition(prereq_id)
		var prereq_name: String = prereq_def.name_ja if prereq_def != null else str(prereq_id)
		var mark: String = "✓" if SkillManager.is_unlocked(prereq_id) else "✗"
		parts.append("%s %s" % [mark, prereq_name])
	_detail_prereq_label.text = "前提: %s" % ", ".join(parts)
	# 全て充足しているかで色を変える
	var all_met: bool = _all_prereqs_met(def)
	if all_met:
		_detail_prereq_label.add_theme_color_override("font_color", SkillListItem.UNLOCKED_TEXT_COLOR)
	else:
		_detail_prereq_label.add_theme_color_override("font_color", Color(0.85, 0.4, 0.4))


## 解放ボタンの表示と有効/無効を更新する
## 解放不可の場合は理由（AP不足 / 前提未充足）を表示する
func _update_unlock_button(def: SkillDefinition) -> void:
	if SkillManager.is_unlocked(def.id):
		# 解放済み
		_unlock_button.text = "解放済み"
		_unlock_button.disabled = true
		_lock_reason_label.visible = false
	elif SkillManager.can_unlock(def.id):
		# 解放可能
		_unlock_button.text = "解放する (%d AP)" % def.ap_cost
		_unlock_button.disabled = false
		_lock_reason_label.visible = false
	else:
		# 解放不可 — 理由を判定して表示する
		_unlock_button.text = "解放不可"
		_unlock_button.disabled = true
		_lock_reason_label.visible = true
		_lock_reason_label.text = _get_lock_reason(def)


## 全前提ノードが解放済みかを返す
func _all_prereqs_met(def: SkillDefinition) -> bool:
	return def.prerequisites.all(
		func(id: StringName) -> bool: return SkillManager.is_unlocked(id)
	)


## 解放不可の理由を判定して文字列を返す
func _get_lock_reason(def: SkillDefinition) -> String:
	# 前提ノードの充足チェック
	if not _all_prereqs_met(def):
		# 未充足の前提ノード名を列挙する
		var missing: PackedStringArray = []
		for prereq_id: StringName in def.prerequisites:
			if not SkillManager.is_unlocked(prereq_id):
				var prereq_def: SkillDefinition = SkillManager.get_definition(prereq_id)
				var prereq_name: String = prereq_def.name_ja if prereq_def != null else str(prereq_id)
				missing.append(prereq_name)
		return "前提未充足: %s が必要" % ", ".join(missing)
	# 前提は充足しているがAP不足
	var available: int = SkillManager.get_available_ap()
	return "AP不足 (所持: %d / 必要: %d)" % [available, def.ap_cost]


## APラベルを更新する
func _update_ap_label() -> void:
	_ap_label.text = "利用可能AP: %d" % SkillManager.get_available_ap()


## 効果サマリを更新する
func _update_effect_summary() -> void:
	var cache: SkillEffectCache = SkillManager.get_effect_cache()
	var parts: PackedStringArray = []
	# 数値系の効果を収集する
	for entry: Array in EFFECT_LABELS:
		var prop_name: String = entry[0]
		var format_str: String = entry[1]
		var value: float = cache.get(prop_name)
		if value > 0.0:
			parts.append(format_str % str(int(value)))
	# フラグ系の効果を収集する
	if cache.auto_collect_multiplier > 1.0:
		parts.append("自動回収 x%s" % str(cache.auto_collect_multiplier))
	if cache.pin_slot_bonus > 0:
		parts.append("ピン枠 +%d" % cache.pin_slot_bonus)
	if cache.diversity_bonus_enabled:
		parts.append("多様性ボーナス")
	if cache.minimap_enabled:
		parts.append("ミニマップ")
	if cache.fast_travel_enabled:
		parts.append("ファストトラベル")
	# サマリテキストを設定する
	if parts.is_empty():
		_effect_summary_label.text = "解放済み効果: なし"
	else:
		_effect_summary_label.text = "解放済み効果: %s" % ", ".join(parts)


# ========== シグナルハンドラ ==========

## リスト項目が選択されたときのコールバック
func _on_item_selected(def: SkillDefinition) -> void:
	_selected_def = def
	# 全項目の選択状態をリセットし、選択された項目だけ選択状態にする
	for item: SkillListItem in _current_items:
		item.set_selected(item.get_definition().id == def.id)
	# 詳細パネルを更新する
	_show_detail(def)


## フィルタが変更されたときのコールバック
func _on_filter_changed(_index: int) -> void:
	_rebuild_list()


## 解放ボタンが押されたときのコールバック
func _on_unlock_button_pressed() -> void:
	if _selected_def == null:
		return
	# スキルを解放する
	var success: bool = SkillManager.unlock_skill(_selected_def.id)
	if success:
		AudioManager.play_se(AudioConsts.SE_GET_SKILL)
		Log.debug("SkillTab: スキル '%s' を解放しました" % _selected_def.name_ja)


## スキルが解放されたときのコールバック
func _on_skill_unlocked(
	_id: StringName, _definition: SkillDefinition
) -> void:
	# リストと詳細を更新する
	_rebuild_list()
	# 選択中のスキルが有効か確認してから詳細を更新する
	_refresh_selected_detail()


## 利用可能APが変更されたときのコールバック
func _on_available_ap_changed(_available_ap: int) -> void:
	# APラベルを更新する
	_update_ap_label()


## タブの表示状態が変わったときのコールバック
func _on_visibility_changed() -> void:
	# 可視状態になったときにリストを最新化する
	if visible:
		_rebuild_list()
		# 選択中のスキルが有効か確認してから詳細を更新する
		_refresh_selected_detail()


## 選択中のスキルが有効なら詳細を更新、無効なら空表示に戻す
func _refresh_selected_detail() -> void:
	if _selected_def == null:
		return
	# SkillManager に定義が存在するか確認する
	var current_def: SkillDefinition = SkillManager.get_definition(_selected_def.id)
	if current_def == null:
		# 定義が削除された（リセット等）場合は選択解除する
		_selected_def = null
		_show_empty_detail()
	else:
		_show_detail(_selected_def)
