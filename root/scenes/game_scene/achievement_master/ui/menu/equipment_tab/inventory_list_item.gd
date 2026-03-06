## バッグ内アイテム1行を表示するリスト項目
## アイテム名と数量を表示し、クリックで選択シグナルを発火する
class_name InventoryListItem extends PanelContainer

## この項目が選択されたときに発火する
signal item_selected(def: ItemDefinition)

## 選択時の背景色
const SELECTED_COLOR: Color = Color(0.3, 0.5, 0.7, 0.4)
## 通常時の背景色
const NORMAL_COLOR: Color = Color(0.15, 0.15, 0.15, 0.3)

## この項目が表すアイテム定義
var _definition: ItemDefinition = null
## 選択状態
var _is_selected: bool = false

# ---- ノードキャッシュ ----
## アイテム名ラベル
@onready var _name_label: Label = %NameLabel
## 数量ラベル
@onready var _count_label: Label = %CountLabel
## 背景用 StyleBoxFlat
var _style: StyleBoxFlat = null


## 初期化
func _ready() -> void:
	# 背景スタイルを作成する
	_style = StyleBoxFlat.new()
	_style.bg_color = NORMAL_COLOR
	_style.set_corner_radius_all(4)
	add_theme_stylebox_override("panel", _style)


## アイテムデータを設定する
func setup(def: ItemDefinition, count: int) -> void:
	_definition = def
	_name_label.text = def.name_ja
	_count_label.text = "x%d" % count


## 数量のみ更新する
func update_count(count: int) -> void:
	_count_label.text = "x%d" % count


## 選択状態を設定する
func set_selected(selected: bool) -> void:
	_is_selected = selected
	if _style != null:
		_style.bg_color = SELECTED_COLOR if selected else NORMAL_COLOR


## アイテム定義を返す
func get_definition() -> ItemDefinition:
	return _definition


## GUI 入力処理 — クリックで選択シグナルを発火する
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			item_selected.emit(_definition)
