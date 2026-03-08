## NPC の永続状態（ギフト受取済みフラグ等）を管理する Autoload
extends Node

# ---- 状態 ----
## ギフト受取済み NPC の ID セット { StringName: true }
var _gifts_claimed: Dictionary = {}


# ========== ライフサイクル ==========

## 初期化
func _ready() -> void:
	Log.info("NpcManager: 初期化完了 (ギフト受取済み=%d件)" % _gifts_claimed.size())
	# Saveable として登録する
	SaveManager.register_saveable(self)


# ========== ギフト API ==========

## 指定 NPC のギフトが受取済みかを返す
func is_gift_claimed(npc_id: StringName) -> bool:
	return _gifts_claimed.has(npc_id)


## 指定 NPC のギフトを受取済みとしてマークする
func mark_gift_claimed(npc_id: StringName) -> void:
	_gifts_claimed[npc_id] = true
	Log.info("NpcManager: ギフト受取済み — %s" % npc_id)


## 全状態をリセットする
func reset() -> void:
	_gifts_claimed = {}
	Log.info("NpcManager: 全状態をリセットしました")


# ========== セーブ/ロード（SaveManager から呼ばれる） ==========

## 現在の状態を Dictionary で返す
func get_save_data() -> Dictionary:
	var gift_ids: Array[String] = []
	for npc_id: StringName in _gifts_claimed:
		gift_ids.append(String(npc_id))
	return {"gifts_claimed": gift_ids}


## Dictionary から状態を復元する
func load_save_data(data: Dictionary) -> void:
	_gifts_claimed = {}
	for npc_id_str: String in data.get("gifts_claimed", []):
		_gifts_claimed[StringName(npc_id_str)] = true
	Log.info("NpcManager: ロード完了 (ギフト受取済み=%d件)" % _gifts_claimed.size())


# ========== Saveable インターフェース ==========

func get_save_keys() -> Array[StringName]:
	return [&"npc"]


func get_save_data_for_key(_key: StringName) -> Dictionary:
	return get_save_data()


func load_save_data_for_key(_key: StringName, data: Dictionary) -> void:
	load_save_data(data)


func reset_save_state() -> void:
	reset()
