## 【Autoload】メニューやレベルのシーン切り替えを担当する
extends Node

## シーンパス(文字列定数のまま保持し、必要時にロードすることで循環参照時の初期化不全を避ける。)
const MAIN_MENU_SCENE_PATH: String = "uid://byjaiv21t5df7"
## ポーズスクリーンの表示が可能なシーンのパスリスト
const PAUSE_SCREEN_ENABLE_SCENE_PATHS: PackedStringArray = [
	"res://root/scenes/game_scene/introduce_godot/game/introduce_godot.tscn"
]

const SceneNavigatorScript: GDScript = preload("res://root/autoload/game_manager/scene_navigator.gd")
const OverlayControllerScript: GDScript = preload("res://root/autoload/game_manager/overlay_controller.gd")

@onready var pause_screen: Control = %PauseScreen
@onready var transition_effect_layer: CanvasLayer = %TransitionEffectLayer
@onready var options_menu: Control = %OptionsMenu

var _scene_navigator: RefCounted
var _overlay_controller: RefCounted

func _ready() -> void:
	Log.info("_ready GameManager")
	#Log.current_log_level = Log.LogLevel.DEBUG
	_scene_navigator = SceneNavigatorScript.new(get_tree(), transition_effect_layer)
	_overlay_controller = OverlayControllerScript.new(
		get_tree(),
		pause_screen,
		options_menu,
		PAUSE_SCREEN_ENABLE_SCENE_PATHS
	)

## 引数のシーンを、遷移エフェクト付きでロードする関数
func load_scene_with_transition(load_to_scene:PackedScene) -> void:
	Log.info("func load_scene_with_transition", load_to_scene)
	_overlay_controller.reset_overlays()
	_scene_navigator.load_scene_with_transition(load_to_scene)

## メインメニューへ遷移するメソッド
## 導線をGameManagerに集約し、呼び出し側の依存を減らす。
func load_main_menu_scene() -> void:
	var main_menu_scene: PackedScene = load(MAIN_MENU_SCENE_PATH)
	load_scene_with_transition(main_menu_scene)

func _input(event: InputEvent) -> void:
	_overlay_controller.handle_input(event)
