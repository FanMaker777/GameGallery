## ステージクリア用のゴールフラグを管理する
## プレイヤーが接触するとフラグが起動し、プレイヤーを停止させる
class_name EndFlag extends Area2D

# ---- ノード参照 ----
## フラグのアニメーションスプライト
@onready var _animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
## クリア時のパーティクルエフェクト
@onready var _gpu_particles_2d: GPUParticles2D = $GPUParticles2D

## 初期化処理（デフォルトアニメーション再生とプレイヤー接触シグナル接続）
func _ready() -> void:
	_animated_sprite_2d.play("default")

	# プレイヤーが接触したらフラグを起動し、プレイヤーを停止させる
	body_entered.connect(func _on_body_entered(body: Node2D) -> void:
		if body is Player:
			activate()
			body.deactivate()
	)


## フラグを起動し、風アニメーションとパーティクルを再生する
func activate() -> void:
	AudioManager.play_se(AudioConsts.SE_GOAL_REACH)
	_animated_sprite_2d.play("wind")

	# This controls the little squash and stretch animation when touching the flag.
	# It's the same technique as the player jump tween from the previous module.
	var tween := create_tween()
	tween.tween_property(_animated_sprite_2d, "scale", Vector2(1.2,0.8), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_animated_sprite_2d, "scale", Vector2(0.8,1.2), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_animated_sprite_2d, "scale", Vector2.ONE, 0.15)
	_gpu_particles_2d.emitting = true
