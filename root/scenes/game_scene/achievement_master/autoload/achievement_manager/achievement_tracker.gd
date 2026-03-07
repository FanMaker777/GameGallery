## 実績の進捗管理・解除判定・ピン留めを担当する
## 進捗データは RecordDatabase から導出し、実績状態（解除/ピン留め）のみ自身で管理する
class_name AchievementTracker extends Node

# ---- シグナル ----
## 実績が解除されたときに発火する
signal achievement_unlocked(id: StringName, definition: AchievementDefinition)
## 実績の進捗が更新されたときに発火する
signal achievement_progress_updated(id: StringName, current: int, target: int)
## ピン留め状態が変更されたときに発火する
signal pinned_changed

# ---- 定数 ----
## ピン留め可能な最大件数
const MAX_PIN_COUNT: int = 3

# ---- 実績データベース ----
## preload した実績定義リソース
var _database: AchievementDatabase = preload("uid://djq03bqmx8mfq")
## { id: AchievementDefinition } の高速引きマップ
var _def_map: Dictionary = {}

# ---- レコードデータベース ----
## 生データの蓄積を担当する Resource
var _record_db: RecordDatabase = null

# ---- 実績状態（解除/ピン留めのみ） ----
## { id: unlock_timestamp } — 解除済み実績
var _unlocked: Dictionary = {}
## 合計AP
var _total_ap: int = 0
## ピン留め中の実績ID配列（最大 MAX_PIN_COUNT 件）
var _pinned_ids: Array[StringName] = []


# ========== 初期化 ==========

## データベース構築を行う（親ノードの _ready から呼ばれる）
func initialize() -> void:
	for def: AchievementDefinition in _database.achievements:
		_def_map[def.id] = def
	_record_db = RecordDatabase.new()
	Log.info("AchievementTracker: 初期化完了 (%d件の実績定義)" % _def_map.size())


# ========== 公開 API ==========

## アクションを記録し、該当する実績の進捗を更新する
func record_action(action: StringName, context: Dictionary = {}) -> void:
	# 1. RecordDatabase に常にカウント
	_record_db.record(action, context)
	# 2. CHALLENGE 定義のストリーク加算
	var amount: int = context.get(&"amount", 1)
	for def: AchievementDefinition in _database.achievements:
		if def.trigger_action != action:
			continue
		if def.type == AchievementDefinition.Type.CHALLENGE:
			_record_db.increment_streak(def.trigger_action, def.reset_on, amount)
	# 3. 全マッチ定義をループして進捗判定
	for def: AchievementDefinition in _database.achievements:
		if def.trigger_action != action:
			continue
		if _unlocked.has(def.id):
			continue
		# 進捗値を RecordDatabase から導出する
		var current: int = _derive_progress(def)
		# 進捗シグナルを発火する
		achievement_progress_updated.emit(def.id, current, def.target_count)
		# 閾値到達チェック
		if current >= def.target_count:
			_unlock_achievement(def)


## 指定実績の進捗情報を返す
func get_progress(id: StringName) -> Dictionary:
	var def: AchievementDefinition = _def_map.get(id)
	if def == null:
		return {}
	var is_unlocked: bool = _unlocked.has(id)
	var current: int
	if is_unlocked:
		current = def.target_count
	else:
		current = _derive_progress(def)
	return {
		"current": current,
		"target": def.target_count,
		"unlocked": is_unlocked,
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
		Log.warn("AchievementTracker: ピン留め失敗 — 未知のID [%s]" % id)
		return
	# 解除済み実績はピン留め不可
	if _unlocked.has(id):
		Log.debug("AchievementTracker: ピン留め失敗 — 解除済み [%s]" % id)
		return
	# 既にピン留め済みの場合は無視
	if id in _pinned_ids:
		return
	# 上限チェック
	if _pinned_ids.size() >= MAX_PIN_COUNT:
		Log.debug("AchievementTracker: ピン留め失敗 — 上限 %d 件に到達" % MAX_PIN_COUNT)
		return
	# ピン留めを追加する
	_pinned_ids.append(id)
	pinned_changed.emit()
	Log.info("AchievementTracker: ピン留め追加 [%s] (合計 %d 件)" % [id, _pinned_ids.size()])


## 実績のピン留めを解除する
func unpin_achievement(id: StringName) -> void:
	var idx: int = _pinned_ids.find(id)
	if idx < 0:
		return
	# ピン留めを解除する
	_pinned_ids.remove_at(idx)
	pinned_changed.emit()
	Log.info("AchievementTracker: ピン留め解除 [%s] (合計 %d 件)" % [id, _pinned_ids.size()])


## 指定実績がピン留めされているかを返す
func is_pinned(id: StringName) -> bool:
	return id in _pinned_ids


## チャレンジ実績のリセット処理
func handle_challenge_reset(reset_action: StringName) -> void:
	_record_db.reset_streaks_by_reset_on(reset_action)


# ========== RecordTab 用 API ==========

## 指定アクションの累積カウントを返す
func get_stat(action: StringName) -> int:
	return _record_db.get_count(action)


## 指定アクションの型名別内訳を返す
func get_stat_by_type(action: StringName) -> Dictionary:
	return _record_db.get_counts_by_type(action)


## 累積プレイ時間（秒）を返す
func get_play_time_seconds() -> float:
	return _record_db.play_time_seconds


## プレイ時間を加算する（セーブは呼び出し元が制御する）
func add_play_time(seconds: float) -> void:
	_record_db.add_play_time(seconds)


## 全レコードと実績状態をリセットする
func reset_records() -> void:
	_record_db.reset_all()
	_unlocked = {}
	_total_ap = 0
	_pinned_ids = []
	pinned_changed.emit()
	Log.info("AchievementTracker: 全レコード・実績をリセットしました")


# ========== 内部ロジック ==========

## RecordDatabase から実績定義の type に基づいて進捗値を導出する
func _derive_progress(def: AchievementDefinition) -> int:
	match def.type:
		AchievementDefinition.Type.CHALLENGE:
			return _record_db.get_streak(def.trigger_action, def.reset_on)
		_:
			# ONE_SHOT / COUNTER
			if def.unique_instances:
				return _record_db.get_unique_count(def.trigger_action)
			else:
				return _record_db.get_count(def.trigger_action)


## 実績を解除する（二重解除防止付き）
func _unlock_achievement(def: AchievementDefinition) -> void:
	if _unlocked.has(def.id):
		return
	_unlocked[def.id] = Time.get_unix_time_from_system()
	_total_ap += def.ap
	Log.info("AchievementTracker: 🏆 実績解除 [%s] %s (AP+%d, 合計AP=%d)" % [
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


# ========== セーブ/ロード（SaveManager から呼ばれる） ==========

## 実績状態を Dictionary で返す
func get_save_data() -> Dictionary:
	# unlocked の StringName キーを String に変換する
	var unlocked_data: Dictionary = {}
	for key: StringName in _unlocked:
		unlocked_data[String(key)] = _unlocked[key]
	var pinned_data: Array[String] = []
	for id: StringName in _pinned_ids:
		pinned_data.append(String(id))
	return {
		"unlocked": unlocked_data,
		"total_ap": _total_ap,
		"pinned_ids": pinned_data,
	}


## Dictionary から実績状態を復元する
func load_save_data(data: Dictionary) -> void:
	# unlocked の復元（JSONのキーは文字列になるため StringName に変換）
	_unlocked = {}
	for key: String in data.get("unlocked", {}).keys():
		_unlocked[StringName(key)] = data["unlocked"][key]
	_total_ap = int(data.get("total_ap", 0))
	# ピン留めIDの復元（解除済み・未定義の実績は除外する）
	_pinned_ids = []
	for id_str: String in data.get("pinned_ids", []):
		var id: StringName = StringName(id_str)
		if not _unlocked.has(id) and _def_map.has(id):
			_pinned_ids.append(id)
	pinned_changed.emit()
	Log.info("AchievementTracker: ロード完了 (解除済み=%d, AP=%d, ピン留め=%d)" % [
		_unlocked.size(), _total_ap, _pinned_ids.size()
	])


## RecordDatabase の状態を Dictionary で返す
func get_record_save_data() -> Dictionary:
	return _record_db.get_save_data()


## Dictionary から RecordDatabase の状態を復元する
func load_record_save_data(data: Dictionary) -> void:
	_record_db.load_save_data(data)
