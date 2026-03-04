## 報酬ツリーの解放・効果適用・セーブ/ロードを担当する Autoload
extends Node

# ---- シグナル ----
## 報酬が解放されたときに発火する
signal reward_unlocked(id: StringName, definition: RewardDefinition)
## 利用可能APが変化したときに発火する
signal available_ap_changed(available_ap: int)

# ---- 定数 ----
## セーブファイルのパス
const SAVE_PATH: String = "user://achievement_master_rewards.save"

# ---- 報酬データベース ----
## preload した報酬定義リソース
var _database: RewardDatabase = preload(
	"res://root/scenes/game_scene/achievement_master/data/reward_database.tres"
)
## { id: RewardDefinition } の高速引きマップ
var _def_map: Dictionary = {}

# ---- 報酬状態 ----
## 解放済み報酬IDの配列
var _unlocked_ids: Array[StringName] = []
## 消費済みAP
var _spent_ap: int = 0
## 効果累積値キャッシュ（解放時に更新、各システムが参照する）
var _effect_cache: RewardEffectCache = RewardEffectCache.new()


# ========== ライフサイクル ==========

## 初期化 — 定義マップ構築・セーブ復元・効果キャッシュ再構築
func _ready() -> void:
	# データベースの高速引きマップを構築する
	for def: RewardDefinition in _database.rewards:
		_def_map[def.id] = def
	# セーブデータを復元する
	_load()
	# 効果キャッシュを再構築する
	_rebuild_effect_cache()
	Log.info("RewardManager: 初期化完了 (%d件の報酬定義, 解放済み=%d, 消費AP=%d)" % [
		_def_map.size(), _unlocked_ids.size(), _spent_ap
	])


# ========== 公開 API ==========

## 利用可能AP（累計AP - 消費済AP）を返す
func get_available_ap() -> int:
	return AchievementManager.get_total_ap() - _spent_ap


## 消費済みAPを返す
func get_spent_ap() -> int:
	return _spent_ap


## 報酬ノードを解放する（AP消費 + 前提チェック + 効果適用 + セーブ）
func unlock_reward(id: StringName) -> bool:
	if not can_unlock(id):
		return false
	var def: RewardDefinition = _def_map[id]
	# AP を消費する
	_spent_ap += def.ap_cost
	_unlocked_ids.append(id)
	Log.info("RewardManager: 報酬解放 [%s] %s (AP消費=%d, 残AP=%d)" % [
		id, def.name_ja, def.ap_cost, get_available_ap()
	])
	# 効果キャッシュに差分を加算する
	_effect_cache.apply_effect(def)
	# セーブ + シグナル
	_save()
	reward_unlocked.emit(id, def)
	available_ap_changed.emit(get_available_ap())
	return true


## 指定ノードが解放可能かを返す（AP足りる + 前提充足 + 未解放）
func can_unlock(id: StringName) -> bool:
	if not _def_map.has(id):
		return false
	if is_unlocked(id):
		return false
	var def: RewardDefinition = _def_map[id]
	# AP チェック
	if get_available_ap() < def.ap_cost:
		return false
	# 前提ノードチェック
	for prereq_id: StringName in def.prerequisites:
		if not is_unlocked(prereq_id):
			return false
	return true


## 指定ノードが解放済みかを返す
func is_unlocked(id: StringName) -> bool:
	return id in _unlocked_ids


## 効果キャッシュを返す（各システムが直接プロパティを参照する）
func get_effect_cache() -> RewardEffectCache:
	return _effect_cache


## 全報酬定義を返す
func get_all_definitions() -> Array[RewardDefinition]:
	var result: Array[RewardDefinition] = []
	for def: RewardDefinition in _database.rewards:
		result.append(def)
	return result


## カテゴリ別の報酬定義を返す
func get_definitions_by_category(cat: RewardDefinition.Category) -> Array[RewardDefinition]:
	var result: Array[RewardDefinition] = []
	for def: RewardDefinition in _database.rewards:
		if def.category == cat:
			result.append(def)
	return result


## 解放済みIDの配列を返す
func get_unlocked_ids() -> Array[StringName]:
	return _unlocked_ids.duplicate()


## 指定IDの報酬定義を返す（未定義の場合は null）
func get_definition(id: StringName) -> RewardDefinition:
	return _def_map.get(id)


## 全報酬状態をリセットする
func reset_rewards() -> void:
	_unlocked_ids = []
	_spent_ap = 0
	_effect_cache.reset()
	_save()
	available_ap_changed.emit(get_available_ap())
	Log.info("RewardManager: 全報酬をリセットしました")


# ========== 効果キャッシュ（内部） ==========

## 解放済み報酬から効果キャッシュを全再構築する（ロード時に使用）
func _rebuild_effect_cache() -> void:
	_effect_cache.reset()
	for id: StringName in _unlocked_ids:
		var def: RewardDefinition = _def_map.get(id)
		if def != null:
			_effect_cache.apply_effect(def)
	Log.debug("RewardManager: 効果キャッシュ再構築完了 (HP+%.0f%%, ATK+%.0f%%, SPD+%.0f%%)" % [
		_effect_cache.hp_percent_up, _effect_cache.attack_percent_up, _effect_cache.move_speed_up
	])


# ========== セーブ/ロード ==========

## 報酬状態をJSONファイルに保存する
func _save() -> void:
	var ids_array: Array[String] = []
	for id: StringName in _unlocked_ids:
		ids_array.append(String(id))
	var data: Dictionary = {
		"unlocked_ids": ids_array,
		"spent_ap": _spent_ap,
	}
	var json_string: String = JSON.stringify(data, "\t")
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		Log.warn("RewardManager: セーブ失敗 — %s" % FileAccess.get_open_error())
		return
	file.store_string(json_string)
	file.close()
	Log.debug("RewardManager: セーブ完了")


## JSONファイルから報酬状態を復元する
func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		Log.info("RewardManager: セーブデータなし — 初回起動")
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		Log.warn("RewardManager: ロード失敗 — %s" % FileAccess.get_open_error())
		return
	var json_string: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	var error: Error = json.parse(json_string)
	if error != OK:
		Log.warn("RewardManager: JSONパース失敗 — %s" % json.get_error_message())
		return
	var data: Dictionary = json.data
	# unlocked_ids の復元（存在しないIDは除外する）
	_unlocked_ids = []
	for id_str: String in data.get("unlocked_ids", []):
		var id: StringName = StringName(id_str)
		if _def_map.has(id):
			_unlocked_ids.append(id)
	_spent_ap = int(data.get("spent_ap", 0))
	Log.info("RewardManager: ロード完了 (解放済み=%d, 消費AP=%d)" % [
		_unlocked_ids.size(), _spent_ap
	])
