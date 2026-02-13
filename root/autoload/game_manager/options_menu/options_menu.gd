## オプションメニュークラス
class_name OptionsMenu extends Control

@onready var _back_button: Button = %BackButton

func _ready() -> void:
	Log.info("_ready OptionsMenu")
	# 初期では非表示に設定
	visible = false
	# backボタン押下時、オプションメニューを閉じる
	_back_button.pressed.connect(close)

## オプションメニューを表示するメソッド
func open() -> void:
	visible = true

## オプションメニューを非表示にするメソッド
func close() -> void:
	visible = false
