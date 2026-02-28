## ピン留め実績1件分のHUDウィジェット
## 実績名と進捗バーを表示し、達成時にはフラッシュアニメーションを再生する
class_name PinnedAchievementItem extends PanelContainer

# ---- シグナル ----
## 達成アニメーションが完了したときに発火する
signal unlock_animation_finished

# ---- 定数 ----
## 進捗Tweenのアニメーション時間（秒）
const PROGRESS_TWEEN_DURATION: float = 0.3
## 達成フラッシュの色
const FLASH_COLOR: Color = Color(0.2, 0.9, 0.3, 1.0)
## フラッシュ表示時間（秒）
const FLASH_DURATION: float = 0.4
## フェードアウト時間（秒）
const FADEOUT_DURATION: float = 0.6

# ---- ノードキャッシュ ----
## 実績名ラベル
@onready var _name_label: Label = %NameLabel
## 進捗バー
@onready var _progress_bar: ProgressBar = %ProgressBar
## 進捗テキストラベル
@onready var _progress_label: Label = %ProgressLabel

# ---- 状態 ----
## この項目が保持する実績ID
var _achievement_id: StringName = &""


## 実績ID・名前・進捗をセットアップする
func setup(definition: AchievementDefinition, current: int, target: int) -> void:
	# 実績IDを保持する
	_achievement_id = definition.id
	# UI要素に値をセットする
	_name_label.text = definition.name_ja
	_progress_bar.max_value = target
	_progress_bar.value = current
	_progress_label.text = "%d/%d" % [current, target]


## 保持する実績IDを返す
func get_achievement_id() -> StringName:
	return _achievement_id


## 進捗をTweenアニメーション付きで更新する
func update_progress(current: int, target: int) -> void:
	# バーの最大値とラベルを更新する
	_progress_bar.max_value = target
	_progress_label.text = "%d/%d" % [current, target]
	# Tweenアニメーションで進捗バーを滑らかに遷移させる
	var tween: Tween = create_tween()
	tween.tween_property(_progress_bar, "value", float(current), PROGRESS_TWEEN_DURATION)


## 達成時の緑フラッシュ → フェードアウトアニメーションを再生する
func play_unlock_animation() -> void:
	# 進捗を最大値にする
	_progress_bar.value = _progress_bar.max_value
	_progress_label.text = "%d/%d" % [int(_progress_bar.max_value), int(_progress_bar.max_value)]
	# 緑フラッシュ → フェードアウト
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", FLASH_COLOR, FLASH_DURATION * 0.5)
	tween.tween_property(self, "modulate", Color.WHITE, FLASH_DURATION * 0.5)
	tween.tween_interval(0.3)
	tween.tween_property(self, "modulate:a", 0.0, FADEOUT_DURATION)
	tween.tween_callback(_on_unlock_animation_finished)


## 達成アニメーション完了時の処理
func _on_unlock_animation_finished() -> void:
	unlock_animation_finished.emit()
	queue_free()
