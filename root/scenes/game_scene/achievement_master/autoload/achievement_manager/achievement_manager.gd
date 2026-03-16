## 実績システムのファサード（Autoload）
## イベント配線を担当し、コアロジックは AchievementTracker に委譲する
extends Node

# ---- シグナル（Tracker から中継） ----
## 実績が解除されたときに発火する
signal achievement_unlocked(id: StringName, definition: AchievementDefinition)
## 実績の進捗が更新されたときに発火する
signal achievement_progress_updated(id: StringName, current: int, target: int)
## ピン留め状態が変更されたときに発火する
signal pinned_changed

# ---- 子ノード ----
@onready var tracker: AchievementTracker = %AchievementTracker
@onready var player_metrics: PlayerMetricsTracker = %PlayerMetricsTracker

## 前フレームのHP（ダメージ検出用）
var _previous_hp: int = -1


# ========== ライフサイクル ==========

func _ready() -> void:
	# Tracker を初期化する
	tracker.initialize()
	# Saveable として登録する
	SaveManager.register_saveable(tracker)
	# Tracker のシグナルを自身のシグナルに中継する
	tracker.achievement_unlocked.connect(
		func(id: StringName, def: AchievementDefinition) -> void:
			AudioManager.play_se(AudioConsts.SE_ACHIEVEMENT_UNLOCK)
			achievement_unlocked.emit(id, def)
	)
	tracker.achievement_progress_updated.connect(
		func(id: StringName, current: int, target: int) -> void:
			achievement_progress_updated.emit(id, current, target)
	)
	tracker.pinned_changed.connect(func() -> void: pinned_changed.emit())
	# シーンツリーの node_added シグナルに接続し、ノード自動接続を行う
	get_tree().node_added.connect(_on_node_added)
	# InventoryManager のシグナルを接続してアイテム関連実績を追跡する
	InventoryManager.bag_changed.connect(_on_inventory_bag_changed)
	InventoryManager.equipment_changed.connect(_on_inventory_equipment_changed)
	InventoryManager.item_used.connect(_on_inventory_item_used)
	Log.info("AchievementManager: 初期化完了")


# ========== 公開 API ==========

## プレイヤーノードを登録し、シグナルを接続する
func register_player(player: Node) -> void:
	player_metrics.register_player(player)
	# Player のシグナルを接続する
	if player.has_signal("attack_landed"):
		player.attack_landed.connect(_on_player_attack_landed)
	if player.has_signal("attack_started"):
		player.attack_started.connect(_on_player_attack_started)
	if player.has_signal("health_changed"):
		player.health_changed.connect(_on_player_health_changed)
	if player.has_signal("died"):
		player.died.connect(_on_player_died)
	Log.info("AchievementManager: プレイヤー登録完了")


# ========== ノード自動接続（node_added コールバック） ==========

## シーンツリーに追加されたノードのシグナルを自動接続する
func _on_node_added(node: Node) -> void:
	# Enemy の died シグナルを接続する
	if node is Enemy:
		if not node.died.is_connected(_on_enemy_died):
			node.died.connect(_on_enemy_died.bind(node))
	# Npc の npc_interacted シグナルを接続する
	if node is Npc:
		if node.has_signal("npc_interacted"):
			if not node.npc_interacted.is_connected(player_metrics._on_npc_interacted):
				node.npc_interacted.connect(player_metrics._on_npc_interacted)
	# ResourceNode の resource_harvested シグナルを接続する
	if node is ResourceNode:
		if node.has_signal("resource_harvested"):
			if not node.resource_harvested.is_connected(_on_resource_harvested):
				node.resource_harvested.connect(_on_resource_harvested)
	# MapGate の map_transitioned シグナルを接続する
	if node is MapGate:
		if node.has_signal("map_transitioned"):
			if not node.map_transitioned.is_connected(_on_map_transitioned):
				node.map_transitioned.connect(_on_map_transitioned)


# ========== イベントハンドラ ==========

## 敵が倒されたとき
func _on_enemy_died(enemy: Node) -> void:
	var context: Dictionary = {&"instance_id": enemy.name}
	if enemy is Enemy and enemy.enemy_data:
		context[&"type_name"] = enemy.enemy_data.display_name
	tracker.record_action(&"enemy_killed", context)


## リソースが採取されたとき
func _on_resource_harvested(resource_type: int, node_key: String) -> void:
	# 全種共通
	tracker.record_action(&"resource_harvested", {&"instance_id": node_key})
	# 種別ごとのアクション
	match resource_type:
		ResourceDefinitions.ResourceType.WOOD:
			tracker.record_action(&"resource_harvested_wood")
		ResourceDefinitions.ResourceType.GOLD:
			tracker.record_action(&"resource_harvested_gold")
		ResourceDefinitions.ResourceType.MEAT:
			tracker.record_action(&"resource_harvested_meat")
		ResourceDefinitions.ResourceType.BERRY:
			tracker.record_action(&"resource_harvested_berry")
		ResourceDefinitions.ResourceType.HERB:
			tracker.record_action(&"resource_harvested_herb")
		ResourceDefinitions.ResourceType.MUSHROOM:
			tracker.record_action(&"resource_harvested_mushroom")
		ResourceDefinitions.ResourceType.IRON:
			tracker.record_action(&"resource_harvested_iron")


## マップ遷移したとき
func _on_map_transitioned(target_path: String) -> void:
	# パスからマップ名を抽出して instance_id にする
	var map_name: String = target_path.get_file().get_basename()
	tracker.record_action(&"map_entered", {&"instance_id": map_name})


## プレイヤーの攻撃が命中したとき
func _on_player_attack_landed(_target: Node2D, _damage: int) -> void:
	tracker.record_action(&"attack_landed")


## プレイヤーが攻撃を開始したとき
func _on_player_attack_started() -> void:
	tracker.record_action(&"attack_started")
	# チャレンジリセット: attack_started でリセットされる実績
	tracker.handle_challenge_reset(&"attack_started")


## プレイヤーのHPが変化したとき（ダメージ検出用）
func _on_player_health_changed(current_hp: int, _max_hp: int) -> void:
	if _previous_hp >= 0 and current_hp < _previous_hp:
		tracker.record_action(&"player_damaged")
		# チャレンジリセット: player_damaged でリセットされる実績
		tracker.handle_challenge_reset(&"player_damaged")
	_previous_hp = current_hp


## プレイヤーが死亡したとき
func _on_player_died() -> void:
	tracker.record_action(&"player_died")


# ========== InventoryManager 連携 ==========

## バッグ内容が変化したとき
func _on_inventory_bag_changed(_id: StringName, _new_count: int) -> void:
	pass


## 装備が変更されたとき
func _on_inventory_equipment_changed(_slot: int) -> void:
	pass


## 消耗品が使用されたとき
func _on_inventory_item_used(_id: StringName, _definition: ItemDefinition) -> void:
	pass
