## トースト通知のキュー管理マネージャー
## 実績解除時のトースト表示順序・アイテム入手通知を制御する
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
## アイテム入手キュー
var _item_queue: Array[Dictionary] = []
## 現在トーストを表示中かどうか
var _is_showing: bool = false
## 前回のアイテム所持数キャッシュ（差分検出用）
var _prev_counts: Dictionary = {}


## 初期化 — AchievementManager のシグナルを購読する
func _ready() -> void:
	# AchievementManager の実績解除シグナルを購読する
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	# InventoryManager のバッグ変化シグナルを購読する
	InventoryManager.bag_changed.connect(_on_bag_changed)
	# 初期所持数をキャッシュする
	_sync_prev_counts()
	Log.info("ToastManager: 初期化完了")


## 実績解除時のコールバック — ランクに応じてキューに振り分ける
func _on_achievement_unlocked(_id: StringName, definition: AchievementDefinition) -> void:
	# Silver/Gold は優先キューの先頭に入れて即時表示する
	if definition.rank != AchievementDefinition.Rank.BRONZE:
		_queue.push_front(definition)
	else:
		_queue.append(definition)
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
