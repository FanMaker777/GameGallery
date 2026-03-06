## 装備スロット1枠を表示するパネル
## スロット名と装備中アイテム名を表示し、クリックで選択シグナルを発火する
class_name EquipSlotPanel extends PanelContainer

## スロットがクリックされたときに発火する
signal slot_selected(slot: EquipmentDefinition.EquipSlot)

## このパネルが担当する装備スロット
var _slot: EquipmentDefinition.EquipSlot = EquipmentDefinition.EquipSlot.WEAPON

# ---- ノードキャッシュ ----
## スロット名ラベル（武器/防具/装飾）
@onready var _slot_name_label: Label = %SlotNameLabel
## 装備中アイテム名ラベル
@onready var _item_name_label: Label = %ItemNameLabel

## スロット名の日本語マッピング
const SLOT_NAMES: Dictionary = {
	EquipmentDefinition.EquipSlot.WEAPON: "武器",
	EquipmentDefinition.EquipSlot.ARMOR: "防具",
	EquipmentDefinition.EquipSlot.ACCESSORY: "装飾",
}


## スロットとデータを設定する
func setup(slot: EquipmentDefinition.EquipSlot) -> void:
	_slot = slot
	_slot_name_label.text = SLOT_NAMES.get(slot, "???")
	refresh()


## 表示を最新の装備状態に更新する
func refresh() -> void:
	var equipped_id: StringName = InventoryManager.get_equipped(_slot)
	if equipped_id == &"":
		# 未装備
		_item_name_label.text = "---"
		_item_name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	else:
		# 装備中アイテムの名前を表示する
		var def: ItemDefinition = InventoryManager.get_definition(equipped_id)
		_item_name_label.text = def.name_ja if def != null else str(equipped_id)
		_item_name_label.remove_theme_color_override("font_color")


## GUI 入力処理 — クリックで選択シグナルを発火する
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			slot_selected.emit(_slot)


## このパネルのスロットを返す
func get_slot() -> EquipmentDefinition.EquipSlot:
	return _slot
