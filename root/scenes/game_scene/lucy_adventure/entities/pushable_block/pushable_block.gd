## プレイヤーが押すことができるブロック（岩）の物理挙動を管理する
## 重力による落下と摩擦による減速を処理する
class_name Rock extends CharacterBody2D

## 物理フレーム毎の移動処理（重力適用と水平速度の減衰）
func _physics_process(delta: float) -> void:
	# 空中にいる場合は重力を適用する
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	# 水平速度を徐々に減速させる
	velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
	move_and_slide()
