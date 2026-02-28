## 実績システムのコアマネージャー（Autoload）
## 実績の進捗管理・解除判定・セーブ/ロードを担当する
extends Node

# ---- シグナル ----
## 実績が解除されたときに発火する
signal achievement_unlocked(id: StringName, definition: AchievementDefinition)
## 実績の進捗が更新されたときに発火する
signal achievement_progress_updated(id: StringName, current: int, target: int)
## ピン留め状態が変更されたときに発火する
signal pinned_changed

# ---- 定数 ----
## セーブファイルのパス
const SAVE_PATH: String = "user://achievement_master_progress.save"
## NPC会話のクールダウン時間（秒）
const NPC_TALK_COOLDOWN: float = 30.0
## 歩行距離の記録間隔（ピクセル）
const DISTANCE_RECORD_INTERVAL: float = 100.0
## ピン留め可能な最大件数
const MAX_PIN_COUNT: int = 3

# ---- 実績データベース ----
## preload した実績定義リソース
var _database: AchievementDatabase = preload(
	"res://root/scenes/game_scene/achievement_master/data/achievement_database.tres"
)
## { id: AchievementDefinition } の高速引きマップ
var _def_map: Dictionary = {}

# ---- 進捗状態 ----
## { id: current_count } — 各実績の現在カウント
var _progress: Dictionary = {}
## { id: unlock_timestamp } — 解除済み実績
var _unlocked: Dictionary = {}
## { id: Array[String] } — unique_instances 用の記録セット
var _unique_sets: Dictionary = {}
## { id: current_streak } — チャレンジ実績のストリーク
var _challenge_streaks: Dictionary = {}
## NPC会話クールダウン { npc_id: last_time_msec }
var _npc_talk_cooldowns: Dictionary = {}
## 合計AP
var _total_ap: int = 0
## ピン留め中の実績ID配列（最大 MAX_PIN_COUNT 件）
var _pinned_ids: Array[StringName] = []

# ---- プレイヤー参照 ----
## 登録されたプレイヤーノード
var _player: Node = null
## 前フレームのプレイヤー位置（歩行距離計算用）
var _previous_player_pos: Vector2 = Vector2.ZERO
## 歩行距離の累積（DISTANCE_RECORD_INTERVAL に達したら record）
var _distance_accumulator: float = 0.0
## 前フレームのHP（ダメージ検出用）
var _previous_hp: int = -1


# ========== ライフサイクル ==========

func _ready() -> void:
	# 定義マップを構築する
	for def: AchievementDefinition in _database.achievements:
		_def_map[def.id] = def
	# セーブデータを復元する
	_load_progress()
	# シーンツリーの node_added シグナルに接続し、ノード自動接続を行う
	get_tree().node_added.connect(_on_node_added)
	Log.info("AchievementManager: 初期化完了 (%d件の実績定義)" % _def_map.size())


func _process(delta: float) -> void:
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
					record_action(&"distance_walked", {&"amount": int(DISTANCE_RECORD_INTERVAL)})
		_previous_player_pos = current_pos


# ========== 公開 API ==========

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
	for def: AchievementDefinition in _database.achievements:
		if def.trigger_action != action:
			continue
		if _unlocked.has(def.id):
			continue
		# チャレンジ実績のリセットチェック
		if def.type == AchievementDefinition.Type.CHALLENGE:
			# reset_on のチェックは _handle_challenge_reset で行う
			pass
		# ユニーク制約チェック
		if def.unique_instances:
			var instance_id: String = context.get(&"instance_id", "")
			if instance_id.is_empty():
				continue
			if not _unique_sets.has(def.id):
				_unique_sets[def.id] = []
			if instance_id in _unique_sets[def.id]:
				continue
			_unique_sets[def.id].append(instance_id)
		# 進捗を更新する
		var amount: int = context.get(&"amount", 1)
		if def.type == AchievementDefinition.Type.CHALLENGE:
			# チャレンジはストリークで管理
			if not _challenge_streaks.has(def.id):
				_challenge_streaks[def.id] = 0
			_challenge_streaks[def.id] += amount
			_progress[def.id] = _challenge_streaks[def.id]
		else:
			if not _progress.has(def.id):
				_progress[def.id] = 0
			_progress[def.id] += amount
		# 進捗シグナルを発火する
		achievement_progress_updated.emit(def.id, _progress.get(def.id, 0), def.target_count)
		# 閾値到達チェック
		if _progress.get(def.id, 0) >= def.target_count:
			_unlock_achievement(def)


## 指定実績の進捗情報を返す
func get_progress(id: StringName) -> Dictionary:
	var def: AchievementDefinition = _def_map.get(id)
	if def == null:
		return {}
	return {
		"current": _progress.get(id, 0),
		"target": def.target_count,
		"unlocked": _unlocked.has(id),
	}


## 全実績定義を返す
func get_all_definitions() -> Array[AchievementDefinition]:
	var result: Array[AchievementDefinition] = []
	for def: AchievementDefinition in _database.achievements:
		result.append(def)
	return result


## 解除済み実績IDの配列を返す
func get_unlocked_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for id: StringName in _unlocked.keys():
		result.append(id)
	return result


## 合計APを返す
func get_total_ap() -> int:
	return _total_ap


## 指定IDの実績定義を返す（未定義の場合は null）
func get_definition(id: StringName) -> AchievementDefinition:
	return _def_map.get(id)


## ピン留め中の実績IDの配列を返す
func get_pinned_ids() -> Array[StringName]:
	return _pinned_ids.duplicate()


## 実績をピン留めする（解除済み実績は不可、上限超過時は無視）
func pin_achievement(id: StringName) -> void:
	# 実績定義の存在チェック
	if not _def_map.has(id):
		Log.warn("AchievementManager: ピン留め失敗 — 未知のID [%s]" % id)
		return
	# 解除済み実績はピン留め不可
	if _unlocked.has(id):
		Log.debug("AchievementManager: ピン留め失敗 — 解除済み [%s]" % id)
		return
	# 既にピン留め済みの場合は無視
	if id in _pinned_ids:
		return
	# 上限チェック
	if _pinned_ids.size() >= MAX_PIN_COUNT:
		Log.debug("AchievementManager: ピン留め失敗 — 上限 %d 件に到達" % MAX_PIN_COUNT)
		return
	# ピン留めを追加する
	_pinned_ids.append(id)
	pinned_changed.emit()
	_save_progress()
	Log.info("AchievementManager: ピン留め追加 [%s] (合計 %d 件)" % [id, _pinned_ids.size()])


## 実績のピン留めを解除する
func unpin_achievement(id: StringName) -> void:
	var idx: int = _pinned_ids.find(id)
	if idx < 0:
		return
	# ピン留めを解除する
	_pinned_ids.remove_at(idx)
	pinned_changed.emit()
	_save_progress()
	Log.info("AchievementManager: ピン留め解除 [%s] (合計 %d 件)" % [id, _pinned_ids.size()])


## 指定実績がピン留めされているかを返す
func is_pinned(id: StringName) -> bool:
	return id in _pinned_ids


# ========== 内部ロジック ==========

## 実績を解除する（二重解除防止付き）
func _unlock_achievement(def: AchievementDefinition) -> void:
	if _unlocked.has(def.id):
		return
	_unlocked[def.id] = Time.get_unix_time_from_system()
	_total_ap += def.ap
	Log.info("AchievementManager: 🏆 実績解除 [%s] %s (AP+%d, 合計AP=%d)" % [
		def.id, def.name_ja, def.ap, _total_ap
	])
	achievement_unlocked.emit(def.id, def)
	# 解除された実績がピン留めされている場合は自動的にピン解除する
	if def.id in _pinned_ids:
		_pinned_ids.erase(def.id)
		pinned_changed.emit()
	# システム実績の自動進捗
	record_action(&"achievement_unlocked")
	record_action(&"ap_earned", {&"amount": def.ap})
	# 自動セーブ
	_save_progress()


## チャレンジ実績のリセット処理
func _handle_challenge_reset(reset_action: StringName) -> void:
	for def: AchievementDefinition in _database.achievements:
		if def.type != AchievementDefinition.Type.CHALLENGE:
			continue
		if def.reset_on != reset_action:
			continue
		if _unlocked.has(def.id):
			continue
		# ストリークをリセットする
		_challenge_streaks[def.id] = 0
		_progress[def.id] = 0


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
	record_action(&"enemy_killed", {&"instance_id": enemy.name})
	# チャレンジリセット: enemy_killed がリセットトリガーの実績は無し（逆方向）
	# player_damaged がリセットなので、ここではリセット不要


## NPCに話しかけたとき
func _on_npc_interacted(npc_id: String) -> void:
	# クールダウンチェック（同一NPC連打防止）
	var now: int = Time.get_ticks_msec()
	var last_time: int = _npc_talk_cooldowns.get(npc_id, 0)
	if now - last_time < int(NPC_TALK_COOLDOWN * 1000.0):
		Log.debug("AchievementManager: NPC会話クールダウン中 [%s]" % npc_id)
		return
	_npc_talk_cooldowns[npc_id] = now
	record_action(&"npc_talked", {&"instance_id": npc_id})


## リソースが採取されたとき
func _on_resource_harvested(resource_type: int, node_key: String) -> void:
	# 全種共通
	record_action(&"resource_harvested", {&"instance_id": node_key})
	# 種別ごとのアクション
	match resource_type:
		ResourceDefinitions.ResourceType.WOOD:
			record_action(&"resource_harvested_wood")
		ResourceDefinitions.ResourceType.GOLD:
			record_action(&"resource_harvested_gold")
		ResourceDefinitions.ResourceType.MEAT:
			record_action(&"resource_harvested_meat")


## マップ遷移したとき
func _on_map_transitioned(target_path: String) -> void:
	# パスからマップ名を抽出して instance_id にする
	var map_name: String = target_path.get_file().get_basename()
	record_action(&"map_entered", {&"instance_id": map_name})


## プレイヤーの攻撃が命中したとき
func _on_player_attack_landed(_target: Node2D, _damage: int) -> void:
	record_action(&"attack_landed")


## プレイヤーが攻撃を開始したとき
func _on_player_attack_started() -> void:
	record_action(&"attack_started")
	# チャレンジリセット: attack_started でリセットされる実績
	_handle_challenge_reset(&"attack_started")


## プレイヤーのHPが変化したとき（ダメージ検出用）
func _on_player_health_changed(current_hp: int, _max_hp: int) -> void:
	if _previous_hp >= 0 and current_hp < _previous_hp:
		record_action(&"player_damaged")
		# チャレンジリセット: player_damaged でリセットされる実績
		_handle_challenge_reset(&"player_damaged")
	_previous_hp = current_hp


## プレイヤーが死亡したとき
func _on_player_died() -> void:
	record_action(&"player_died")


# ========== セーブ/ロード ==========

## 進捗データをJSONファイルに保存する
func _save_progress() -> void:
	var data: Dictionary = {
		"progress": _progress,
		"unlocked": _unlocked,
		"unique_sets": _unique_sets,
		"challenge_streaks": _challenge_streaks,
		"total_ap": _total_ap,
		"pinned_ids": _pinned_ids,
	}
	var json_string: String = JSON.stringify(data, "\t")
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		Log.warn("AchievementManager: セーブ失敗 — %s" % FileAccess.get_open_error())
		return
	file.store_string(json_string)
	file.close()
	Log.debug("AchievementManager: セーブ完了")


## JSONファイルから進捗データを復元する
func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		Log.info("AchievementManager: セーブデータなし — 初回起動")
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		Log.warn("AchievementManager: ロード失敗 — %s" % FileAccess.get_open_error())
		return
	var json_string: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	var error: Error = json.parse(json_string)
	if error != OK:
		Log.warn("AchievementManager: JSONパース失敗 — %s" % json.get_error_message())
		return
	var data: Dictionary = json.data
	# 進捗の復元（JSONのキーは文字列になるため StringName に変換）
	_progress = {}
	for key: String in data.get("progress", {}).keys():
		_progress[StringName(key)] = int(data["progress"][key])
	_unlocked = {}
	for key: String in data.get("unlocked", {}).keys():
		_unlocked[StringName(key)] = data["unlocked"][key]
	_unique_sets = {}
	for key: String in data.get("unique_sets", {}).keys():
		_unique_sets[StringName(key)] = data["unique_sets"][key]
	_challenge_streaks = {}
	for key: String in data.get("challenge_streaks", {}).keys():
		_challenge_streaks[StringName(key)] = int(data["challenge_streaks"][key])
	_total_ap = int(data.get("total_ap", 0))
	# ピン留めIDの復元（解除済み・未定義の実績は除外する）
	_pinned_ids = []
	for id_str: String in data.get("pinned_ids", []):
		var id: StringName = StringName(id_str)
		if not _unlocked.has(id) and _def_map.has(id):
			_pinned_ids.append(id)
	Log.info("AchievementManager: ロード完了 (解除済み=%d, AP=%d, ピン留め=%d)" % [
		_unlocked.size(), _total_ap, _pinned_ids.size()
	])
