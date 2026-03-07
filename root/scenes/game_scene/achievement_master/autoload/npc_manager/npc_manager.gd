## NPC の永続状態（ギフト受取済みフラグ等）を管理する Autoload
extends Node

# ---- 定数 ----
## セーブファイルのパス（user:// 領域のため UID 不可）
const SAVE_PATH: String = "user://achievement_master_npc.save"

# ---- 状態 ----
## ギフト受取済み NPC の ID セット { StringName: true }
var _gifts_claimed: Dictionary = {}


# ========== ライフサイクル ==========

## 初期化 — セーブデータを復元する
func _ready() -> void:
	_load()
	Log.info("NpcManager: 初期化完了 (ギフト受取済み=%d件)" % _gifts_claimed.size())


# ========== ギフト API ==========

## 指定 NPC のギフトが受取済みかを返す
func is_gift_claimed(npc_id: StringName) -> bool:
	return _gifts_claimed.has(npc_id)


## 指定 NPC のギフトを受取済みとしてマークし、セーブする
func mark_gift_claimed(npc_id: StringName) -> void:
	_gifts_claimed[npc_id] = true
	_save()
	Log.info("NpcManager: ギフト受取済み — %s" % npc_id)


## 全状態をリセットしてセーブする
func reset() -> void:
	_gifts_claimed = {}
	_save()
	Log.info("NpcManager: 全状態をリセットしました")


# ========== セーブ/ロード ==========

## NPC 状態を JSON ファイルに保存する
func _save() -> void:
	# StringName を String 配列に変換する
	var gift_ids: Array[String] = []
	for npc_id: StringName in _gifts_claimed:
		gift_ids.append(String(npc_id))
	var data: Dictionary = {"gifts_claimed": gift_ids}
	# ファイルに書き出す
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		Log.warn("NpcManager: セーブ失敗 — %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	Log.debug("NpcManager: セーブ完了")


## JSON ファイルから NPC 状態を復元する
func _load() -> void:
	# セーブファイルが存在しない場合は何もしない
	if not FileAccess.file_exists(SAVE_PATH):
		Log.info("NpcManager: セーブデータなし — 初回起動")
		return
	# ファイルを読み込む
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		Log.warn("NpcManager: ロード失敗 — %s" % FileAccess.get_open_error())
		return
	var json_string: String = file.get_as_text()
	file.close()
	# JSON をパースする
	var json: JSON = JSON.new()
	var error: Error = json.parse(json_string)
	if error != OK:
		Log.warn("NpcManager: JSONパース失敗 — %s" % json.get_error_message())
		return
	# ギフト受取済みフラグを復元する
	var data: Dictionary = json.data
	_gifts_claimed = {}
	for npc_id_str: String in data.get("gifts_claimed", []):
		_gifts_claimed[StringName(npc_id_str)] = true
	Log.info("NpcManager: ロード完了 (ギフト受取済み=%d件)" % _gifts_claimed.size())
