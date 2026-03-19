## ショップ購入タブ用のリスト項目 — アイテム名と価格を表示する
class_name ShopListItem extends PanelContainer

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
@onready var _icon_rect: TextureRect = %IconRect
@onready var _name_label: Label = %NameLabel
@onready var _price_label: Label = %PriceLabel

## 背景用 StyleBoxFlat
var _style: StyleBoxFlat = null


func _ready() -> void:
	_style = StyleBoxFlat.new()
	_style.bg_color = NORMAL_COLOR
	_style.set_corner_radius_all(4)
	add_theme_stylebox_override("panel", _style)


## アイテムデータと価格を設定する
func setup(def: ItemDefinition, price: int) -> void:
	_definition = def
	_icon_rect.texture = def.icon
	_name_label.text = def.name_ja
	_price_label.text = "%dG" % price


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
