## 【Beehave】パトロール地点へ移動するアクションリーフ
## move_towardで滑らかに加速し、アニメーションはBlackboard経由でenemy.gdに委譲する
class_name MoveToPatrolPoint
extends ActionLeaf

## パトロール時の最大移動速度
@export var move_speed: float = 50.0
## 目的地到達判定距離
@export var point_reach_distance: float = 10.0
## 加速度（velocity補間の速さ、追跡より緩やか）
@export var acceleration: float = 200.0

func tick(actor: Node, blackboard: Blackboard) -> int:
	# パトロール目的地を取得
	var target_pos: Vector2 = blackboard.get_value(BlackBoardValue.IDLE_POSITION)
	var direction: Vector2 = (target_pos - actor.global_position).normalized()

	# 目標速度に向かって滑らかに加速
	var target_velocity: Vector2 = direction * move_speed
	var delta: float = get_physics_process_delta_time()
	actor.velocity = actor.velocity.move_toward(target_velocity, acceleration * delta)
	actor.move_and_slide()

	# アニメーション希望を設定
	blackboard.set_value(BlackBoardValue.DESIRED_ANIM_STATE, "Run")

	# 目的地到達判定
	var distance: float = actor.global_position.distance_to(target_pos)
	if distance <= point_reach_distance:
		return SUCCESS

	return RUNNING

## パトロール移動終了時の速度クリア
func after_run(actor: Node, _blackboard: Blackboard) -> void:
	actor.velocity = Vector2.ZERO
