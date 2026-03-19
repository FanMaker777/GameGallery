## 村マップのルートスクリプト — BGM 再生、チュートリアル表示、ショップ接続を担当する
extends Node2D

@onready var _tutorial_overlay: TutorialOverlay = $TutorialOverlay
@onready var _shop_ui: ShopUI = $ShopUI
@onready var _npc_shoper: Npc = $NPC/NpcShoper

func _ready() -> void:
	AudioManager.play_bgm(AudioConsts.BGM_VILLAGE)
	# NPC ショップ店員のインタラクションでショップを開く
	_npc_shoper.npc_interacted.connect(_on_shop_npc_interacted)
	if SaveManager.is_new_game:
		SaveManager.is_new_game = false
		await get_tree().process_frame
		_tutorial_overlay.show_tutorial()


## ショップ店員と会話した時のコールバック
func _on_shop_npc_interacted(_npc_id: String) -> void:
	_shop_ui.open_shop()
