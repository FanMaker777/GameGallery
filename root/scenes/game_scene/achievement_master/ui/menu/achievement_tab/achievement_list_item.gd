## 実績リスト内の1行表示ノード
## ランクバッジ・実績名・ピンアイコン・ステータスを表示する
class_name AchievementListItem extends PanelContainer

# ---- シグナル ----
## この項目が選択されたときに発火する
signal item_selected(definition: AchievementDefinition)

# ---- 定数 ----
## ランクごとのラベル文字列
const RANK_LABELS: Dictionary = {
	AchievementDefinition.Rank.BRONZE: "[B]",
	AchievementDefinition.Rank.SILVER: "[S]",
	AchievementDefinition.Rank.GOLD: "[G]",
}
## ランクごとの表示色
const RANK_COLORS: Dictionary = {
	AchievementDefinition.Rank.BRONZE: Color(0.80, 0.50, 0.20),
	AchievementDefinition.Rank.SILVER: Color(0.75, 0.75, 0.75),
	AchievementDefinition.Rank.GOLD: Color(1.00, 0.84, 0.00),
}
## 選択時の背景色
const SELECTED_BG_COLOR: Color = Color(0.25, 0.25, 0.35, 0.8)
## 通常時の背景色
const NORMAL_BG_COLOR: Color = Color(0.15, 0.15, 0.20, 0.6)
## 達成済みテキスト色（薄くする）
const UNLOCKED_TEXT_COLOR: Color = Color(0.6, 0.6, 0.6, 0.8)

# ---- ノードキャッシュ ----
## ランクバッジラベル
@onready var _rank_label: Label = %RankLabel
## 実績名ラベル
@onready var _name_label: Label = %NameLabel
## ピン留めアイコンラベル
@onready var _pin_icon: Label = %PinIcon
## ステータス表示ラベル（達成/進捗）
@onready var _status_label: Label = %StatusLabel

# ---- 状態 ----
## この行が保持する実績定義
var _definition: AchievementDefinition = null
## 選択状態
var _is_selected: bool = false


## 実績定義からUIを構築する
func setup(definition: AchievementDefinition) -> void:
	_definition = definition
	# ランクバッジの設定
	_rank_label.text = RANK_LABELS[definition.rank]
	_rank_label.add_theme_color_override("font_color", RANK_COLORS[definition.rank])
	# 実績名の設定
	_name_label.text = definition.name_ja
	# 進捗情報の取得
	var progress: Dictionary = AchievementManager.get_progress(definition.id)
	var is_unlocked: bool = progress.get("unlocked", false)
	# ステータス表示の設定
	if is_unlocked:
		_status_label.text = "達成"
		_status_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
		# 達成済みは全体的に少し薄くする
		_name_label.add_theme_color_override("font_color", UNLOCKED_TEXT_COLOR)
	else:
		var current: int = progress.get("current", 0)
		var target: int = progress.get("target", 1)
		_status_label.text = "%d/%d" % [current, target]
		# 未達成時はデフォルト色に戻す
		_status_label.remove_theme_color_override("font_color")
		_name_label.remove_theme_color_override("font_color")
	# ピンアイコンの設定
	_pin_icon.text = "P" if AchievementManager.is_pinned(definition.id) else ""


## 選択状態を設定する
func set_selected(selected: bool) -> void:
	_is_selected = selected
	# 背景色の切り替え
	var style: StyleBoxFlat = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.bg_color = SELECTED_BG_COLOR if selected else NORMAL_BG_COLOR
	add_theme_stylebox_override("panel", style)


## この行が保持する実績定義を返す
func get_definition() -> AchievementDefinition:
	return _definition


## GUI入力イベントをハンドリングする（クリック選択）
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		# 左クリックで選択する
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			item_selected.emit(_definition)
