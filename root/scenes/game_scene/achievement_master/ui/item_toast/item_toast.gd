## 1件分のアイテム入手トースト通知パネル
## アイテム名と個数を表示し、スライドアニメーションで出入りする
class_name ItemToast extends PanelContainer

# ---- シグナル ----
## トーストのアニメーションが完了したときに発火する
signal toast_finished

# ---- 定数 ----
## トースト表示時間（秒）
const DISPLAY_DURATION: float = 1.5
## スライドアニメーション時間（秒）
const SLIDE_DURATION: float = 0.2
## スライド移動距離（ピクセル）
const SLIDE_OFFSET: float = 200.0

# ---- ノードキャッシュ ----
## メッセージラベル
@onready var _message_label: Label = %MessageLabel


## アイテム名と個数からトースト内容をセットする
func setup(item_name: String, amount: int) -> void:
	_message_label.text = "%s x%d を入手!" % [item_name, amount]


## スライドイン → 表示 → スライドアウトのアニメーションを再生する
func play_animation() -> void:
	# 初期位置を画面右外に設定する
	var original_x: float = position.x
	position.x = original_x + SLIDE_OFFSET
	modulate.a = 0.0

	# スライドイン
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "position:x", original_x, SLIDE_DURATION)
	tween.parallel().tween_property(self, "modulate:a", 1.0, SLIDE_DURATION * 0.5)

	# 表示時間待機
	tween.tween_interval(DISPLAY_DURATION)

	# スライドアウト
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "position:x", original_x + SLIDE_OFFSET, SLIDE_DURATION)
	tween.parallel().tween_property(self, "modulate:a", 0.0, SLIDE_DURATION)

	# アニメーション完了後にシグナル発火して自身を削除する
	tween.tween_callback(_on_animation_finished)


## アニメーション完了時の処理
func _on_animation_finished() -> void:
	toast_finished.emit()
	queue_free()
