## 【Beehave】パトロール地点へ移動するアクションリーフ
class_name MoveToPatrolPoint
extends ActionLeaf

@export var move_speed: float = 50.0
@export var point_reach_distance: float = 10.0

var current_point_index: int = 0

@onready var _animated_sprite: AnimatedSprite2D = %AnimatedSprite

func tick(actor: Node, blackboard: Blackboard) -> int:
	
	# Calculate direction to the point
	var target_pos = blackboard.get_value(BlackBordValue.IDLE_POSITION)
	var direction = (target_pos - actor.global_position).normalized()
	
	# Move toward the patrol point
	actor.global_position += direction * move_speed * get_physics_process_delta_time()
	_animated_sprite.play("Run")
	# Rotate to face direction
	actor.rotation = lerp_angle(actor.rotation, atan2(direction.y, direction.x), 0.1)
	
	# Check if we've reached the point
	var distance = actor.global_position.distance_to(target_pos)
	if distance <= point_reach_distance:
		# Move to the next patrol point
		blackboard.set_value("patrol_point_reached", true)
		return SUCCESS
	
	return RUNNING
