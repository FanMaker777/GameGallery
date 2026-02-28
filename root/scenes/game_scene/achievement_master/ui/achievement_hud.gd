## 統合型HUD — HP・リソース・AP表示、ピン留め実績パネル枠、トースト通知を一元管理する
class_name AchievementHud extends CanvasLayer

# ---- ノードキャッシュ ----
## HPバー
@onready var _hp_bar: ProgressBar = %HpBar
## 木材ラベル
@onready var _wood_label: Label = %WoodLabel
## 金ラベル
@onready var _gold_label: Label = %GoldLabel
## 肉ラベル
@onready var _meat_label: Label = %MeatLabel
## APカウンターラベル
@onready var _ap_label: Label = %ApLabel
## ピン留め実績パネル
@onready var _pinned_panel: PinnedAchievementPanel = %PinnedAchievementPanel

# ---- 状態 ----
## Pawn への参照キャッシュ（毎回検索しない）
var _pawn: Node = null
## リソース種別とラベルの対応マッピング
var _label_map: Dictionary = {}


## 初期化 — Pawn へのシグナル接続を遅延実行し、AP表示を初期化する
func _ready() -> void:
	# Pawn が先に _ready される保証がないため遅延接続する
	_connect_to_pawn.call_deferred()
	# 全ラベルを初期化する
	_refresh_all()
	# AchievementManager のシグナルを購読してAPをリアルタイム更新する
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)


## Pawn のシグナルを購読し、参照をキャッシュする
func _connect_to_pawn() -> void:
	_pawn = get_tree().get_first_node_in_group("player")
	if _pawn == null:
		Log.debug("AchievementHud: グループ 'player' に Pawn が見つからない")
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
	# 全表示を最新化する
	_refresh_all()
	Log.info("AchievementHud: Pawn に接続完了")


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


## 実績解除時にAPカウンターを更新する
func _on_achievement_unlocked(
	_id: StringName, _definition: AchievementDefinition
) -> void:
	_refresh_ap()


## APカウンターを最新値で更新する
func _refresh_ap() -> void:
	_ap_label.text = "AP: %d" % AchievementManager.get_total_ap()


## 全ラベルを最新の値で更新する
func _refresh_all() -> void:
	# リソースラベルを更新する
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
	# APカウンターを更新する
	_refresh_ap()
