class_name RpgPlayer extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	#if not is_on_floor():
		#velocity += get_gravity() * delta

	# Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction_x := Input.get_axis("ui_left", "ui_right")
	if direction_x:
		velocity.x = direction_x * SPEED
		animated_sprite.play("Run")
		animated_sprite.flip_h = direction_x < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		animated_sprite.play("Idle")
	
	var direction_y := Input.get_axis("ui_up", "ui_down")
	if direction_y:
		velocity.y = direction_y * SPEED
		animated_sprite.play("Run")
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)

	move_and_slide()
