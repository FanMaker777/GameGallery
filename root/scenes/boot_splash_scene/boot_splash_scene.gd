extends Control

@onready var _timer: Timer = %Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_timer.timeout.connect(func() -> void:
		Log.debug("call GameManager.load_main_scene")
		GameManager.load_main_menu_scene()
	)
