## 【Beehave】パトロール地点で待機するアクションリーフ
class_name WaitAtPatrolPoint
extends ActionLeaf

@export var wait_time: float = 2.0
var current_wait_time: float = 0.0
@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite

func tick(actor: Node, blackboard: Blackboard) -> int:
	animated_sprite.play("Idle")
	
	# Increment wait time
	current_wait_time += get_physics_process_delta_time()
	
	# Check if we've waited long enough
	if current_wait_time >= wait_time:
		return SUCCESS
	
	return RUNNING
