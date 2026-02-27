## 【Beehave】パトロール地点で待機するアクションリーフ
## 待機中は速度をゼロにし、アニメーションはBlackboard経由でenemy.gdに委譲する
class_name WaitAtPatrolPoint
extends ActionLeaf

## 待機時間（秒）
@export var wait_time: float = 2.0

## 現在の待機経過時間
var _current_wait_time: float = 0.0

func before_run(actor: Node, _blackboard: Blackboard) -> void:
	_current_wait_time = 0.0
	# 待機開始時に速度を確実にゼロにする
	actor.velocity = Vector2.ZERO

func tick(actor: Node, blackboard: Blackboard) -> int:
	# 待機中は移動しない
	actor.velocity = Vector2.ZERO

	# アニメーション希望をIdleに設定
	blackboard.set_value(BlackBordValue.DESIRED_ANIM_STATE, "Idle")

	# 待機時間の経過判定
	_current_wait_time += get_physics_process_delta_time()
	if _current_wait_time >= wait_time:
		return SUCCESS

	return RUNNING
