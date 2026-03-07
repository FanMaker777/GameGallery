## マッシュルームワールド・プレイグラウンドのレベルスクリプト
## ゴールフラグ到達時にクリア画面を表示する
extends Node2D

# ---- ノード参照 ----
## ゴールフラグ
@onready var _end_flag: EndFlag = %EndFlag
## クリア画面UI
@onready var _clear_screen: ClearScreen = %ClearScreen

## 初期化処理（ゴールフラグにクリア画面表示のシグナルを接続する）
func _ready() -> void:
	# プレイヤーがゴールフラグに到達したら、2秒後にクリア画面を表示する
	_end_flag.body_entered.connect(func (body: Node2D) -> void:
		await get_tree().create_timer(2.0).timeout
		_clear_screen.open()
	)
