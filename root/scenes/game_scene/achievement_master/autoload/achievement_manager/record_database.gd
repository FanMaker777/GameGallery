## レコードデータの蓄積・照会・永続化を担当する Resource
## 実績の状態（解除/ピン留め）は持たない — 生データのみを管理する
class_name RecordDatabase extends Resource

const SAVE_PATH: String = "user://achievement_master_records.tres"

## アクション種別ごとの累積カウント { String: int }
@export var counts: Dictionary = {}
## 型名別の内訳 { String: { String: int } }
@export var counts_by_type: Dictionary = {}
## アクション別のユニークインスタンスセット { String: Array }
@export var unique_sets: Dictionary = {}
## チャレンジストリーク { "trigger_action:reset_on": int }
@export var challenge_streaks: Dictionary = {}
## 累積プレイ時間（秒）
@export var play_time_seconds: float = 0.0


# ========== 記録 API ==========

## アクションを記録する（カウント加算 + type_name 内訳 + unique_set 更新）
func record(action: StringName, context: Dictionary = {}) -> void:
	var action_str: String = String(action)
	var amount: int = context.get(&"amount", 1)
	# カウント加算
	counts[action_str] = counts.get(action_str, 0) + amount
	# type_name 内訳
	var type_name: String = context.get(&"type_name", "")
	if not type_name.is_empty():
		if not counts_by_type.has(action_str):
			counts_by_type[action_str] = {}
		var type_dict: Dictionary = counts_by_type[action_str]
		type_dict[type_name] = type_dict.get(type_name, 0) + amount
	# unique_set 更新
	var instance_id: String = context.get(&"instance_id", "")
	if not instance_id.is_empty():
		if not unique_sets.has(action_str):
			unique_sets[action_str] = []
		var arr: Array = unique_sets[action_str]
		if instance_id not in arr:
			arr.append(instance_id)


## 累積カウントを返す
func get_count(action: StringName) -> int:
	return counts.get(String(action), 0)


## 型名別内訳を返す
func get_counts_by_type(action: StringName) -> Dictionary:
	return counts_by_type.get(String(action), {})


## ユニークインスタンス数を返す
func get_unique_count(action: StringName) -> int:
	var arr: Array = unique_sets.get(String(action), [])
	return arr.size()


# ========== ストリーク API ==========

## ストリークを加算する
func increment_streak(trigger: StringName, reset_on: StringName, amount: int = 1) -> void:
	var key: String = "%s:%s" % [String(trigger), String(reset_on)]
	challenge_streaks[key] = challenge_streaks.get(key, 0) + amount


## 現在のストリークを返す
func get_streak(trigger: StringName, reset_on: StringName) -> int:
	var key: String = "%s:%s" % [String(trigger), String(reset_on)]
	return challenge_streaks.get(key, 0)


## 指定 reset_on に該当するストリークを全てリセットする
func reset_streaks_by_reset_on(reset_on: StringName) -> void:
	var reset_suffix: String = ":" + String(reset_on)
	for key: String in challenge_streaks.keys():
		if key.ends_with(reset_suffix):
			challenge_streaks[key] = 0


# ========== プレイ時間 ==========

## プレイ時間を加算する
func add_play_time(seconds: float) -> void:
	play_time_seconds += seconds


# ========== 永続化 ==========

## ファイルに保存する
func save_to_file() -> void:
	var err: Error = ResourceSaver.save(self, SAVE_PATH)
	if err != OK:
		Log.warn("RecordDatabase: セーブ失敗 — %s" % error_string(err))
	else:
		Log.debug("RecordDatabase: セーブ完了")


## ファイルから読み込む（存在しない場合は新規インスタンスを返す）
static func load_from_file() -> RecordDatabase:
	if ResourceLoader.exists(SAVE_PATH):
		var res: Resource = ResourceLoader.load(SAVE_PATH)
		if res is RecordDatabase:
			Log.info("RecordDatabase: ロード完了")
			return res as RecordDatabase
		Log.warn("RecordDatabase: ロードしたリソースの型が不一致 — 新規作成")
	else:
		Log.info("RecordDatabase: セーブデータなし — 新規作成")
	return RecordDatabase.new()
