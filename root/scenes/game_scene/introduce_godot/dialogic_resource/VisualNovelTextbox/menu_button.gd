extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# ボタン押下時、Autoloadのポーズスクリーンの表示切替メソッドを呼び出し
	pressed.connect(GameManager.overlay_contoroller.toggle_pause_screen)
