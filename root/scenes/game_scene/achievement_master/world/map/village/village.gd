## 村マップのルートスクリプト — BGM 再生を担当する
extends Node2D

func _ready() -> void:
	AudioManager.play_bgm(AudioConsts.BGM_VILLAGE)
