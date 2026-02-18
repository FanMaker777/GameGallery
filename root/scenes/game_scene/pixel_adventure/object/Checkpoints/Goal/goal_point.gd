## プラットフォーマーで使用するゴール
class_name GoalPoint extends Area2D

@onready var _animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 最初は待機アニメーションを再生
	_animated_sprite_2d.play("Idle")

func _on_body_entered(body: Node2D) -> void:
	# 侵入したのがプレイヤーの場合
	if body is Player:
		# また接触メソッドを実行しないよう、モニタリングを無効化
		set_deferred("monitoring",false)
		# フラッグが出現するアニメーションを再生
		_animated_sprite_2d.play("Pressed")
