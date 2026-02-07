## 【Autoload】メニューやレベルのシーン切り替えを担当する
extends Node

# 文字列定数のまま保持し、必要時にロードすることで循環参照時の初期化不全を避ける。
const MAIN_MENU_SCENE_PATH: String = "uid://byjaiv21t5df7"

func _ready() -> void:
	Log.current_log_level = Log.LogLevel.DEBUG

# 引数のシーンを、遷移エフェクト付きでロードする関数
func load_scene_with_transition(load_to_scene:PackedScene) -> void:
	Log.info("func load_scene_with_transition", load_to_scene)
	# 画面をフェードアウト
	TransitionEffect.fade_out()
	# フェードアウト終了後
	TransitionEffect.finished_fade_out.connect(func() -> void:
		# 引数のシーンに遷移
		get_tree().change_scene_to_packed(load_to_scene)
		# シーン展開完了まで待機
		await get_tree().scene_changed
		# 画面をフェードイン
		TransitionEffect.fade_in()
	)

# メインメニュー遷移導線をGameManagerに集約し、呼び出し側の依存を減らす。
func load_main_menu_scene() -> void:
	var main_menu_scene: PackedScene = load(MAIN_MENU_SCENE_PATH)
	load_scene_with_transition(main_menu_scene)
