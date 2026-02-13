## 【Autoload】メニューやレベルのシーン切り替えを担当する
extends Node

@onready var scene_navigator: SceneNavigator = %SceneNavigator
@onready var overlay_contoroller: OverlayController = %OverlayContoroller

func _ready() -> void:
	Log.info("_ready GameManager")
	Log.current_log_level = Log.LogLevel.DEBUG

## 引数のシーンを、遷移エフェクト付きでロードする関数
func load_scene_with_transition(load_to_scene_path:String) -> void:
	# オーバーレイUIを非表示状態にリセット
	overlay_contoroller.reset_overlays()
	# シーンナビゲーターのシーン遷移メソッドを呼び出し
	scene_navigator.load_scene_with_transition(load_to_scene_path)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ESC"):
		overlay_contoroller.handle_input_esc(event)
