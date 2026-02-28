## トースト通知のキュー管理マネージャー
## 実績解除時のトースト表示順序・戦闘中の遅延表示を制御する
class_name ToastManager extends VBoxContainer

# ---- 定数 ----
## トーストシーン（preload で事前読み込み）
const TOAST_SCENE: PackedScene = preload(
	"res://root/scenes/game_scene/achievement_master/ui/toast/achievement_toast.tscn"
)

# ---- 状態 ----
## 通常キュー（Bronze の通知を格納）
var _queue: Array[AchievementDefinition] = []
## 戦闘中に溜まった Bronze 通知キュー
var _combat_queue: Array[AchievementDefinition] = []
## 現在トーストを表示中かどうか
var _is_showing: bool = false
## 現在戦闘中かどうか
var _is_in_combat: bool = false
## プレイヤーへの参照キャッシュ
var _pawn: Node = null


## 初期化 — AchievementManager のシグナルを購読し、Pawn への接続を遅延実行する
func _ready() -> void:
	# AchievementManager の実績解除シグナルを購読する
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	# Pawn への接続を遅延実行する（Pawn が先に _ready される保証がないため）
	_connect_to_pawn.call_deferred()
	Log.info("ToastManager: 初期化完了")


## Pawn の戦闘状態シグナルを購読する
func _connect_to_pawn() -> void:
	_pawn = get_tree().get_first_node_in_group("player")
	if _pawn == null:
		return
	# 戦闘状態変化シグナルを接続する
	if _pawn.has_signal("combat_state_changed"):
		_pawn.combat_state_changed.connect(_on_combat_state_changed)
		Log.debug("ToastManager: Pawn の combat_state_changed に接続完了")


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


## 次のトーストを表示する（同時表示は最大1件）
func _try_show_next() -> void:
	# 既にトーストを表示中なら何もしない
	if _is_showing:
		return
	# キューが空なら何もしない
	if _queue.is_empty():
		return
	# キューの先頭から取り出して表示する
	var definition: AchievementDefinition = _queue.pop_front()
	_show_toast(definition)


## トーストを生成して表示する
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


## トースト完了時のコールバック — 次のトーストを表示する
func _on_toast_finished() -> void:
	_is_showing = false
	_try_show_next()
