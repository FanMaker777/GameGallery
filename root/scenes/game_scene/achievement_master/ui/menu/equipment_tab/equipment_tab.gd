## 装備タブの本体 — 左に装備スロット＋バッグリスト、右に詳細パネルを表示する
## InventoryManager のアイテム管理を UI から操作するためのタブ
class_name EquipmentTab extends MarginContainer

# ---- 定数 ----
## リスト項目シーン（.tscn に UID 未割当のため res:// を使用）
const LIST_ITEM_SCENE: PackedScene = preload(
	"res://root/scenes/game_scene/achievement_master/ui/menu/equipment_tab/inventory_list_item.tscn"
)

## カテゴリフィルタの選択肢（index 0 = 全て）
const FILTER_OPTIONS: Array[String] = ["全て", "装備品", "消耗品", "素材"]

# ---- ノードキャッシュ（左パネル：装備スロット） ----
## 武器スロットパネル
@onready var _weapon_slot: EquipSlotPanel = %WeaponSlot
## 防具スロットパネル
@onready var _armor_slot: EquipSlotPanel = %ArmorSlot
## アクセサリスロットパネル
@onready var _accessory_slot: EquipSlotPanel = %AccessorySlot

# ---- ノードキャッシュ（左パネル：バッグリスト） ----
## カテゴリフィルタ
@onready var _category_filter: OptionButton = %CategoryFilter
## リスト項目のコンテナ
@onready var _list_container: VBoxContainer = %ListContainer

# ---- ノードキャッシュ（右パネル：詳細） ----
## アイコン
@onready var _detail_icon_rect: TextureRect = %DetailIconRect
## アイテム名ラベル
@onready var _detail_name_label: Label = %DetailNameLabel
## 説明ラベル
@onready var _detail_desc_label: Label = %DetailDescLabel
## ステータス効果ラベル
@onready var _detail_stats_label: Label = %DetailStatsLabel
## アクションボタン（装備/使用/外す）
@onready var _action_button: Button = %ActionButton
## 未選択時の案内ラベル
@onready var _empty_label: Label = %EmptyLabel
## 詳細コンテンツのコンテナ
@onready var _detail_content: VBoxContainer = %DetailContent

# ---- 状態 ----
## 現在選択中のアイテム定義
var _selected_def: ItemDefinition = null
## 装備スロットから選択されたかどうか（外す操作用）
var _selected_from_slot: bool = false
## 選択中のスロット（スロット選択時のみ有効）
var _selected_slot: EquipmentDefinition.EquipSlot = EquipmentDefinition.EquipSlot.WEAPON
## 現在表示中のリスト項目への参照
var _current_items: Array[InventoryListItem] = []


## 初期化処理 — スロット設定・フィルタ設定・シグナル接続・リスト構築を行う
func _ready() -> void:
	# 装備スロットを初期化する
	_weapon_slot.setup(EquipmentDefinition.EquipSlot.WEAPON)
	_armor_slot.setup(EquipmentDefinition.EquipSlot.ARMOR)
	_accessory_slot.setup(EquipmentDefinition.EquipSlot.ACCESSORY)
	# 装備スロットの選択シグナルを接続する
	_weapon_slot.slot_selected.connect(_on_slot_selected)
	_armor_slot.slot_selected.connect(_on_slot_selected)
	_accessory_slot.slot_selected.connect(_on_slot_selected)
	# フィルタの選択肢を設定する
	_setup_filters()
	# フィルタ変更シグナルを接続する
	_category_filter.item_selected.connect(_on_filter_changed)
	# アクションボタンのシグナルを接続する
	_action_button.pressed.connect(_on_action_button_pressed)
	# タブ表示切替時にリストを更新する
	visibility_changed.connect(_on_visibility_changed)
	# InventoryManager のシグナルを接続する
	InventoryManager.bag_changed.connect(_on_bag_changed)
	InventoryManager.equipment_changed.connect(_on_equipment_changed)
	# 初期状態: 詳細パネルを空表示にする
	_show_empty_detail()
	# リストを構築する
	_rebuild_list()


## フィルタ OptionButton の選択肢を設定する
func _setup_filters() -> void:
	_category_filter.clear()
	for option: String in FILTER_OPTIONS:
		_category_filter.add_item(option)


# ========== リスト構築 ==========

## フィルタ条件に基づいてリストを再構築する
func _rebuild_list() -> void:
	# 既存の項目を全て削除する
	_current_items.clear()
	for child: Node in _list_container.get_children():
		child.queue_free()
	# バッグ内容を取得する
	var bag: Dictionary = InventoryManager.get_bag_contents()
	# フィルタ条件を取得する
	var filter_idx: int = _category_filter.selected
	# バッグ内の各アイテムを表示する
	for id: StringName in bag:
		var def: ItemDefinition = InventoryManager.get_definition(id)
		if def == null:
			continue
		# フィルタ適用
		if not _passes_filter(def, filter_idx):
			continue
		var count: int = bag[id]
		_add_list_item(def, count)
	# リストが空の場合はメッセージを表示する
	if _current_items.is_empty():
		var empty: Label = Label.new()
		empty.text = "アイテムがありません"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 11)
		_list_container.add_child(empty)


## アイテムがフィルタ条件を通過するかを判定する
func _passes_filter(def: ItemDefinition, filter_idx: int) -> bool:
	match filter_idx:
		0:
			# 全て
			return true
		1:
			# 装備品
			return def.get_category() == ItemDefinition.Category.EQUIPMENT
		2:
			# 消耗品
			return def.get_category() == ItemDefinition.Category.CONSUMABLE
		3:
			# 素材
			return def.get_category() == ItemDefinition.Category.MATERIAL
		_:
			return true


## リストに1件のアイテム項目を追加する
func _add_list_item(def: ItemDefinition, count: int) -> void:
	var item: InventoryListItem = LIST_ITEM_SCENE.instantiate() as InventoryListItem
	_list_container.add_child(item)
	# アイテムデータを設定する
	item.setup(def, count)
	# 選択シグナルを接続する
	item.item_selected.connect(_on_item_selected)
	_current_items.append(item)
	# 選択状態を復元する
	if _selected_def != null and not _selected_from_slot and def.id == _selected_def.id:
		item.set_selected(true)


# ========== 詳細パネル ==========

## 詳細パネルにアイテム情報を表示する
func _show_detail(def: ItemDefinition) -> void:
	# 空表示を非表示にする
	_empty_label.visible = false
	# 詳細コンテンツを表示する
	_detail_content.visible = true
	# アイコン
	_detail_icon_rect.texture = def.icon
	_detail_icon_rect.visible = def.icon != null
	# アイテム名
	_detail_name_label.text = def.name_ja
	# 説明
	_detail_desc_label.text = def.description_ja
	# ステータス効果
	_detail_stats_label.text = _build_stats_text(def)
	# アクションボタンの状態更新
	_update_action_button(def)


## 詳細パネルを空表示にする（アイテム未選択時）
func _show_empty_detail() -> void:
	_empty_label.visible = true
	_detail_content.visible = false


## アイテムのステータス効果テキストを構築する
func _build_stats_text(def: ItemDefinition) -> String:
	var parts: PackedStringArray = []
	if def is EquipmentDefinition:
		var eq: EquipmentDefinition = def as EquipmentDefinition
		if eq.hp_flat != 0:
			parts.append("HP +%d" % eq.hp_flat)
		if eq.attack_flat != 0:
			parts.append("攻撃力 +%d" % eq.attack_flat)
		if eq.speed_percent != 0.0:
			parts.append("移動速度 +%.0f%%" % eq.speed_percent)
		if eq.stamina_flat != 0.0:
			parts.append("スタミナ +%.0f" % eq.stamina_flat)
		if eq.gather_percent != 0.0:
			parts.append("採取速度 +%.0f%%" % eq.gather_percent)
	elif def is ConsumableDefinition:
		var cs: ConsumableDefinition = def as ConsumableDefinition
		match cs.effect_type:
			ConsumableDefinition.EffectType.HP_RECOVER:
				parts.append("HP回復 +%.0f" % cs.effect_value)
			ConsumableDefinition.EffectType.STAMINA_RECOVER:
				parts.append("スタミナ回復 +%.0f" % cs.effect_value)
	if parts.is_empty():
		return "効果: なし"
	return "効果: %s" % ", ".join(parts)


## アクションボタンの表示と機能を更新する
func _update_action_button(def: ItemDefinition) -> void:
	if _selected_from_slot:
		# 装備スロットからの選択 → 「外す」ボタン
		_action_button.text = "外す"
		_action_button.disabled = false
	elif def is EquipmentDefinition:
		# バッグの装備品 → 「装備する」ボタン
		_action_button.text = "装備する"
		_action_button.disabled = false
	elif def is ConsumableDefinition:
		# 消耗品 → 「使用する」ボタン
		_action_button.text = "使用する"
		_action_button.disabled = not InventoryManager.has_item(def.id)
	else:
		# 素材 → ボタン無効
		_action_button.text = "---"
		_action_button.disabled = true


# ========== 装備スロット更新 ==========

## 全装備スロットパネルの表示を更新する
func _refresh_slots() -> void:
	_weapon_slot.refresh()
	_armor_slot.refresh()
	_accessory_slot.refresh()


# ========== シグナルハンドラ ==========

## バッグ内アイテムが選択されたときのコールバック
func _on_item_selected(def: ItemDefinition) -> void:
	_selected_def = def
	_selected_from_slot = false
	# 全項目の選択状態をリセットし、選択された項目だけ選択状態にする
	for item: InventoryListItem in _current_items:
		item.set_selected(item.get_definition().id == def.id)
	# 詳細パネルを更新する
	_show_detail(def)


## 装備スロットが選択されたときのコールバック
func _on_slot_selected(slot: EquipmentDefinition.EquipSlot) -> void:
	var equipped_id: StringName = InventoryManager.get_equipped(slot)
	if equipped_id == &"":
		return
	var def: ItemDefinition = InventoryManager.get_definition(equipped_id)
	if def == null:
		return
	_selected_def = def
	_selected_from_slot = true
	_selected_slot = slot
	# バッグリストの選択を解除する
	for item: InventoryListItem in _current_items:
		item.set_selected(false)
	# 詳細パネルを更新する
	_show_detail(def)


## フィルタが変更されたときのコールバック
func _on_filter_changed(_index: int) -> void:
	_rebuild_list()


## アクションボタンが押されたときのコールバック
func _on_action_button_pressed() -> void:
	if _selected_def == null:
		return
	if _selected_from_slot:
		# 装備を外す
		InventoryManager.unequip_item(_selected_slot)
		_selected_def = null
		_selected_from_slot = false
		_show_empty_detail()
	elif _selected_def is EquipmentDefinition:
		# 装備する
		InventoryManager.equip_item(_selected_def.id)
	elif _selected_def is ConsumableDefinition:
		# 使用する
		InventoryManager.use_item(_selected_def.id)
	# 選択中アイテムの詳細を更新する（リスト/スロットはシグナル経由で自動更新される）
	if _selected_def != null and not _selected_from_slot:
		_show_detail(_selected_def)


## バッグ内容が変化したときのコールバック
func _on_bag_changed(_id: StringName, _new_count: int) -> void:
	# タブが可視状態のときのみ更新する
	if visible:
		_rebuild_list()


## 装備が変更されたときのコールバック
func _on_equipment_changed(_slot: int) -> void:
	# タブが可視状態のときのみ更新する
	if visible:
		_refresh_slots()


## タブの表示状態が変わったときのコールバック
func _on_visibility_changed() -> void:
	# 可視状態になったときにリストとスロットを最新化する
	if visible:
		_rebuild_list()
		_refresh_slots()
		# 選択中のアイテムが有効か確認する
		if _selected_def != null:
			var current_def: ItemDefinition = InventoryManager.get_definition(_selected_def.id)
			if current_def == null:
				_selected_def = null
				_show_empty_detail()
			else:
				_show_detail(_selected_def)
