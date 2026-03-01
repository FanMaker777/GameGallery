## 【Beehave】プレイヤーを追跡するアクションリーフ
## move_towardで滑らかに加速し、アニメーションはBlackboard経由でenemy.gdに委譲する
## 移動速度・攻撃範囲は Blackboard 経由で EnemyData から取得する
class_name ChasePlayer
extends ActionLeaf

## 加速度（velocity補間の速さ）
@export var acceleration: float = 400.0

func tick(actor: Node, blackboard: Blackboard) -> int:
	# 攻撃アニメーション中は移動せず即座に SUCCESS を返す
	if blackboard.get_value(BlackBoardValue.IS_ENEMY_ATTACKING, false):
		return SUCCESS

	# プレイヤーの現在位置を直接取得（Blackboard経由では古い可能性がある）
	var player: Node2D = actor.get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return FAILURE
	var player_pos: Vector2 = player.global_position
	# Blackboardも最新位置で更新（AttackPlayerなど他ノードが参照するため）
	blackboard.set_value(BlackBoardValue.PLAYER_POSITION, player_pos)

	# プレイヤーへの方向を算出
	var direction: Vector2 = (player_pos - actor.global_position).normalized()

	# Blackboard から追跡速度を取得する
	var move_speed: float = blackboard.get_value(BlackBoardValue.MOVE_SPEED)
	# 目標速度に向かって滑らかに加速（急な速度変更を防止）
	var target_velocity: Vector2 = direction * move_speed
	var delta: float = get_physics_process_delta_time()
	actor.velocity = actor.velocity.move_toward(target_velocity, acceleration * delta)
	actor.move_and_slide()

	# Blackboard から攻撃範囲を取得する
	var attack_range: float = blackboard.get_value(BlackBoardValue.ATTACK_RANGE)
	# 攻撃範囲内に到達したか判定
	var distance: float = actor.global_position.distance_to(player_pos)
	if distance <= attack_range:
		return SUCCESS

	# 追跡中 → アニメーション希望を設定
	blackboard.set_value(BlackBoardValue.DESIRED_ANIM_STATE, "Run")
	return RUNNING

## 追跡終了時に速度をクリア
func after_run(actor: Node, _blackboard: Blackboard) -> void:
	actor.velocity = Vector2.ZERO


## 追跡が中断された際に速度をクリアする
func interrupt(actor: Node, _blackboard: Blackboard) -> void:
	actor.velocity = Vector2.ZERO
	super(actor, _blackboard)
