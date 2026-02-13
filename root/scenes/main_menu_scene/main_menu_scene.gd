extends Control

@onready var _main_menu: Control = %MainMenu
@onready var _select_game_menu: Control = %SelectGameMenu
@onready var _play_button: Button = %PlayButton
@onready var _option_button: Button = %OptionButton
@onready var _quit_button: Button = %QuitButton
@onready var _main_menu_button: Button = %MainMenuButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Log.info("_ready MainMenuScene")
	# メインメニューの表示を有効化
	_main_menu.visible = true
	# ゲーム選択画面の表示を無効化
	_select_game_menu.visible = false
	# シグナルを接続
	_conect_signal()
	
	# web実行時、終了ボタンを非表示に変更
	if  OS.has_feature("web"):
		_quit_button.visible = false

## シグナルを接続
func _conect_signal() -> void:
	# プレイボタン押下時
	_play_button.pressed.connect(_pressed_play_button)
	# 終了ボタン押下時
	_quit_button.pressed.connect(_pressed_quit_button)
	# メインメニューボタン押下時
	_main_menu_button.pressed.connect(func() -> void:
		# メインメニューの表示を有効化
		_main_menu.visible = true
		# ゲーム選択画面の表示を無効化
		_select_game_menu.visible = false
		)

## プレイボタン押下時のメソッド
func _pressed_play_button() -> void:
	Log.debug("_pressed_play_button")
	# メインメニューの表示を無効化
	_main_menu.visible = false
	# ゲーム選択画面の表示を有効化
	_select_game_menu.visible = true

## 終了ボタン押下時のメソッド
func _pressed_quit_button() -> void:
	# ゲームを終了
	get_tree().quit()

## 未処理イベントの検出メソッド(オーバーライド)
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ESC"):
		Log.debug("_unhandled_input:ESC")
		# メインメニューの表示を有効化
		_main_menu.visible = true
		# ゲーム選択画面の表示を無効化
		_select_game_menu.visible = false
