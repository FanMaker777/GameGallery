extends Control

@onready var _timer: Timer = %Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_timer.timeout.connect(func() -> void:
		Log.debug("call GameManager.load_scene_with_transition")
		#　メインメニューに遷移
		GameManager.load_scene_with_transition(PathConsts.PATH_MAIN_MENU_SCENE)
	)
