## 統合型HUD — HP・リソース・AP表示、ピン留め実績パネル枠、トースト通知を一元管理する
class_name AchievementHud extends CanvasLayer

# ---- ノードキャッシュ ----
## HPバー
@onready var _hp_bar: ProgressBar = %HpBar
## スタミナバー
@onready var _stamina_bar: ProgressBar = %StaminaBar
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
## Player への参照キャッシュ（毎回検索しない）
var _player: Node = null
## リソース種別とラベルの対応マッピング
var _label_map: Dictionary = {}


## 初期化 — Player へのシグナル接続を遅延実行し、AP表示を初期化する
func _ready() -> void:
	# Player が先に _ready される保証がないため遅延接続する
	_connect_to_player.call_deferred()
	# 全ラベルを初期化する
	_refresh_all()
	# AchievementManager のシグナルを購読してAPをリアルタイム更新する
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)


## Player のシグナルを購読し、参照をキャッシュする
func _connect_to_player() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		Log.debug("AchievementHud: グループ 'player' に Player が見つからない")
		return
	# アイテムIDとラベルの対応マッピングを構築する
	_label_map = {
		&"wood": { "label": _wood_label, "name": "Wood" },
		&"gold": { "label": _gold_label, "name": "Gold" },
		&"meat": { "label": _meat_label, "name": "Meat" },
	}
	# InventoryManager のバッグ変化シグナルを接続する
	InventoryManager.bag_changed.connect(_on_bag_changed)
	# HP変化シグナルを接続
	if _player.has_signal("health_changed"):
		_player.health_changed.connect(_on_health_changed)
	# スタミナ変化シグナルを接続
	if _player.has_signal("stamina_changed"):
		_player.stamina_changed.connect(_on_stamina_changed)
	# 全表示を最新化する
	_refresh_all()
	Log.info("AchievementHud: Player に接続完了")


## バッグ内容変化時に該当ラベルのみ更新する
func _on_bag_changed(id: StringName, new_count: int) -> void:
	# 該当するラベルのみ更新する
	var entry: Dictionary = _label_map.get(id, {})
	if not entry.is_empty():
		entry["label"].text = "%s: %d" % [entry["name"], new_count]


## HP変化時にHPバーを更新する
func _on_health_changed(current_hp: int, max_hp: int) -> void:
	_hp_bar.max_value = max_hp
	_hp_bar.value = current_hp


## スタミナ変化時にスタミナバーを更新する
func _on_stamina_changed(current_stamina: float, p_max_stamina: float) -> void:
	_stamina_bar.max_value = p_max_stamina
	_stamina_bar.value = current_stamina


## 実績解除時にAPカウンターを更新する
func _on_achievement_unlocked(
	_id: StringName, _definition: AchievementDefinition
) -> void:
	_refresh_ap()


## APカウンターを最新値で更新する
func _refresh_ap() -> void:
	_ap_label.text = "AP: %d" % AchievementManager.tracker.get_total_ap()


## 全ラベルを最新の値で更新する
func _refresh_all() -> void:
	# リソースラベルを InventoryManager から更新する
	_wood_label.text = "Wood: %d" % InventoryManager.get_item_count(&"wood")
	_gold_label.text = "Gold: %d" % InventoryManager.get_item_count(&"gold")
	_meat_label.text = "Meat: %d" % InventoryManager.get_item_count(&"meat")
	# APカウンターを更新する
	_refresh_ap()
