## スキルツリーの解放・効果適用を担当する Autoload
extends Node

# ---- シグナル ----
## スキルが解放されたときに発火する
signal skill_unlocked(id: StringName, definition: SkillDefinition)
## 利用可能APが変化したときに発火する
signal available_ap_changed(available_ap: int)

# ---- スキルデータベース ----
## preload したスキル定義リソース
var _database: SkillDatabase = preload("uid://dc7scokcg13w4")
## { id: SkillDefinition } の高速引きマップ
var _def_map: Dictionary = {}

# ---- スキル状態 ----
## 解放済みスキルIDの配列
var _unlocked_ids: Array[StringName] = []
## 消費済みAP
var _spent_ap: int = 0
## 効果累積値キャッシュ（解放時に更新、各システムが参照する）
var _effect_cache: SkillEffectCache = SkillEffectCache.new()


# ========== ライフサイクル ==========

## 初期化 — 定義マップ構築・効果キャッシュ再構築
func _ready() -> void:
	# データベースの高速引きマップを構築する
	for def: SkillDefinition in _database.skills:
		_def_map[def.id] = def
	Log.info("SkillManager: 初期化完了 (%d件のスキル定義, 解放済み=%d, 消費AP=%d)" % [
		_def_map.size(), _unlocked_ids.size(), _spent_ap
	])
	# Saveable として登録する
	SaveManager.register_saveable(self)


# ========== 公開 API ==========

## 利用可能AP（累計AP - 消費済AP）を返す
func get_available_ap() -> int:
	return AchievementManager.tracker.get_total_ap() - _spent_ap


## 消費済みAPを返す
func get_spent_ap() -> int:
	return _spent_ap


## スキルノードを解放する（AP消費 + 前提チェック + 効果適用 + セーブ）
func unlock_skill(id: StringName) -> bool:
	if not can_unlock(id):
		return false
	var def: SkillDefinition = _def_map[id]
	# AP を消費する
	_spent_ap += def.ap_cost
	_unlocked_ids.append(id)
	Log.info("SkillManager: スキル解放 [%s] %s (AP消費=%d, 残AP=%d)" % [
		id, def.name_ja, def.ap_cost, get_available_ap()
	])
	# 効果キャッシュに差分を加算する
	_effect_cache.apply_effect(def)
	# シグナル発火
	skill_unlocked.emit(id, def)
	available_ap_changed.emit(get_available_ap())
	return true


## 指定ノードが解放可能かを返す（AP足りる + 前提充足 + 未解放）
func can_unlock(id: StringName) -> bool:
	if not _def_map.has(id):
		return false
	if is_unlocked(id):
		return false
	var def: SkillDefinition = _def_map[id]
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
func get_effect_cache() -> SkillEffectCache:
	return _effect_cache


## 全スキル定義を返す
func get_all_definitions() -> Array[SkillDefinition]:
	var result: Array[SkillDefinition] = []
	for def: SkillDefinition in _database.skills:
		result.append(def)
	return result


## カテゴリ別のスキル定義を返す
func get_definitions_by_category(cat: SkillDefinition.Category) -> Array[SkillDefinition]:
	var result: Array[SkillDefinition] = []
	for def: SkillDefinition in _database.skills:
		if def.category == cat:
			result.append(def)
	return result


## 解放済みIDの配列を返す
func get_unlocked_ids() -> Array[StringName]:
	return _unlocked_ids.duplicate()


## 指定IDのスキル定義を返す（未定義の場合は null）
func get_definition(id: StringName) -> SkillDefinition:
	return _def_map.get(id)


## 全スキル状態をリセットする
func reset_skills() -> void:
	_unlocked_ids = []
	_spent_ap = 0
	_effect_cache.reset()
	available_ap_changed.emit(get_available_ap())
	Log.info("SkillManager: 全スキルをリセットしました")


# ========== 効果キャッシュ（内部） ==========

## 解放済みスキルから効果キャッシュを全再構築する（ロード時に使用）
func _rebuild_effect_cache() -> void:
	_effect_cache.reset()
	for id: StringName in _unlocked_ids:
		var def: SkillDefinition = _def_map.get(id)
		if def != null:
			_effect_cache.apply_effect(def)
	Log.debug("SkillManager: 効果キャッシュ再構築完了 (HP+%.0f%%, ATK+%.0f%%, SPD+%.0f%%)" % [
		_effect_cache.hp_percent_up, _effect_cache.attack_percent_up, _effect_cache.move_speed_up
	])


# ========== セーブ/ロード（SaveManager から呼ばれる） ==========

## 現在の状態を Dictionary で返す
func get_save_data() -> Dictionary:
	var ids_array: Array[String] = []
	for id: StringName in _unlocked_ids:
		ids_array.append(String(id))
	return {
		"unlocked_ids": ids_array,
		"spent_ap": _spent_ap,
	}


## Dictionary から状態を復元する
func load_save_data(data: Dictionary) -> void:
	# unlocked_ids の復元（存在しないIDは除外する）
	_unlocked_ids = []
	for id_str: String in data.get("unlocked_ids", []):
		var id: StringName = StringName(id_str)
		if _def_map.has(id):
			_unlocked_ids.append(id)
	_spent_ap = int(data.get("spent_ap", 0))
	# 効果キャッシュを再構築する
	_rebuild_effect_cache()
	Log.info("SkillManager: ロード完了 (解放済み=%d, 消費AP=%d)" % [
		_unlocked_ids.size(), _spent_ap
	])


# ========== Saveable インターフェース ==========

func get_save_keys() -> Array[StringName]:
	return [&"skill"]


func get_save_data_for_key(_key: StringName) -> Dictionary:
	return get_save_data()


func load_save_data_for_key(_key: StringName, data: Dictionary) -> void:
	load_save_data(data)


func reset_save_state() -> void:
	reset_skills()
