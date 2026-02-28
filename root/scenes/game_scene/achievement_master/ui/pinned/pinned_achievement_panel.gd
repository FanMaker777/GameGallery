## ピン留め実績のHUD表示パネル
## AchievementManager のシグナルを購読し、ピン留め実績の進捗をリアルタイム表示する
class_name PinnedAchievementPanel extends MarginContainer

# ---- 定数 ----
## PinnedAchievementItem シーン
const ITEM_SCENE: PackedScene = preload(
	"res://root/scenes/game_scene/achievement_master/ui/pinned/pinned_achievement_item.tscn"
)

# ---- ノードキャッシュ ----
## アイテムを格納するコンテナ
@onready var _item_container: VBoxContainer = %ItemContainer

# ---- 状態 ----
## { id: PinnedAchievementItem } のO(1)ルックアップマップ
var _item_map: Dictionary = {}
## 達成アニメーション中フラグ（pinned_changed による即時再構築を遅延する）
var _is_animating_unlock: bool = false


## 初期化 — AchievementManager のシグナルを遅延接続する
func _ready() -> void:
	# AchievementManager の初期化完了を待つために遅延接続する
	_connect_signals.call_deferred()


## AchievementManager のシグナルを購読する
func _connect_signals() -> void:
	AchievementManager.pinned_changed.connect(_on_pinned_changed)
	AchievementManager.achievement_progress_updated.connect(_on_progress_updated)
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	# 初回構築
	_rebuild_items()
	Log.info("PinnedAchievementPanel: シグナル接続完了")


## ピン留め状態変更時のハンドラ
func _on_pinned_changed() -> void:
	if _is_animating_unlock:
		return
	_rebuild_items()


## 進捗更新時のハンドラ
func _on_progress_updated(id: StringName, current: int, target: int) -> void:
	var item: PinnedAchievementItem = _item_map.get(id)
	if item == null:
		return
	item.update_progress(current, target)


## 実績解除時のハンドラ
func _on_achievement_unlocked(id: StringName, _definition: AchievementDefinition) -> void:
	var item: PinnedAchievementItem = _item_map.get(id)
	if item == null:
		return
	# アニメーション中フラグを立てて pinned_changed による即時再構築を遅延する
	_is_animating_unlock = true
	item.unlock_animation_finished.connect(_on_unlock_animation_finished)
	item.play_unlock_animation()


## 達成アニメーション完了後に再構築する
func _on_unlock_animation_finished() -> void:
	_is_animating_unlock = false
	_rebuild_items()


## ピン留め実績アイテムを再構築する
func _rebuild_items() -> void:
	# 既存の子ノードを全て削除する
	_item_map.clear()
	for child: Node in _item_container.get_children():
		child.queue_free()
	# ピン留めIDを取得してアイテムを生成する
	var pinned_ids: Array[StringName] = AchievementManager.get_pinned_ids()
	if pinned_ids.is_empty():
		visible = false
		return
	visible = true
	for id: StringName in pinned_ids:
		var def: AchievementDefinition = AchievementManager.get_definition(id)
		if def == null:
			continue
		var progress: Dictionary = AchievementManager.get_progress(id)
		var current: int = progress.get("current", 0)
		var target: int = progress.get("target", def.target_count)
		# アイテムを生成して追加する
		var item: PinnedAchievementItem = ITEM_SCENE.instantiate()
		_item_container.add_child(item)
		item.setup(def, current, target)
		_item_map[id] = item
