## セーブ/ロードの一元管理を担当する Autoload
## 全マネージャーのデータを統合 JSON として保存・復元する
extends Node

# ---- シグナル ----
## セーブ完了時に発火する
signal save_completed(slot: int, success: bool)
## ロード完了時に発火する
signal load_completed(slot: int, success: bool)

# ---- 定数 ----
## セーブファイルのベースパス
const SAVE_BASE_PATH: String = "user://save_slot_%d.save"
## セーブスロット数（0=オートセーブ, 1-3=手動）
const SLOT_COUNT: int = 4
## オートセーブ間隔（秒）
const AUTO_SAVE_INTERVAL: float = 30.0
## セーブデータバージョン
const SAVE_VERSION: int = 1

# ---- 状態 ----
## オートセーブタイマー
var _auto_save_accumulator: float = 0.0
## ロード処理中フラグ（二重ロード防止）
var _is_loading: bool = false


# ========== ライフサイクル ==========

func _ready() -> void:
	# オートセーブスロットからデータを復元する
	_load_auto_save()
	Log.info("SaveManager: 初期化完了")


func _process(delta: float) -> void:
	_auto_save_accumulator += delta
	if _auto_save_accumulator >= AUTO_SAVE_INTERVAL:
		_auto_save_accumulator -= AUTO_SAVE_INTERVAL
		# プレイヤーが存在しない場合（メインメニュー等）はオートセーブしない
		if get_tree().get_nodes_in_group("player").is_empty():
			return
		auto_save()


# ========== 公開 API ==========

## 指定スロットにセーブする
func save_to_slot(slot: int) -> bool:
	if slot < 0 or slot >= SLOT_COUNT:
		Log.warn("SaveManager: 無効なスロット番号 — %d" % slot)
		return false
	var data: Dictionary = _collect_save_data()
	var path: String = SAVE_BASE_PATH % slot
	var json_string: String = JSON.stringify(data, "\t")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		Log.warn("SaveManager: セーブ失敗 — %s" % FileAccess.get_open_error())
		save_completed.emit(slot, false)
		return false
	file.store_string(json_string)
	file.close()
	Log.info("SaveManager: スロット%d にセーブ完了" % slot)
	save_completed.emit(slot, true)
	return true


## 指定スロットからロードする（シーン遷移を伴う）
func load_from_slot(slot: int) -> bool:
	if _is_loading:
		Log.warn("SaveManager: ロード処理中のため無視")
		return false
	if slot < 0 or slot >= SLOT_COUNT:
		Log.warn("SaveManager: 無効なスロット番号 — %d" % slot)
		return false
	var path: String = SAVE_BASE_PATH % slot
	var data: Dictionary = _read_save_file(path)
	if data.is_empty():
		Log.warn("SaveManager: スロット%d のデータが空" % slot)
		load_completed.emit(slot, false)
		return false
	_is_loading = true
	# 各マネージャーにデータを配布する
	_distribute_save_data(data)
	# プレイヤーデータとマップ遷移を処理する
	var player_data: Dictionary = data.get("player", {})
	var map_path: String = player_data.get("map_path", "")
	if map_path.is_empty():
		# マップ情報がない場合は村にフォールバック
		map_path = PathConsts.AM_VILLAGE_SCENE
	# メニューを閉じてシーン遷移する
	GameManager.load_scene_with_transition(map_path)
	# シーン遷移完了後にプレイヤー状態を復元する
	await get_tree().scene_changed
	await get_tree().process_frame
	_restore_player_state(player_data)
	_is_loading = false
	Log.info("SaveManager: スロット%d からロード完了" % slot)
	load_completed.emit(slot, true)
	return true


## オートセーブを実行する（スロット0）
func auto_save() -> void:
	save_to_slot(0)


## 指定スロットのメタ情報を返す
func get_slot_info(slot: int) -> Dictionary:
	if slot < 0 or slot >= SLOT_COUNT:
		return {}
	var path: String = SAVE_BASE_PATH % slot
	var data: Dictionary = _read_save_file(path)
	if data.is_empty():
		return {}
	return data.get("meta", {})


## 指定スロットにデータがあるかを返す
func is_slot_used(slot: int) -> bool:
	if slot < 0 or slot >= SLOT_COUNT:
		return false
	return FileAccess.file_exists(SAVE_BASE_PATH % slot)


## 全マネージャーを初期状態にリセットする（ニューゲーム用）
func reset_all_managers() -> void:
	AchievementManager.reset_records()
	RewardManager.reset_rewards()
	InventoryManager.reset_inventory()
	NpcManager.reset()
	Log.info("SaveManager: 全マネージャーをリセット")


## 指定スロットのセーブデータを削除する
func delete_slot(slot: int) -> bool:
	if slot < 0 or slot >= SLOT_COUNT:
		return false
	var path: String = SAVE_BASE_PATH % slot
	if not FileAccess.file_exists(path):
		return false
	DirAccess.remove_absolute(path)
	Log.info("SaveManager: スロット%d を削除" % slot)
	return true


# ========== データ収集・配布 ==========

## 全マネージャーからセーブデータを収集する
func _collect_save_data() -> Dictionary:
	# プレイヤー状態を収集する
	var player_data: Dictionary = _collect_player_state()
	# メタ情報を構築する
	var meta: Dictionary = {
		"timestamp": Time.get_datetime_string_from_system(),
		"map_name": player_data.get("map_name", ""),
		"play_time_seconds": AchievementManager.get_play_time_seconds(),
		"version": SAVE_VERSION,
	}
	return {
		"meta": meta,
		"achievement": AchievementManager.get_save_data(),
		"record": AchievementManager.get_record_save_data(),
		"reward": RewardManager.get_save_data(),
		"inventory": InventoryManager.get_save_data(),
		"npc": NpcManager.get_save_data(),
		"player": player_data,
	}


## セーブデータを全マネージャーに配布する
func _distribute_save_data(data: Dictionary) -> void:
	if data.has("achievement"):
		AchievementManager.load_save_data(data["achievement"])
	if data.has("record"):
		AchievementManager.load_record_save_data(data["record"])
	if data.has("reward"):
		RewardManager.load_save_data(data["reward"])
	if data.has("inventory"):
		InventoryManager.load_save_data(data["inventory"])
	if data.has("npc"):
		NpcManager.load_save_data(data["npc"])


# ========== プレイヤー状態 ==========

## プレイヤーの現在状態を収集する
func _collect_player_state() -> Dictionary:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return {}
	var pawn: Node2D = players[0] as Node2D
	if pawn == null:
		return {}
	# 現在のシーンからマップパスを取得する
	var current_scene: Node = get_tree().current_scene
	var map_path: String = ""
	var map_name: String = ""
	if current_scene != null:
		map_path = current_scene.scene_file_path
		map_name = map_path.get_file().get_basename()
	return {
		"hp": pawn.hp,
		"position": {"x": pawn.global_position.x, "y": pawn.global_position.y},
		"map_path": map_path,
		"map_name": map_name,
	}


## シーン遷移後にプレイヤー状態を復元する
func _restore_player_state(player_data: Dictionary) -> void:
	if player_data.is_empty():
		return
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		Log.warn("SaveManager: プレイヤーが見つからないため復元をスキップ")
		return
	var pawn: CharacterBody2D = players[0] as CharacterBody2D
	if pawn == null:
		return
	# 位置を復元する
	var pos: Dictionary = player_data.get("position", {})
	if not pos.is_empty():
		pawn.global_position = Vector2(
			float(pos.get("x", 0.0)),
			float(pos.get("y", 0.0))
		)
	# HPを復元する（_ready() でリセットされた後に上書きする）
	if player_data.has("hp"):
		pawn.hp = int(player_data["hp"])
		pawn.health_changed.emit(pawn.hp, pawn.get_effective_max_hp())
	Log.info("SaveManager: プレイヤー状態を復元 (HP=%d, pos=%s)" % [
		pawn.hp, pawn.global_position
	])


# ========== ファイル I/O ==========

## セーブファイルを読み込んで Dictionary を返す（存在しない/エラー時は空辞書）
func _read_save_file(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json_string: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	var error: Error = json.parse(json_string)
	if error != OK:
		Log.warn("SaveManager: JSONパース失敗 — %s" % json.get_error_message())
		return {}
	if json.data is Dictionary:
		return json.data as Dictionary
	return {}


# ========== オートセーブ復元 ==========

## 起動時にオートセーブスロットからデータを復元する（シーン遷移なし）
func _load_auto_save() -> void:
	var path: String = SAVE_BASE_PATH % 0
	var data: Dictionary = _read_save_file(path)
	if data.is_empty():
		Log.info("SaveManager: オートセーブデータなし — 初回起動")
		return
	# マネージャーにデータを配布する（シーン遷移は行わない）
	_distribute_save_data(data)
	Log.info("SaveManager: オートセーブから復元完了")
