class_name Enemy extends CharacterBody2D

@onready var _blackboard: Blackboard = %Blackboard

func _ready():
	add_to_group("enemies")
	# blackboardに初期地点を待機地点として登録
	_blackboard.set_value(BlackBordValue.IDLE_POSITION, global_position)

func _physics_process(delta):
	# The behavior tree handles the movement logic, but you might need
	# additional code for animation, etc.
	pass


func _on_detect_area_body_entered(body: Node2D) -> void:
	_blackboard.set_value(BlackBordValue.IS_PLAYER_VISIBLE, true)


func _on_detect_area_body_exited(body: Node2D) -> void:
	_blackboard.set_value(BlackBordValue.IS_PLAYER_VISIBLE, false)
