## 【Autoload】メニューやレベルのシーン切り替えを担当する
extends Node

# メインメニューとレベルシーンをプリロード
const MAIN_MENU_SCENE: PackedScene = preload("uid://byjaiv21t5df7")

func _ready() -> void:
	Log.current_log_level = Log.LogLevel.DEBUG

# メインメニューシーンをロードする関数
func load_main_scene() -> void:
	Log.debug("func load_main_scene")
	# 画面をフェードアウト
	TransitionEffect.fade_out()
	# フェードアウト終了後
	TransitionEffect.finished_fade_out.connect(func() -> void:
		# メインメニューに遷移
		get_tree().change_scene_to_packed(MAIN_MENU_SCENE)
		# メインメニューのシーン展開完了まで待機
		await get_tree().scene_changed
		# 画面をフェードイン
		TransitionEffect.fade_in()
	)
