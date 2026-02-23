class_name Enemy extends CharacterBody2D

@export_category("Status")
@export var move_speed: float = 100.0
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 1.0

@onready var _blackboard: Blackboard = %Blackboard
@onready var _detect_area: Area2D = %DetectArea

func _ready():
	add_to_group("enemies")
	# blackboardに初期地点を待機地点として登録
	_blackboard.set_value(BlackBordValue.IDLE_POSITION, global_position)
	# blackboardにステータスを登録
	_blackboard.set_value(BlackBordValue.MOVE_SPEED, move_speed)
	_blackboard.set_value(BlackBordValue.ATTACK_RANGE, attack_range)
	_blackboard.set_value(BlackBordValue.ATTACK_COOLDOWN, attack_cooldown)
	
	_detect_area.body_entered.connect(func(body:Node2D) -> void:
		Log.debug("_detect_area.body_entered")
		_blackboard.set_value(BlackBordValue.IS_PLAYER_VISIBLE, true)
		)
	
	_detect_area.body_exited.connect(func(body:Node2D) -> void:
		_blackboard.set_value(BlackBordValue.IS_PLAYER_VISIBLE, false)
		)

func _physics_process(delta):
	# The behavior tree handles the movement logic, but you might need
	# additional code for animation, etc.
	pass
