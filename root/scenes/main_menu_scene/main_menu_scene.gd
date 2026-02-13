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
	_play_button.pressed.connect(func() -> void:
		# メインメニューの表示を無効化
		_main_menu.visible = false
		# ゲーム選択画面の表示を有効化
		_select_game_menu.visible = true
		)
	# オプションボタン押下時、オプションメニューを表示
	_option_button.pressed.connect(GameManager.overlay_contoroller.open_options_menu)
	# 終了ボタン押下時、ゲーム終了
	_quit_button.pressed.connect(get_tree().quit)
	# メインメニューボタン押下時
	_main_menu_button.pressed.connect(func() -> void:
		# メインメニューの表示を有効化
		_main_menu.visible = true
		# ゲーム選択画面の表示を無効化
		_select_game_menu.visible = false
		)

## 未処理イベントの検出メソッド(オーバーライド)
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ESC"):
		Log.debug("_unhandled_input:ESC")
		# メインメニューの表示を有効化
		_main_menu.visible = true
		# ゲーム選択画面の表示を無効化
		_select_game_menu.visible = false
