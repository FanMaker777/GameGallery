## 報酬リスト内の1行表示ノード
## 報酬名・APコスト・解放状態を表示し、状態に応じて背景色を切り替える
class_name RewardListItem extends PanelContainer

# ---- シグナル ----
## この項目が選択されたときに発火する
signal item_selected(definition: RewardDefinition)

# ---- 定数 ----
## 解放済みの背景色（緑系）
const UNLOCKED_BG_COLOR: Color = Color(0.15, 0.35, 0.15, 0.8)
## 解放可能の背景色（青系・目立つ）
const AVAILABLE_BG_COLOR: Color = Color(0.15, 0.25, 0.45, 0.9)
## 解放不能の背景色（暗いグレー）
const LOCKED_BG_COLOR: Color = Color(0.15, 0.15, 0.15, 0.5)

## 解放済みのテキスト色（明るい緑）
const UNLOCKED_TEXT_COLOR: Color = Color(0.5, 0.85, 0.5)
## 解放可能のテキスト色（白）
const AVAILABLE_TEXT_COLOR: Color = Color(1.0, 1.0, 1.0)
## 解放不能のテキスト色（薄いグレー）
const LOCKED_TEXT_COLOR: Color = Color(0.45, 0.45, 0.45)

## 選択時の背景色（青系ハイライト）
const SELECTED_BG_COLOR: Color = Color(0.25, 0.30, 0.45, 0.9)

## 解放可能のステータスラベル色（水色）
const AVAILABLE_STATUS_COLOR: Color = Color(0.4, 0.7, 1.0)

## ステータス表示文字列: 解放済み
const STATUS_UNLOCKED: String = "✓"
## ステータス表示文字列: 解放可能
const STATUS_AVAILABLE: String = "解放可"

# ---- ノードキャッシュ ----
## 報酬名ラベル
@onready var _name_label: Label = %NameLabel
## APコストラベル
@onready var _cost_label: Label = %CostLabel
## ステータス表示ラベル
@onready var _status_label: Label = %StatusLabel

# ---- 状態 ----
## この行が保持する報酬定義
var _definition: RewardDefinition = null
## 選択状態
var _is_selected: bool = false
## 現在の状態別背景色（選択解除時に戻すため保持）
var _state_bg_color: Color = LOCKED_BG_COLOR
## キャッシュされた StyleBoxFlat（毎回 duplicate しないため）
var _style_box: StyleBoxFlat = null


## StyleBoxFlat をキャッシュして背景色の切り替えを効率化する
func _ready() -> void:
	_style_box = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	add_theme_stylebox_override("panel", _style_box)


## 報酬定義からUIを構築する
func setup(definition: RewardDefinition) -> void:
	_definition = definition
	# 報酬名の設定
	_name_label.text = definition.name_ja
	# APコストの設定
	_cost_label.text = "%dAP" % definition.ap_cost
	# 状態判定と表示更新
	if RewardManager.is_unlocked(definition.id):
		# 解放済み（緑）
		_apply_state(UNLOCKED_BG_COLOR, UNLOCKED_TEXT_COLOR, STATUS_UNLOCKED)
	elif RewardManager.can_unlock(definition.id):
		# 解放可能（青・目立つ）
		_apply_state(AVAILABLE_BG_COLOR, AVAILABLE_TEXT_COLOR, STATUS_AVAILABLE)
	else:
		# 解放不能（AP不足 or 前提未充足）
		_apply_state(LOCKED_BG_COLOR, LOCKED_TEXT_COLOR, "")


## 状態に応じた背景色・テキスト色・ステータステキストを適用する
func _apply_state(bg_color: Color, text_color: Color, status_text: String) -> void:
	_state_bg_color = bg_color
	# テキスト色の設定
	_name_label.add_theme_color_override("font_color", text_color)
	_cost_label.add_theme_color_override("font_color", text_color)
	# ステータスラベルの設定
	_status_label.text = status_text
	if status_text == STATUS_UNLOCKED:
		_status_label.add_theme_color_override("font_color", UNLOCKED_TEXT_COLOR)
	elif status_text == STATUS_AVAILABLE:
		_status_label.add_theme_color_override("font_color", AVAILABLE_STATUS_COLOR)
	else:
		_status_label.add_theme_color_override("font_color", LOCKED_TEXT_COLOR)
	# 背景色の更新（選択中でなければ状態色を適用する）
	if not _is_selected:
		_update_bg(_state_bg_color)


## 選択状態を設定する
func set_selected(selected: bool) -> void:
	_is_selected = selected
	# 背景色の切り替え
	_update_bg(SELECTED_BG_COLOR if selected else _state_bg_color)


## この行が保持する報酬定義を返す
func get_definition() -> RewardDefinition:
	return _definition


## 背景色を更新する（キャッシュ済み StyleBoxFlat の色を変更するだけ）
func _update_bg(color: Color) -> void:
	_style_box.bg_color = color


## GUI入力イベントをハンドリングする（クリック選択）
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		# 左クリックで選択する
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			item_selected.emit(_definition)
