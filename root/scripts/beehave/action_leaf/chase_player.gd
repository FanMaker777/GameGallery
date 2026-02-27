## 【Beehave】プレイヤーを追跡するアクションリーフ
## move_towardで滑らかに加速し、アニメーションはBlackboard経由でenemy.gdに委譲する
class_name ChasePlayer
extends ActionLeaf

## 追跡時の最大移動速度
@export var move_speed: float = 125.0
## 攻撃開始距離
@export var attack_range: float = 75.0
## 加速度（velocity補間の速さ）
@export var acceleration: float = 400.0

func tick(actor: Node, blackboard: Blackboard) -> int:
	# blackboardからプレイヤー位置を取得
	var player_pos: Variant = blackboard.get_value(BlackBordValue.PLAYER_POSITION)
	if not player_pos:
		return FAILURE

	# プレイヤーへの方向を算出
	var direction: Vector2 = (player_pos - actor.global_position).normalized()

	# 目標速度に向かって滑らかに加速（急な速度変更を防止）
	var target_velocity: Vector2 = direction * move_speed
	var delta: float = get_physics_process_delta_time()
	actor.velocity = actor.velocity.move_toward(target_velocity, acceleration * delta)
	actor.move_and_slide()

	# 攻撃範囲内に到達したか判定
	var distance: float = actor.global_position.distance_to(player_pos)
	if distance <= attack_range:
		return SUCCESS

	# 追跡中 → アニメーション希望を設定
	blackboard.set_value(BlackBordValue.DESIRED_ANIM_STATE, "Run")
	return RUNNING

## 追跡終了時に速度をクリア
func after_run(actor: Node, _blackboard: Blackboard) -> void:
	actor.velocity = Vector2.ZERO
