## オプションメニューのビデオ設定タブのスクリプト
extends VBoxContainer

@onready var _display_mode_option_button: OptionButton = %DisplayModeOptionButton
@onready var _resolution_option_button: OptionButton = %ResolutionOptionButton
@onready var _v_sync_option_button: OptionButton = %VSyncOptionButton
@onready var _fps_option_button: OptionButton = %FpsOptionButton
@onready var _fps_display_option_button: OptionButton = $OptionsMarginContainer/OptionsVBoxContainer/FpsDisplayBoxContainer/FpsDisplayOptionButton

func _ready() -> void:
	# オプションボタンの選択時シグナルを接続
	_display_mode_option_button.item_selected.connect(_selected_display_mode_button)
	_resolution_option_button.item_selected.connect(_selected_resolution_option_button)
	_v_sync_option_button.item_selected.connect(_selected_v_sync_option_button)
	_fps_option_button.item_selected.connect(_selected_fps_option_button)
	_fps_display_option_button.item_selected.connect(_selected_fps_display_option_button)

## 表示モード選択時の処理メソッド
func _selected_display_mode_button(selected_index:int) -> void:
	Log.debug("表示モード変更")
	# 選択された表示モードを取得
	var selected_text:String = _display_mode_option_button.get_item_text(selected_index)
	# 選択された表示モードに応じてゲーム設定を変更
	match selected_text:
		"ウインドウ":
			# (codex)ゲームの表示モードをウインドウに変更
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		"フルスクリーン":
			# (codex)ゲームの表示モードをフルスクリーンに変更
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

## 解像度選択時の処理メソッド
func _selected_resolution_option_button(selected_index:int) -> void:
	Log.debug("解像度変更")
	# 選択された解像度を取得
	var selected_text:String = _resolution_option_button.get_item_text(selected_index)
	# 選択された解像度に応じてゲーム設定を変更
	match selected_text:
		"854 × 480":
			# (codex)ゲームの解像度を854 × 480に変更
			DisplayServer.window_set_size(Vector2i(854, 480))
		"1280 × 720":
			# (codex)ゲームの解像度を1280 × 720に変更
			DisplayServer.window_set_size(Vector2i(1280, 720))
		"1920 × 1080":
			# (codex)ゲームの解像度を1920 × 1080に変更
			DisplayServer.window_set_size(Vector2i(1920, 1080))

## Vsync(垂直同期)選択時の処理メソッド
func _selected_v_sync_option_button(selected_index:int) -> void:
	Log.debug("Vsync変更")
	# 選択された値を取得
	var selected_text:String = _v_sync_option_button.get_item_text(selected_index)
	# 選択された値に応じてゲーム設定を変更
	match selected_text:
		"無効":
			# (codex)ゲームのVsync(垂直同期)を無効に設定
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		"有効":
			# (codex)ゲームのVsync(垂直同期)を有効に設定
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)

## FPS選択時の処理メソッド
func _selected_fps_option_button(selected_index:int) -> void:
	Log.debug("FPS変更")
	# 選択された値を取得
	var selected_text:String = _fps_option_button.get_item_text(selected_index)
	# 選択された値に応じてFPSを変更
	match selected_text:
		"30":
			# (codex)ゲームのFPSを30に設定
			Engine.max_fps = 30
		"60":
			# (codex)ゲームのFPSを60に設定
			Engine.max_fps = 60
		"100":
			# (codex)ゲームのFPSを100に設定
			Engine.max_fps = 100
		"120":
			# (codex)ゲームのFPSを120に設定
			Engine.max_fps = 120
		"144":
			# (codex)ゲームのFPSを144に設定
			Engine.max_fps = 144

## FPS表示選択時の処理メソッド
func _selected_fps_display_option_button(selected_index:int) -> void:
	Log.debug("FPS表示変更")
	# 選択された値を取得
	var selected_text:String = _fps_display_option_button.get_item_text(selected_index)
	# 選択された値に応じてゲーム設定を変更
	match selected_text:
		"無効":
			# ゲームのFPS表示を無効に設定
			pass
		"有効":
			# ゲームのFPS表示を有効に設定
			pass
