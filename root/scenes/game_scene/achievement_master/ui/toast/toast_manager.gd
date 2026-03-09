## トースト通知のキュー管理マネージャー
## 実績解除時のトースト表示順序・戦闘中の遅延表示・アイテム入手通知を制御する
class_name ToastManager extends VBoxContainer

# ---- 定数 ----
## 実績トーストシーン（preload で事前読み込み）
const TOAST_SCENE: PackedScene = preload("uid://c3ib35gf3op2g")
## アイテムトーストシーン
const ITEM_TOAST_SCENE: PackedScene = preload(
	"res://root/scenes/game_scene/achievement_master/ui/item_toast/item_toast.tscn"
)

# ---- 状態 ----
## 実績キュー（Bronze の通知を格納）
var _queue: Array[AchievementDefinition] = []
## 戦闘中に溜まった Bronze 通知キュー
var _combat_queue: Array[AchievementDefinition] = []
## アイテム入手キュー
var _item_queue: Array[Dictionary] = []
## 現在トーストを表示中かどうか
var _is_showing: bool = false
## 現在戦闘中かどうか
var _is_in_combat: bool = false
## プレイヤーへの参照キャッシュ
var _player: Node = null
## 前回のアイテム所持数キャッシュ（差分検出用）
var _prev_counts: Dictionary = {}


## 初期化 — AchievementManager のシグナルを購読し、Player への接続を遅延実行する
func _ready() -> void:
	# AchievementManager の実績解除シグナルを購読する
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	# InventoryManager のバッグ変化シグナルを購読する
	InventoryManager.bag_changed.connect(_on_bag_changed)
	# 初期所持数をキャッシュする
	_sync_prev_counts()
	# Player への接続を遅延実行する（Player が先に _ready される保証がないため）
	_connect_to_player.call_deferred()
	Log.info("ToastManager: 初期化完了")


## Player の戦闘状態シグナルを購読する
func _connect_to_player() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		return
	# 戦闘状態変化シグナルを接続する
	if _player.has_signal("combat_state_changed"):
		_player.combat_state_changed.connect(_on_combat_state_changed)
		Log.debug("ToastManager: Player の combat_state_changed に接続完了")


## 実績解除時のコールバック — ランクに応じてキューに振り分ける
func _on_achievement_unlocked(_id: StringName, definition: AchievementDefinition) -> void:
	# Silver/Gold は優先キューの先頭に入れて即時表示する
	if definition.rank != AchievementDefinition.Rank.BRONZE:
		_queue.push_front(definition)
		_try_show_next()
		return
	# Bronze は戦闘中なら戦闘キューに溜める
	if _is_in_combat:
		_combat_queue.append(definition)
		Log.debug("ToastManager: 戦闘中のため Bronze を遅延キューに追加 [%s]" % definition.id)
		return
	# 戦闘中でなければ通常キューに追加する
	_queue.append(definition)
	_try_show_next()


## 戦闘状態変化時のコールバック
func _on_combat_state_changed(is_in_combat: bool) -> void:
	_is_in_combat = is_in_combat
	# 戦闘終了時に溜まった Bronze 通知をまとめて流す
	if not is_in_combat and not _combat_queue.is_empty():
		Log.debug("ToastManager: 戦闘終了 — 遅延キュー %d 件を流す" % _combat_queue.size())
		_queue.append_array(_combat_queue)
		_combat_queue.clear()
		_try_show_next()


## バッグ内容変化時にアイテム入手を検出してキューに追加する
func _on_bag_changed(id: StringName, new_count: int) -> void:
	# ロード時の一括通知は prev_counts を同期して無視する
	if id == &"":
		_sync_prev_counts()
		return
	# 差分を計算する
	var prev: int = _prev_counts.get(id, 0)
	var delta: int = new_count - prev
	# 所持数を更新する
	_prev_counts[id] = new_count
	# 消費・装備解除（差分が0以下）は無視する
	if delta <= 0:
		return
	# 素材以外（装備品の着脱等）は除外する
	var def: ItemDefinition = InventoryManager.get_definition(id)
	if def == null or def.get_category() != ItemDefinition.Category.MATERIAL:
		return
	# アイテムキューに追加する
	_item_queue.append({"name": def.name_ja, "amount": delta})
	_try_show_next()


## 現在のバッグ内容で prev_counts を同期する
func _sync_prev_counts() -> void:
	_prev_counts = InventoryManager.get_bag_contents()


## 次のトーストを表示する（同時表示は最大1件）
func _try_show_next() -> void:
	# 既にトーストを表示中なら何もしない
	if _is_showing:
		return
	# 実績トーストを優先する
	if not _queue.is_empty():
		var definition: AchievementDefinition = _queue.pop_front()
		_show_toast(definition)
		return
	# アイテムトーストを表示する
	if not _item_queue.is_empty():
		var data: Dictionary = _item_queue.pop_front()
		_show_item_toast(data)


## 実績トーストを生成して表示する
func _show_toast(definition: AchievementDefinition) -> void:
	_is_showing = true
	# トーストインスタンスを生成する
	var toast: PanelContainer = TOAST_SCENE.instantiate()
	add_child(toast)
	# 内容をセットする
	toast.setup(definition)
	# 完了シグナルを接続する
	toast.toast_finished.connect(_on_toast_finished)
	# アニメーションを再生する
	toast.play_animation()
	Log.debug("ToastManager: トースト表示 [%s] %s" % [definition.id, definition.name_ja])


## アイテムトーストを生成して表示する
func _show_item_toast(data: Dictionary) -> void:
	_is_showing = true
	var toast: PanelContainer = ITEM_TOAST_SCENE.instantiate()
	add_child(toast)
	toast.setup(data["name"], data["amount"])
	toast.toast_finished.connect(_on_toast_finished)
	toast.play_animation()
	Log.debug("ToastManager: アイテムトースト表示 — %s x%d" % [data["name"], data["amount"]])


## トースト完了時のコールバック — 次のトーストを表示する
func _on_toast_finished() -> void:
	_is_showing = false
	_try_show_next()
