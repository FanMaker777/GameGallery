## 実績システムのファサード（Autoload）
## イベント配線・距離追跡を担当し、コアロジックは AchievementTracker に委譲する
extends Node

# ---- シグナル（Tracker から中継） ----
## 実績が解除されたときに発火する
signal achievement_unlocked(id: StringName, definition: AchievementDefinition)
## 実績の進捗が更新されたときに発火する
signal achievement_progress_updated(id: StringName, current: int, target: int)
## ピン留め状態が変更されたときに発火する
signal pinned_changed

# ---- 定数 ----
## NPC会話のクールダウン時間（秒）
const NPC_TALK_COOLDOWN: float = 30.0
## 歩行距離の記録間隔（ピクセル）
const DISTANCE_RECORD_INTERVAL: float = 100.0

# ---- 子ノード ----
@onready var _tracker: AchievementTracker = %AchievementTracker

# ---- NPC クールダウン ----
## NPC会話クールダウン { npc_id: last_time_msec }
var _npc_talk_cooldowns: Dictionary = {}

# ---- プレイヤー参照 ----
## 登録されたプレイヤーノード
var _player: Node = null
## 前フレームのプレイヤー位置（歩行距離計算用）
var _previous_player_pos: Vector2 = Vector2.ZERO
## 歩行距離の累積（DISTANCE_RECORD_INTERVAL に達したら record）
var _distance_accumulator: float = 0.0
## 前フレームのHP（ダメージ検出用）
var _previous_hp: int = -1
## プレイ時間の累積（1秒ごとに record）
var _play_time_accumulator: float = 0.0


# ========== ライフサイクル ==========

func _ready() -> void:
	# Tracker を初期化する
	_tracker.initialize()
	# Tracker のシグナルを自身のシグナルに中継する
	_tracker.achievement_unlocked.connect(
		func(id: StringName, def: AchievementDefinition) -> void:
			achievement_unlocked.emit(id, def)
	)
	_tracker.achievement_progress_updated.connect(
		func(id: StringName, current: int, target: int) -> void:
			achievement_progress_updated.emit(id, current, target)
	)
	_tracker.pinned_changed.connect(func() -> void: pinned_changed.emit())
	# シーンツリーの node_added シグナルに接続し、ノード自動接続を行う
	get_tree().node_added.connect(_on_node_added)
	# InventoryManager のシグナルを接続してアイテム関連実績を追跡する
	InventoryManager.bag_changed.connect(_on_inventory_bag_changed)
	InventoryManager.equipment_changed.connect(_on_inventory_equipment_changed)
	InventoryManager.item_used.connect(_on_inventory_item_used)
	Log.info("AchievementManager: 初期化完了")


func _process(delta: float) -> void:
	# プレイ時間を追跡する
	_play_time_accumulator += delta
	if _play_time_accumulator >= 1.0:
		_play_time_accumulator -= 1.0
		_tracker.add_play_time(1.0)
	# プレイヤーの歩行距離を追跡する
	if _player != null and is_instance_valid(_player):
		var current_pos: Vector2 = _player.global_position
		if _previous_player_pos != Vector2.ZERO:
			var moved: float = current_pos.distance_to(_previous_player_pos)
			if moved > 0.1 and moved < 500.0:  # テレポート除外
				_distance_accumulator += moved
				# 一定距離ごとに record_action を呼ぶ
				while _distance_accumulator >= DISTANCE_RECORD_INTERVAL:
					_distance_accumulator -= DISTANCE_RECORD_INTERVAL
					_tracker.record_action(&"distance_walked", {&"amount": int(DISTANCE_RECORD_INTERVAL)})
		_previous_player_pos = current_pos


# ========== 公開 API（Tracker への委譲） ==========

## プレイヤーノードを登録し、シグナルを接続する
func register_player(player: Node) -> void:
	_player = player
	_previous_player_pos = player.global_position
	_distance_accumulator = 0.0
	# Pawn のシグナルを接続する
	if player.has_signal("attack_landed"):
		player.attack_landed.connect(_on_player_attack_landed)
	if player.has_signal("attack_started"):
		player.attack_started.connect(_on_player_attack_started)
	if player.has_signal("health_changed"):
		player.health_changed.connect(_on_player_health_changed)
	if player.has_signal("died"):
		player.died.connect(_on_player_died)
	Log.info("AchievementManager: プレイヤー登録完了")


## アクションを記録し、該当する実績の進捗を更新する
func record_action(action: StringName, context: Dictionary = {}) -> void:
	_tracker.record_action(action, context)


## 指定実績の進捗情報を返す
func get_progress(id: StringName) -> Dictionary:
	return _tracker.get_progress(id)


## 全実績定義を返す
func get_all_definitions() -> Array[AchievementDefinition]:
	return _tracker.get_all_definitions()


## 解除済み実績IDの配列を返す
func get_unlocked_ids() -> Array[StringName]:
	return _tracker.get_unlocked_ids()


## 合計APを返す
func get_total_ap() -> int:
	return _tracker.get_total_ap()


## 指定IDの実績定義を返す（未定義の場合は null）
func get_definition(id: StringName) -> AchievementDefinition:
	return _tracker.get_definition(id)


## ピン留め中の実績IDの配列を返す
func get_pinned_ids() -> Array[StringName]:
	return _tracker.get_pinned_ids()


## 実績をピン留めする（解除済み実績は不可、上限超過時は無視）
func pin_achievement(id: StringName) -> void:
	_tracker.pin_achievement(id)


## 実績のピン留めを解除する
func unpin_achievement(id: StringName) -> void:
	_tracker.unpin_achievement(id)


## 指定実績がピン留めされているかを返す
func is_pinned(id: StringName) -> bool:
	return _tracker.is_pinned(id)


## 指定アクションの累積カウントを返す（RecordTab 用）
func get_stat(action: StringName) -> int:
	return _tracker.get_stat(action)


## 指定アクションの型名別内訳を返す（RecordTab 用）
func get_stat_by_type(action: StringName) -> Dictionary:
	return _tracker.get_stat_by_type(action)


## 累積プレイ時間（秒）を返す（RecordTab 用）
func get_play_time_seconds() -> float:
	return _tracker.get_play_time_seconds()


## 全レコードをリセットする（RecordTab 用）
func reset_records() -> void:
	_tracker.reset_records()


# ========== セーブ/ロード（SaveManager から呼ばれる） ==========

## 実績状態を Dictionary で返す
func get_save_data() -> Dictionary:
	return _tracker.get_save_data()


## Dictionary から実績状態を復元する
func load_save_data(data: Dictionary) -> void:
	_tracker.load_save_data(data)


## レコード状態を Dictionary で返す
func get_record_save_data() -> Dictionary:
	return _tracker.get_record_save_data()


## Dictionary からレコード状態を復元する
func load_record_save_data(data: Dictionary) -> void:
	_tracker.load_record_save_data(data)


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
			if not node.npc_interacted.is_connected(_on_npc_interacted):
				node.npc_interacted.connect(_on_npc_interacted)
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
	_tracker.record_action(&"enemy_killed", context)


## NPCに話しかけたとき
func _on_npc_interacted(npc_id: String) -> void:
	# クールダウンチェック（同一NPC連打防止）
	var now: int = Time.get_ticks_msec()
	var last_time: int = _npc_talk_cooldowns.get(npc_id, 0)
	if now - last_time < int(NPC_TALK_COOLDOWN * 1000.0):
		Log.debug("AchievementManager: NPC会話クールダウン中 [%s]" % npc_id)
		return
	_npc_talk_cooldowns[npc_id] = now
	_tracker.record_action(&"npc_talked", {&"instance_id": npc_id})


## リソースが採取されたとき
func _on_resource_harvested(resource_type: int, node_key: String) -> void:
	# 全種共通
	_tracker.record_action(&"resource_harvested", {&"instance_id": node_key})
	# 種別ごとのアクション
	match resource_type:
		ResourceDefinitions.ResourceType.WOOD:
			_tracker.record_action(&"resource_harvested_wood")
		ResourceDefinitions.ResourceType.GOLD:
			_tracker.record_action(&"resource_harvested_gold")
		ResourceDefinitions.ResourceType.MEAT:
			_tracker.record_action(&"resource_harvested_meat")


## マップ遷移したとき
func _on_map_transitioned(target_path: String) -> void:
	# パスからマップ名を抽出して instance_id にする
	var map_name: String = target_path.get_file().get_basename()
	_tracker.record_action(&"map_entered", {&"instance_id": map_name})


## プレイヤーの攻撃が命中したとき
func _on_player_attack_landed(_target: Node2D, _damage: int) -> void:
	_tracker.record_action(&"attack_landed")


## プレイヤーが攻撃を開始したとき
func _on_player_attack_started() -> void:
	_tracker.record_action(&"attack_started")
	# チャレンジリセット: attack_started でリセットされる実績
	_tracker.handle_challenge_reset(&"attack_started")


## プレイヤーのHPが変化したとき（ダメージ検出用）
func _on_player_health_changed(current_hp: int, _max_hp: int) -> void:
	if _previous_hp >= 0 and current_hp < _previous_hp:
		_tracker.record_action(&"player_damaged")
		# チャレンジリセット: player_damaged でリセットされる実績
		_tracker.handle_challenge_reset(&"player_damaged")
	_previous_hp = current_hp


## プレイヤーが死亡したとき
func _on_player_died() -> void:
	_tracker.record_action(&"player_died")


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
