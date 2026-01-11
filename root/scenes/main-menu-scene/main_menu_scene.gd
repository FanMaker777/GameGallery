extends Control

@onready var play_button: Button = %PlayButton
@onready var option_button: Button = %OptionButton
@onready var quit_button: Button = %QuitButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# シグナルを接続
	_conect_signal()
	
	# web実行時、終了ボタンを非表示に変更
	if  OS.has_feature("web"):
		quit_button.visible = false
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# シグナルを接続
func _conect_signal() -> void:
	# プレイボタン押下時
	play_button.pressed.connect(_pressed_play_button)
	# 終了ボタン押下時
	quit_button.pressed.connect(_pressed_quit_button)

# プレイボタン押下時のメソッド
func _pressed_play_button() -> void:
	print("pressed_play_button")

# 終了ボタン押下時のメソッド
func _pressed_quit_button() -> void:
	# ゲームを終了
	get_tree().quit()
