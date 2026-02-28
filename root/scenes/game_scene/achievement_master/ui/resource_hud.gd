## リソース・HP表示HUD — Pawn のインベントリ変化とHP変化をUIに反映する
class_name ResourceHud extends CanvasLayer


## HPバー
@onready var _hp_bar: ProgressBar = %HpBar
## リソースラベル群
@onready var _wood_label: Label = %WoodLabel
@onready var _gold_label: Label = %GoldLabel
@onready var _meat_label: Label = %MeatLabel

## Pawn への参照キャッシュ（毎回検索しない）
var _pawn: Node = null

## リソース種別とラベルの対応マッピング
var _label_map: Dictionary = {}


## 初期化 — Pawn へのシグナル接続を遅延実行する
func _ready() -> void:
	# Pawn が先に _ready される保証がないため遅延接続する
	_connect_to_pawn.call_deferred()
	_refresh_all()


## Pawn のシグナルを購読し、参照をキャッシュする
func _connect_to_pawn() -> void:
	_pawn = get_tree().get_first_node_in_group("player")
	if _pawn == null:
		return
	# ラベルマッピングを構築（種別 → ラベル + 表示名）
	_label_map = {
		ResourceDefinitions.ResourceType.WOOD: { "label": _wood_label, "name": "Wood" },
		ResourceDefinitions.ResourceType.GOLD: { "label": _gold_label, "name": "Gold" },
		ResourceDefinitions.ResourceType.MEAT: { "label": _meat_label, "name": "Meat" },
	}
	# インベントリ変化シグナルを接続
	if _pawn.has_signal("inventory_changed"):
		_pawn.inventory_changed.connect(_on_inventory_changed)
	# HP変化シグナルを接続
	if _pawn.has_signal("health_changed"):
		_pawn.health_changed.connect(_on_health_changed)
	Log.info("ResourceHud: Pawn に接続完了")


## インベントリ変化時に該当ラベルのみ更新する
func _on_inventory_changed(
	type: ResourceDefinitions.ResourceType, new_amount: int
) -> void:
	if not is_instance_valid(_pawn):
		return
	# 該当するラベルのみ更新する
	var entry: Dictionary = _label_map.get(type, {})
	if not entry.is_empty():
		entry["label"].text = "%s: %d" % [entry["name"], new_amount]


## HP変化時にHPバーを更新する
func _on_health_changed(current_hp: int, max_hp: int) -> void:
	_hp_bar.max_value = max_hp
	_hp_bar.value = current_hp


## 全ラベルを最新の値で更新する
func _refresh_all() -> void:
	if is_instance_valid(_pawn) and _pawn.has_method("get_resource_amount"):
		_wood_label.text = "Wood: %d" % _pawn.get_resource_amount(
			ResourceDefinitions.ResourceType.WOOD
		)
		_gold_label.text = "Gold: %d" % _pawn.get_resource_amount(
			ResourceDefinitions.ResourceType.GOLD
		)
		_meat_label.text = "Meat: %d" % _pawn.get_resource_amount(
			ResourceDefinitions.ResourceType.MEAT
		)
	else:
		_wood_label.text = "Wood: 0"
		_gold_label.text = "Gold: 0"
		_meat_label.text = "Meat: 0"
