extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		print("メインメニューに遷移します")
		_change_next_scene()

# 次のシーンに移動するメソッド
func _change_next_scene() -> void:
	get_tree().change_scene_to_file(PathConsts.MAIN_MENU)
	
