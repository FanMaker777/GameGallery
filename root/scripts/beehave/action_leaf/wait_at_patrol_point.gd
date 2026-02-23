## 【Beehave】パトロール地点で待機するアクションリーフ
class_name WaitAtPatrolPoint
extends ActionLeaf

@export var wait_time: float = 2.0

var _current_wait_time: float = 0.0

@onready var _animated_sprite: AnimatedSprite2D = %AnimatedSprite

func tick(actor: Node, blackboard: Blackboard) -> int:
	_animated_sprite.play("Idle")
	
	# Increment wait time
	_current_wait_time += get_physics_process_delta_time()
	
	# Check if we've waited long enough
	if _current_wait_time >= wait_time:
		return SUCCESS
	
	return RUNNING
