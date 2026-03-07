## 起動スプラッシュ画面を表示し、一定時間後にメインメニューへ遷移する
extends Control

## スプラッシュ表示時間を管理するタイマー
@onready var _timer: Timer = %Timer

## タイマー完了時にメインメニューへ遷移するコールバックを登録する
func _ready() -> void:
	# タイマー完了シグナルにメインメニュー遷移処理を接続
	_timer.timeout.connect(func() -> void:
		Log.debug("call GameManager.load_scene_with_transition")
		#　メインメニューに遷移
		GameManager.load_scene_with_transition(PathConsts.MAIN_MENU_SCENE)
	)
