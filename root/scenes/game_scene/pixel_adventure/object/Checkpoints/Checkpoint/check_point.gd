## プラットフォーマーで使用するチェックポイント
class_name CheckPoint extends Area2D

@onready var _animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D

func _ready() -> void:
	# 最初はフラッグがない状態に設定
	_animated_sprite_2d.play("NoFlag")

func _on_body_entered(body: Node2D) -> void:
	# 侵入したのがプレイヤーの場合
	if body is Player:
		# また接触メソッドを実行しないよう、モニタリングを無効化
		set_deferred("monitoring",false)
		# フラッグが出現するアニメーションを再生
		_animated_sprite_2d.play("FlagOut")
		# フラッグ出現アニメーションが終了するまで待機
		await _animated_sprite_2d.animation_finished
		# フラッグがたなびくアニメーションを再生
		_animated_sprite_2d.play("Idle")
