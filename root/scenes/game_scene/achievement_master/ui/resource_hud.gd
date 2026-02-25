## リソース・HP表示HUD — Pawn のインベントリ変化とHP変化をUIに反映する
class_name ResourceHud extends CanvasLayer


## HPバー
@onready var _hp_bar: ProgressBar = %HpBar
## リソースラベル群
@onready var _wood_label: Label = %WoodLabel
@onready var _gold_label: Label = %GoldLabel
@onready var _meat_label: Label = %MeatLabel


## 初期化 — Pawn へのシグナル接続を遅延実行する
func _ready() -> void:
	# Pawn が先に _ready される保証がないため遅延接続する
	_connect_to_pawn.call_deferred()
	_refresh_all(null)


## Pawn のシグナルを購読する
func _connect_to_pawn() -> void:
	var pawn: Node = get_tree().get_first_node_in_group("player")
	if pawn == null:
		return
	# インベントリ変化シグナルを接続
	if pawn.has_signal("inventory_changed"):
		pawn.inventory_changed.connect(_on_inventory_changed)
	# HP変化シグナルを接続
	if pawn.has_signal("health_changed"):
		pawn.health_changed.connect(_on_health_changed)
	Log.info("ResourceHud: Pawn に接続完了")


## インベントリ変化時にリソースラベルを更新する
func _on_inventory_changed(
	_type: ResourceDefinitions.ResourceType, _new_amount: int
) -> void:
	var pawn: Node = get_tree().get_first_node_in_group("player")
	_refresh_all(pawn)


## HP変化時にHPバーを更新する
func _on_health_changed(current_hp: int, max_hp: int) -> void:
	_hp_bar.max_value = max_hp
	_hp_bar.value = current_hp


## 全ラベルを最新の値で更新する
func _refresh_all(pawn: Node) -> void:
	if pawn != null and pawn.has_method("get_resource_amount"):
		_wood_label.text = "Wood: %d" % pawn.get_resource_amount(
			ResourceDefinitions.ResourceType.WOOD
		)
		_gold_label.text = "Gold: %d" % pawn.get_resource_amount(
			ResourceDefinitions.ResourceType.GOLD
		)
		_meat_label.text = "Meat: %d" % pawn.get_resource_amount(
			ResourceDefinitions.ResourceType.MEAT
		)
	else:
		_wood_label.text = "Wood: 0"
		_gold_label.text = "Gold: 0"
		_meat_label.text = "Meat: 0"
