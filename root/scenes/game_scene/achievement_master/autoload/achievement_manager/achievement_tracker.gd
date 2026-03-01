## 実績の進捗管理・解除判定・ピン留め・セーブ/ロードを担当する
class_name AchievementTracker extends Node

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
## 合計AP
var _total_ap: int = 0
## ピン留め中の実績ID配列（最大 MAX_PIN_COUNT 件）
var _pinned_ids: Array[StringName] = []


# ========== 初期化 ==========

## データベース構築とセーブデータ復元を行う（親ノードの _ready から呼ばれる）
func initialize() -> void:
	for def: AchievementDefinition in _database.achievements:
		_def_map[def.id] = def
	_load_progress()
	Log.info("AchievementTracker: 初期化完了 (%d件の実績定義)" % _def_map.size())


# ========== 公開 API ==========

## アクションを記録し、該当する実績の進捗を更新する
func record_action(action: StringName, context: Dictionary = {}) -> void:
	for def: AchievementDefinition in _database.achievements:
		if def.trigger_action != action:
			continue
		if _unlocked.has(def.id):
			continue
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
	_save_progress()
	Log.info("AchievementTracker: ピン留め追加 [%s] (合計 %d 件)" % [id, _pinned_ids.size()])


## 実績のピン留めを解除する
func unpin_achievement(id: StringName) -> void:
	var idx: int = _pinned_ids.find(id)
	if idx < 0:
		return
	# ピン留めを解除する
	_pinned_ids.remove_at(idx)
	pinned_changed.emit()
	_save_progress()
	Log.info("AchievementTracker: ピン留め解除 [%s] (合計 %d 件)" % [id, _pinned_ids.size()])


## 指定実績がピン留めされているかを返す
func is_pinned(id: StringName) -> bool:
	return id in _pinned_ids


## チャレンジ実績のリセット処理
func handle_challenge_reset(reset_action: StringName) -> void:
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


# ========== 内部ロジック ==========

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
	# 自動セーブ
	_save_progress()


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
		Log.warn("AchievementTracker: セーブ失敗 — %s" % FileAccess.get_open_error())
		return
	file.store_string(json_string)
	file.close()
	Log.debug("AchievementTracker: セーブ完了")


## JSONファイルから進捗データを復元する
func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		Log.info("AchievementTracker: セーブデータなし — 初回起動")
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		Log.warn("AchievementTracker: ロード失敗 — %s" % FileAccess.get_open_error())
		return
	var json_string: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	var error: Error = json.parse(json_string)
	if error != OK:
		Log.warn("AchievementTracker: JSONパース失敗 — %s" % json.get_error_message())
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
	Log.info("AchievementTracker: ロード完了 (解除済み=%d, AP=%d, ピン留め=%d)" % [
		_unlocked.size(), _total_ap, _pinned_ids.size()
	])
