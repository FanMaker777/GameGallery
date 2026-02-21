@tool
class_name FallingPlatform extends Platform

enum States {
	IDLE,
	FALLING,
	REAPPEARING,
}

var _state: States = States.IDLE
var _player_detector: Area2D

@onready var _visual_root: Node2D = %VisualRoot
@onready var _reappear_timer: Timer = %ReappearTimer
@onready var _chunk_particles: GPUParticles2D = %ChunkParticles


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		set_physics_process(false)
		return

	# Create player detector area
	_player_detector = Area2D.new()
	_player_detector.collision_layer = 0
	# 1 corresponds to the physics layer the player is on
	_player_detector.collision_mask = 1
	add_child(_player_detector)

	# Create shape for the detector
	var detector_shape := CollisionShape2D.new()
	detector_shape.shape = RectangleShape2D.new()
	detector_shape.shape.size = Vector2(width, 2)
	detector_shape.position = Vector2(0, 0)
	_player_detector.add_child(detector_shape)

	# Connect signals
	_reappear_timer.timeout.connect(_reappear_timer_timeout)
	_chunk_particles.emitting = false


func set_width(value: float) -> void:
	super(value)
	if not is_inside_tree():
		return

	# Update detector shape if it exists
	if _player_detector and _player_detector.get_child_count() > 0:
		var detector_shape := _player_detector.get_child(0) as CollisionShape2D
		if detector_shape and detector_shape.shape is RectangleShape2D:
			detector_shape.shape.size.x = width

	_chunk_particles.emitting = false


func _physics_process(_delta: float) -> void:
	if _state != States.IDLE:
		return

	# We need to check every frame if the player is on top of the platform.
	# Using the body_entered signal would not work because if the player jumps
	# from below the platform, it will trigger the signal when the character's
	# head touches the detector area, and at that time it will not activate the
	# falling sequence.
	var overlapping_bodies := _player_detector.get_overlapping_bodies()
	for body in overlapping_bodies:
		if not body is Player or not body.is_on_floor():
			continue

		# Ensure that the player is standing on the platform, not on another
		# ground very close to it.
		if body.global_position.y >= global_position.y + 1.0:
			continue

		activate_falling_sequence()
		break


func activate_falling_sequence() -> void:
	_state = States.FALLING
	_chunk_particles.emitting = true
	var min_width := _sprite.patch_margin_left + _sprite.patch_margin_right
	var tween := create_tween().set_ease(Tween.EASE_OUT)
	tween.tween_method(func(progress: float):
		var w := maxf(min_width, width * progress)
		_sprite.size.x = w
		_sprite.position.x = -w/2.0
		, 1.0, 0.0, 0.6)
	tween.parallel().tween_property(_visual_root, "scale", Vector2.ZERO, 0.4).set_delay(0.4)
	tween.tween_callback(func():
		_visual_root.hide()
		_collision_shape_2d.set_deferred("disabled", true)
		_chunk_particles.emitting = false
		)
	_reappear_timer.start(3.0)


func _reappear_timer_timeout() -> void:
	_state = States.REAPPEARING
	set_width(width)
	_visual_root.show()
	var tween := create_tween().set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_visual_root, "scale", Vector2.ONE, 0.1).from(Vector2.ONE * 0.2).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_callback(func():
		_collision_shape_2d.set_deferred("disabled", false)
		_state = States.IDLE
		)
