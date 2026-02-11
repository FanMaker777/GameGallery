extends Control

@onready var _back_button: Button = %BackButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Log.info("_ready OptionsMenu")
	# 初期では非表示に設定
	visible = false
	# backボタン押下時、オプションメニューを閉じる
	_back_button.pressed.connect(close)

func open() -> void:
	visible = true

func close() -> void:
	visible = false
