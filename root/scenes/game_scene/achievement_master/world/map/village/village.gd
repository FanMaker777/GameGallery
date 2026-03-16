## 村マップのルートスクリプト — BGM 再生とチュートリアル表示を担当する
extends Node2D

@onready var _tutorial_overlay: TutorialOverlay = $TutorialOverlay

func _ready() -> void:
	AudioManager.play_bgm(AudioConsts.BGM_VILLAGE)
	if SaveManager.is_new_game:
		SaveManager.is_new_game = false
		await get_tree().process_frame
		_tutorial_overlay.show_tutorial()
