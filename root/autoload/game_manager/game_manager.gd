## 【Autoload】メニューやレベルのシーン切り替えを担当する
extends Node

## シーンパス(文字列定数のまま保持し、必要時にロードすることで循環参照時の初期化不全を避ける。)
const MAIN_MENU_SCENE_PATH: String = "uid://byjaiv21t5df7"

@onready var _scene_navigator: SceneNavigator = %SceneNavigator
@onready var _overlay_contoroller: OverlayController = %OverlayContoroller

func _ready() -> void:
	Log.info("_ready GameManager")
	#Log.current_log_level = Log.LogLevel.DEBUG

## 引数のシーンを、遷移エフェクト付きでロードする関数
func load_scene_with_transition(load_to_scene:PackedScene) -> void:
	Log.info("func load_scene_with_transition", load_to_scene)
	_overlay_contoroller.reset_overlays()
	_scene_navigator.load_scene_with_transition(load_to_scene)

## メインメニューへ遷移するメソッド
## 導線をGameManagerに集約し、呼び出し側の依存を減らす。
func load_main_menu_scene() -> void:
	var main_menu_scene: PackedScene = load(MAIN_MENU_SCENE_PATH)
	load_scene_with_transition(main_menu_scene)

func _input(event: InputEvent) -> void:
	_overlay_contoroller.handle_input(event)
