## ショップUI — 購入・売却タブを持つオーバーレイUIパネル
## NPC インタラクションで開き、ESC で閉じる
class_name ShopUI extends CanvasLayer

## ショップが閉じたときに発火する
signal shop_closed

# ---- 定数 ----
const SHOP_LIST_ITEM_SCENE: PackedScene = preload(
	"res://root/scenes/game_scene/achievement_master/ui/shop/shop_list_item.tscn"
)
const INV_LIST_ITEM_SCENE: PackedScene = preload(
	"res://root/scenes/game_scene/achievement_master/ui/menu/equipment_tab/inventory_list_item.tscn"
)

## 売却タブ用カテゴリフィルタの選択肢
const SELL_FILTER_OPTIONS: Array[String] = ["全て", "装備品", "消耗品", "素材"]

# ---- データ ----
var _shop_inventory: ShopInventory = preload(
	"res://root/scenes/game_scene/achievement_master/data/item/shop_inventory.tres"
)

# ---- ノードキャッシュ ----
@onready var _gold_label: Label = %GoldLabel
@onready var _tab_container: TabContainer = %TabContainer
# 購入タブ
@onready var _buy_list_container: VBoxContainer = %BuyListContainer
@onready var _buy_detail_content: VBoxContainer = %BuyDetailContent
@onready var _buy_empty_label: Label = %BuyEmptyLabel
@onready var _buy_icon_rect: TextureRect = %BuyIconRect
@onready var _buy_name_label: Label = %BuyNameLabel
@onready var _buy_desc_label: Label = %BuyDescLabel
@onready var _buy_stats_label: Label = %BuyStatsLabel
@onready var _buy_price_label: Label = %BuyPriceLabel
@onready var _buy_button: Button = %BuyButton
# 売却タブ
@onready var _sell_filter: OptionButton = %SellCategoryFilter
@onready var _sell_list_container: VBoxContainer = %SellListContainer
@onready var _sell_detail_content: VBoxContainer = %SellDetailContent
@onready var _sell_empty_label: Label = %SellEmptyLabel
@onready var _sell_icon_rect: TextureRect = %SellIconRect
@onready var _sell_name_label: Label = %SellNameLabel
@onready var _sell_desc_label: Label = %SellDescLabel
@onready var _sell_stats_label: Label = %SellStatsLabel
@onready var _sell_price_label: Label = %SellPriceLabel
@onready var _sell_button: Button = %SellButton

# ---- 状態 ----
var _is_open: bool = false
var _buy_selected_def: ItemDefinition = null
var _sell_selected_def: ItemDefinition = null
var _buy_items: Array[ShopListItem] = []
var _sell_items: Array[InventoryListItem] = []


func _ready() -> void:
	visible = false
	# 売却フィルタの選択肢を設定する
	_sell_filter.clear()
	for option: String in SELL_FILTER_OPTIONS:
		_sell_filter.add_item(option)
	# シグナル接続
	_sell_filter.item_selected.connect(_on_sell_filter_changed)
	_buy_button.pressed.connect(_on_buy_pressed)
	_sell_button.pressed.connect(_on_sell_pressed)
	InventoryManager.gold_changed.connect(_on_gold_changed)
	InventoryManager.bag_changed.connect(_on_bag_changed)


## ショップを開く
func open_shop() -> void:
	if _is_open:
		return
	_is_open = true
	visible = true
	_gold_label.text = "%d G" % InventoryManager.get_gold()
	_tab_container.current_tab = 0
	_rebuild_buy_list()
	_rebuild_sell_list()
	_show_buy_empty()
	_show_sell_empty()
	# OverlayController にショップ中であることを通知する
	var oc: OverlayController = _get_overlay_controller()
	if oc != null:
		oc.set_shop_open(true)


## ショップを閉じる
func close_shop() -> void:
	if not _is_open:
		return
	_is_open = false
	visible = false
	_buy_selected_def = null
	_sell_selected_def = null
	var oc: OverlayController = _get_overlay_controller()
	if oc != null:
		oc.set_shop_open(false)
	shop_closed.emit()


## ESC でショップを閉じる
func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event.is_action_pressed("ESC"):
		close_shop()
		get_viewport().set_input_as_handled()


# ========== 購入タブ ==========

## 購入リストを構築する
func _rebuild_buy_list() -> void:
	_buy_items.clear()
	for child: Node in _buy_list_container.get_children():
		child.queue_free()
	for item_id: StringName in _shop_inventory.item_ids:
		var def: ItemDefinition = InventoryManager.get_definition(item_id)
		if def == null or def.buy_price <= 0:
			continue
		var price: int = _get_discounted_price(def.buy_price)
		var item: ShopListItem = SHOP_LIST_ITEM_SCENE.instantiate() as ShopListItem
		_buy_list_container.add_child(item)
		item.setup(def, price)
		item.item_selected.connect(_on_buy_item_selected)
		_buy_items.append(item)
		if _buy_selected_def != null and def.id == _buy_selected_def.id:
			item.set_selected(true)


## 購入タブのアイテム選択コールバック
func _on_buy_item_selected(def: ItemDefinition) -> void:
	_buy_selected_def = def
	for item: ShopListItem in _buy_items:
		item.set_selected(item.get_definition().id == def.id)
	_show_buy_detail(def)


## 購入タブの詳細パネルを表示する
func _show_buy_detail(def: ItemDefinition) -> void:
	_buy_empty_label.visible = false
	_buy_detail_content.visible = true
	_buy_icon_rect.texture = def.icon
	_buy_icon_rect.visible = def.icon != null
	_buy_name_label.text = def.name_ja
	_buy_desc_label.text = def.description_ja
	_buy_stats_label.text = _build_stats_text(def)
	var price: int = _get_discounted_price(def.buy_price)
	_buy_price_label.text = "価格: %dG" % price
	_buy_button.disabled = InventoryManager.get_gold() < price


## 購入タブの詳細パネルを空にする
func _show_buy_empty() -> void:
	_buy_empty_label.visible = true
	_buy_detail_content.visible = false
	_buy_selected_def = null


## 購入ボタン押下
func _on_buy_pressed() -> void:
	if _buy_selected_def == null:
		return
	var price: int = _get_discounted_price(_buy_selected_def.buy_price)
	if not InventoryManager.remove_gold(price):
		return
	if not InventoryManager.add_item(_buy_selected_def.id):
		# スタック上限でアイテム追加に失敗した場合はゴールドを返金する
		InventoryManager.add_gold(price)
		Log.info("ShopUI: スタック上限のため購入キャンセル — %s" % _buy_selected_def.id)
		return
	Log.info("ShopUI: 購入 %s (-%dG)" % [_buy_selected_def.id, price])
	# 詳細パネルを更新する（ゴールド残高によるボタン状態更新）
	_show_buy_detail(_buy_selected_def)


# ========== 売却タブ ==========

## 売却リストを構築する
func _rebuild_sell_list() -> void:
	_sell_items.clear()
	for child: Node in _sell_list_container.get_children():
		child.queue_free()
	var bag: Dictionary = InventoryManager.get_bag_contents()
	var filter_idx: int = _sell_filter.selected
	for id: StringName in bag:
		var def: ItemDefinition = InventoryManager.get_definition(id)
		if def == null or def.sell_price <= 0:
			continue
		if not _passes_sell_filter(def, filter_idx):
			continue
		var count: int = bag[id]
		var item: InventoryListItem = INV_LIST_ITEM_SCENE.instantiate() as InventoryListItem
		_sell_list_container.add_child(item)
		item.setup(def, count)
		item.item_selected.connect(_on_sell_item_selected)
		_sell_items.append(item)
		if _sell_selected_def != null and def.id == _sell_selected_def.id:
			item.set_selected(true)
	if _sell_items.is_empty():
		var empty: Label = Label.new()
		empty.text = "売却可能なアイテムがありません"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 11)
		_sell_list_container.add_child(empty)


## 売却フィルタの判定
func _passes_sell_filter(def: ItemDefinition, filter_idx: int) -> bool:
	match filter_idx:
		0: return true
		1: return def.get_category() == ItemDefinition.Category.EQUIPMENT
		2: return def.get_category() == ItemDefinition.Category.CONSUMABLE
		3: return def.get_category() == ItemDefinition.Category.MATERIAL
		_: return true


## 売却フィルタ変更コールバック
func _on_sell_filter_changed(_index: int) -> void:
	_sell_selected_def = null
	_show_sell_empty()
	_rebuild_sell_list()


## 売却タブのアイテム選択コールバック
func _on_sell_item_selected(def: ItemDefinition) -> void:
	_sell_selected_def = def
	for item: InventoryListItem in _sell_items:
		item.set_selected(item.get_definition().id == def.id)
	_show_sell_detail(def)


## 売却タブの詳細パネルを表示する
func _show_sell_detail(def: ItemDefinition) -> void:
	_sell_empty_label.visible = false
	_sell_detail_content.visible = true
	_sell_icon_rect.texture = def.icon
	_sell_icon_rect.visible = def.icon != null
	_sell_name_label.text = def.name_ja
	_sell_desc_label.text = def.description_ja
	_sell_stats_label.text = _build_stats_text(def)
	_sell_price_label.text = "売却額: %dG" % def.sell_price
	_sell_button.disabled = not InventoryManager.has_item(def.id)


## 売却タブの詳細パネルを空にする
func _show_sell_empty() -> void:
	_sell_empty_label.visible = true
	_sell_detail_content.visible = false
	_sell_selected_def = null


## 売却ボタン押下
func _on_sell_pressed() -> void:
	if _sell_selected_def == null:
		return
	if not InventoryManager.remove_item(_sell_selected_def.id):
		return
	InventoryManager.add_gold(_sell_selected_def.sell_price)
	Log.info("ShopUI: 売却 %s (+%dG)" % [_sell_selected_def.id, _sell_selected_def.sell_price])
	# 売却後にリストを更新する
	_rebuild_sell_list()
	# 売却したアイテムがまだバッグにあるか確認する
	if InventoryManager.has_item(_sell_selected_def.id):
		_show_sell_detail(_sell_selected_def)
	else:
		_show_sell_empty()


# ========== 共通ヘルパー ==========

## スキル効果による店割引を適用した価格を返す
func _get_discounted_price(base_price: int) -> int:
	var discount: float = SkillManager.get_effect_cache().shop_discount
	var final_price: int = int(base_price * (1.0 - discount / 100.0))
	return maxi(final_price, 1)


## ステータス効果テキストを構築する（EquipmentTab と同パターン）
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


## ゴールド変化時のコールバック
func _on_gold_changed(new_amount: int) -> void:
	if _is_open:
		_gold_label.text = "%d G" % new_amount
		# 購入タブの詳細パネルを更新する（ボタンの有効/無効を再計算）
		if _buy_selected_def != null:
			_show_buy_detail(_buy_selected_def)


## バッグ変化時のコールバック
func _on_bag_changed(_id: StringName, _new_count: int) -> void:
	if _is_open:
		_rebuild_sell_list()


## OverlayController を取得するヘルパー
func _get_overlay_controller() -> OverlayController:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null:
		return null
	return gm.get_node_or_null("%OverlayController") as OverlayController
