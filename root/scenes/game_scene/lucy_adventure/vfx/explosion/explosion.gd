## 爆発エフェクトの再生と自動削除を管理する
## ランダムな爆発アニメーションを再生し、完了後に自身を削除する
extends Node2D

# ---- シグナル ----
## 爆発アニメーションが完了したときに発火する
signal finished

# ---- ノード参照 ----
## 爆発のアニメーションスプライト
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
## 火花パーティクルエフェクト
@onready var sparkes: GPUParticles2D = $Sparkes

## 初期化処理（ランダムな爆発アニメーションを再生し、完了後に自身を削除する）
func _ready() -> void:
	# ランダムなアニメーションを選択して再生する
	var animations: Array = sprite.sprite_frames.get_animation_names()
	sprite.play(animations.pick_random())
	sparkes.emitting = true
	# アニメーション完了を待機する
	await sprite.animation_finished
	sprite.queue_free()
	emit_signal("finished")
	# パーティクルの再生完了を待ってから削除する
	await get_tree().create_timer(5.0).timeout
	queue_free()
