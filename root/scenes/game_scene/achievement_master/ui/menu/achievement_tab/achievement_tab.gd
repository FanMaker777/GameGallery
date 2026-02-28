## 実績タブの本体 — 左にフィルタ付きリスト、右に詳細パネルを表示する
class_name AchievementTab extends MarginContainer

# ---- 定数 ----
## リスト項目シーン（UID は後で置換する）
const LIST_ITEM_SCENE: PackedScene = preload(
	"res://root/scenes/game_scene/achievement_master/ui/menu/achievement_tab/achievement_list_item.tscn"
)

## カテゴリフィルタの選択肢（index 0 = 全て）
const CATEGORY_OPTIONS: Array[String] = [
	"全て", "戦闘", "農業", "探索", "交流", "システム"
]

## ステータスフィルタの選択肢
const STATUS_OPTIONS: Array[String] = [
	"全て", "未達成", "達成済"
]

## おすすめセクションに表示する最大件数
const RECOMMEND_COUNT: int = 3

## おすすめセクションの区切りラベル色
const SECTION_LABEL_COLOR: Color = Color(1.0, 0.84, 0.0, 0.8)

# ---- ノードキャッシュ ----
## カテゴリフィルタ
@onready var _category_filter: OptionButton = %CategoryFilter
## ステータスフィルタ
@onready var _status_filter: OptionButton = %StatusFilter
## リスト項目のコンテナ
@onready var _list_container: VBoxContainer = %ListContainer
## 詳細パネルのランクラベル
@onready var _detail_rank_label: Label = %DetailRankLabel
## 詳細パネルの名前ラベル
@onready var _detail_name_label: Label = %DetailNameLabel
## 詳細パネルの説明ラベル
@onready var _detail_desc_label: Label = %DetailDescLabel
## 進捗コンテナ
@onready var _progress_container: VBoxContainer = %ProgressContainer
## 進捗テキストラベル
@onready var _progress_label: Label = %ProgressLabel
## 進捗バー
@onready var _progress_bar: ProgressBar = %ProgressBar
## AP報酬ラベル
@onready var _ap_label: Label = %ApLabel
## ピン留めボタン
@onready var _pin_button: Button = %PinButton
## 未選択時の案内ラベル
@onready var _empty_label: Label = %EmptyLabel

# ---- 状態 ----
## 現在選択中の実績定義
var _selected_def: AchievementDefinition = null
## 現在表示中のリスト項目への参照（選択状態管理用）
var _current_items: Array[AchievementListItem] = []


## 初期化処理 — フィルタ設定・シグナル接続・リスト構築を行う
func _ready() -> void:
	# フィルタの選択肢を設定する
	_setup_filters()
	# フィルタ変更シグナルを接続する
	_category_filter.item_selected.connect(_on_filter_changed)
	_status_filter.item_selected.connect(_on_filter_changed)
	# ピン留めボタンのシグナルを接続する
	_pin_button.pressed.connect(_on_pin_button_pressed)
	# タブ表示切替時にリストを更新するためシグナルを接続する
	visibility_changed.connect(_on_visibility_changed)
	# AchievementManager のシグナルを購読する（遅延接続）
	_connect_to_manager.call_deferred()
	# 初期状態: 詳細パネルを空表示にする
	_show_empty_detail()
	# リストを構築する
	_rebuild_list()


## AchievementManager のシグナルを購読する（遅延接続）
func _connect_to_manager() -> void:
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	AchievementManager.achievement_progress_updated.connect(_on_progress_updated)
	AchievementManager.pinned_changed.connect(_on_pinned_changed)


## フィルタ OptionButton の選択肢を設定する
func _setup_filters() -> void:
	# カテゴリフィルタの選択肢を追加する
	_category_filter.clear()
	for option: String in CATEGORY_OPTIONS:
		_category_filter.add_item(option)
	# ステータスフィルタの選択肢を追加する
	_status_filter.clear()
	for option: String in STATUS_OPTIONS:
		_status_filter.add_item(option)


# ========== リスト構築 ==========

## フィルタ条件に基づいてリストを再構築する
func _rebuild_list() -> void:
	# 既存の項目を全て削除する
	_current_items.clear()
	for child: Node in _list_container.get_children():
		child.queue_free()
	# 全実績定義を取得する
	var all_defs: Array[AchievementDefinition] = AchievementManager.get_all_definitions()
	# フィルタ条件を取得する
	var cat_idx: int = _category_filter.selected
	var status_idx: int = _status_filter.selected
	# フィルタを適用する
	var filtered: Array[AchievementDefinition] = _apply_filters(all_defs, cat_idx, status_idx)
	# おすすめセクションを構築する（フィルタが「全て/全て」の場合のみ表示）
	if cat_idx == 0 and status_idx == 0:
		var recommended: Array[AchievementDefinition] = _get_recommendations(all_defs)
		if not recommended.is_empty():
			_add_section_label("-- おすすめ --")
			for def: AchievementDefinition in recommended:
				_add_list_item(def)
			_add_section_label("-- すべての実績 --")
	# フィルタ済みリストを構築する
	for def: AchievementDefinition in filtered:
		_add_list_item(def)
	# リストが空の場合はメッセージを表示する
	if filtered.is_empty():
		var empty: Label = Label.new()
		empty.text = "該当する実績がありません"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 11)
		_list_container.add_child(empty)


## フィルタ条件を適用して実績定義を絞り込む
func _apply_filters(
	defs: Array[AchievementDefinition],
	cat_idx: int,
	status_idx: int
) -> Array[AchievementDefinition]:
	var result: Array[AchievementDefinition] = []
	for def: AchievementDefinition in defs:
		# カテゴリフィルタ（0=全て、1=COMBAT, 2=FARMING, ...）
		if cat_idx > 0 and def.category != (cat_idx - 1):
			continue
		# ステータスフィルタ（0=全て、1=未達成、2=達成済）
		var is_unlocked: bool = AchievementManager.get_progress(def.id).get("unlocked", false)
		if status_idx == 1 and is_unlocked:
			continue
		if status_idx == 2 and not is_unlocked:
			continue
		result.append(def)
	return result


## リストにセクション区切りラベルを追加する
func _add_section_label(text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", SECTION_LABEL_COLOR)
	_list_container.add_child(label)


## リストに1件のアイテムを追加する
func _add_list_item(def: AchievementDefinition) -> void:
	var item: AchievementListItem = LIST_ITEM_SCENE.instantiate() as AchievementListItem
	_list_container.add_child(item)
	# 実績データを設定する
	item.setup(def)
	# 選択シグナルを接続する
	item.item_selected.connect(_on_item_selected)
	_current_items.append(item)
	# 選択状態を復元する
	if _selected_def != null and def.id == _selected_def.id:
		item.set_selected(true)


# ========== おすすめ機能 ==========

## おすすめ実績を算出する（達成率が高い未解除実績をカテゴリ分散で最大3件）
func _get_recommendations(
	all_defs: Array[AchievementDefinition]
) -> Array[AchievementDefinition]:
	# 未解除かつ進捗ありの実績を候補として収集する
	var candidates: Array[Dictionary] = []
	for def: AchievementDefinition in all_defs:
		var progress: Dictionary = AchievementManager.get_progress(def.id)
		if progress.get("unlocked", false):
			continue
		var current: int = progress.get("current", 0)
		var target: int = progress.get("target", 1)
		# target が 0 以下の場合は除外する
		if target <= 0:
			continue
		# 進捗 0 の実績は除外する（「もう少しで達成」が主旨）
		if current <= 0:
			continue
		var ratio: float = float(current) / float(target)
		candidates.append({"def": def, "ratio": ratio})
	# 達成率の降順でソートする
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["ratio"] > b["ratio"]
	)
	# カテゴリ分散で最大 RECOMMEND_COUNT 件を選出する
	var result: Array[AchievementDefinition] = []
	var used_categories: Array[int] = []
	# 第1パス: 各カテゴリから1件ずつ選出する
	for entry: Dictionary in candidates:
		if result.size() >= RECOMMEND_COUNT:
			break
		var def: AchievementDefinition = entry["def"] as AchievementDefinition
		if def.category not in used_categories:
			result.append(def)
			used_categories.append(def.category)
	# 第2パス: まだ枠が余っていれば残りから充填する
	if result.size() < RECOMMEND_COUNT:
		for entry: Dictionary in candidates:
			if result.size() >= RECOMMEND_COUNT:
				break
			var def: AchievementDefinition = entry["def"] as AchievementDefinition
			if def not in result:
				result.append(def)
	return result


# ========== 詳細パネル ==========

## 詳細パネルに実績情報を表示する
func _show_detail(def: AchievementDefinition) -> void:
	# 空表示ラベルを非表示にする
	_empty_label.visible = false
	# 詳細内容を表示する
	_detail_rank_label.visible = true
	_detail_name_label.visible = true
	_detail_desc_label.visible = true
	_progress_container.visible = true
	_ap_label.visible = true
	_pin_button.visible = true
	# ランク表示
	_detail_rank_label.text = AchievementListItem.RANK_LABELS[def.rank]
	_detail_rank_label.add_theme_color_override(
		"font_color", AchievementListItem.RANK_COLORS[def.rank]
	)
	# 名前
	_detail_name_label.text = def.name_ja
	# 説明
	_detail_desc_label.text = def.description_ja
	# 進捗
	var progress: Dictionary = AchievementManager.get_progress(def.id)
	var current: int = progress.get("current", 0)
	var target: int = progress.get("target", 1)
	var is_unlocked: bool = progress.get("unlocked", false)
	_progress_label.text = "進捗: %d / %d" % [current, target]
	_progress_bar.max_value = target
	_progress_bar.value = mini(current, target)
	# AP報酬
	_ap_label.text = "報酬: %d AP" % def.ap
	# ピン留めボタンの状態を更新する
	_update_pin_button(def, is_unlocked)


## 詳細パネルを空表示にする（実績未選択時）
func _show_empty_detail() -> void:
	_empty_label.visible = true
	_detail_rank_label.visible = false
	_detail_name_label.visible = false
	_detail_desc_label.visible = false
	_progress_container.visible = false
	_ap_label.visible = false
	_pin_button.visible = false


## ピン留めボタンの表示と有効/無効を更新する
func _update_pin_button(def: AchievementDefinition, is_unlocked: bool) -> void:
	var is_pinned: bool = AchievementManager.is_pinned(def.id)
	if is_pinned:
		# ピン留め中 — 解除可能
		_pin_button.text = "ピン解除"
		_pin_button.disabled = false
	elif is_unlocked:
		# 達成済み — ピン留め不可
		_pin_button.text = "達成済み"
		_pin_button.disabled = true
	elif AchievementManager.get_pinned_ids().size() >= AchievementManager.MAX_PIN_COUNT:
		# 上限到達 — ピン留め不可
		_pin_button.text = "ピン留め (上限)"
		_pin_button.disabled = true
	else:
		# ピン留め可能
		_pin_button.text = "ピン留め"
		_pin_button.disabled = false


# ========== シグナルハンドラ ==========

## リスト項目が選択されたときのコールバック
func _on_item_selected(def: AchievementDefinition) -> void:
	_selected_def = def
	# 全項目の選択状態をリセットし、選択された項目だけ選択状態にする
	for item: AchievementListItem in _current_items:
		item.set_selected(item.get_definition().id == def.id)
	# 詳細パネルを更新する
	_show_detail(def)


## フィルタが変更されたときのコールバック
func _on_filter_changed(_index: int) -> void:
	_rebuild_list()


## ピン留めボタンが押されたときのコールバック
func _on_pin_button_pressed() -> void:
	if _selected_def == null:
		return
	# ピン留め状態をトグルする
	if AchievementManager.is_pinned(_selected_def.id):
		AchievementManager.unpin_achievement(_selected_def.id)
	else:
		AchievementManager.pin_achievement(_selected_def.id)


## ピン留め状態が変更されたときのコールバック
func _on_pinned_changed() -> void:
	# リストを再構築してピンアイコンを更新する
	_rebuild_list()
	# 詳細パネルも更新する
	if _selected_def != null:
		_show_detail(_selected_def)


## 実績が解除されたときのコールバック
func _on_achievement_unlocked(
	_id: StringName, _definition: AchievementDefinition
) -> void:
	# リストと詳細を更新する
	_rebuild_list()
	if _selected_def != null:
		_show_detail(_selected_def)


## 進捗が更新されたときのコールバック
func _on_progress_updated(
	id: StringName, _current: int, _target: int
) -> void:
	# 選択中の実績の進捗が変わった場合のみ詳細パネルを更新する
	if _selected_def != null and _selected_def.id == id:
		_show_detail(_selected_def)
	# リスト項目のステータス表示も更新する（対象項目のみ）
	for item: AchievementListItem in _current_items:
		if item.get_definition().id == id:
			item.setup(item.get_definition())
			break


## タブの表示状態が変わったときのコールバック
func _on_visibility_changed() -> void:
	# 可視状態になったときにリストを最新化する
	if visible:
		_rebuild_list()
		# 選択中の実績の詳細も更新する
		if _selected_def != null:
			_show_detail(_selected_def)
