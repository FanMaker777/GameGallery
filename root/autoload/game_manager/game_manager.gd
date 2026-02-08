## 【Autoload】メニューやレベルのシーン切り替えを担当する
extends Node

# 文字列定数のまま保持し、必要時にロードすることで循環参照時の初期化不全を避ける。
const MAIN_MENU_SCENE_PATH: String = "uid://byjaiv21t5df7"
const PAUSE_SCREEN_DISABLED_SCENE_PATHS: PackedStringArray = [
	"res://root/scenes/boot_splash_scene/boot_splash_scene.tscn",
	"res://root/scenes/main_menu_scene/main-menu-scene.tscn",
]

@onready var pause_screen: Control = %PauseScreen
@onready var transition_effect_layer: CanvasLayer = %TransitionEffectLayer

func _ready() -> void:
	Log.info("_ready GameManager")
	Log.current_log_level = Log.LogLevel.DEBUG

## 引数のシーンを、遷移エフェクト付きでロードする関数
func load_scene_with_transition(load_to_scene:PackedScene) -> void:
	Log.info("func load_scene_with_transition", load_to_scene)
	# 画面をフェードアウト
	transition_effect_layer.fade_out()
	# フェードアウト終了後
	transition_effect_layer.finished_fade_out.connect(func() -> void:
		# 引数のシーンに遷移
		get_tree().change_scene_to_packed(load_to_scene)
		# シーン展開完了まで待機
		await get_tree().scene_changed
		# 画面をフェードイン
		transition_effect_layer.fade_in()
	)

## メインメニューへ遷移するメソッド
## 導線をGameManagerに集約し、呼び出し側の依存を減らす。
func load_main_menu_scene() -> void:
	var main_menu_scene: PackedScene = load(MAIN_MENU_SCENE_PATH)
	load_scene_with_transition(main_menu_scene)

func _input(event: InputEvent) -> void:
	# ESCボタン押下時
	if event.is_action_pressed("ESC") and _can_toggle_pause_screen():
		# ポーズスクリーンの表示を切り替え
		pause_screen.toggle()

## シーン単位でポーズ可否を制御し、導線追加時の条件分岐を1か所に集約する。
func _can_toggle_pause_screen() -> bool:
	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return false

	var current_scene_path: String = current_scene.scene_file_path
	return not PAUSE_SCREEN_DISABLED_SCENE_PATHS.has(current_scene_path)
