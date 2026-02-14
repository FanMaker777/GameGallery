## オプションメニューのビデオ設定タブのスクリプト
class_name OptionVideo extends VBoxContainer

@onready var _display_mode_option_button: OptionButton = %DisplayModeOptionButton
@onready var _resolution_option_button: OptionButton = %ResolutionOptionButton
@onready var _v_sync_option_button: OptionButton = %VSyncOptionButton
@onready var _fps_option_button: OptionButton = %FpsOptionButton
@onready var _fps_display_option_button: OptionButton = $OptionsMarginContainer/OptionsVBoxContainer/FpsDisplayBoxContainer/FpsDisplayOptionButton

func _ready() -> void:
	# Video設定値をデフォルト値に設定
	set_default_video_option()
	# オプションボタンの選択時シグナルを接続
	_display_mode_option_button.item_selected.connect(_selected_display_mode_button)
	_resolution_option_button.item_selected.connect(_selected_resolution_option_button)
	_v_sync_option_button.item_selected.connect(_selected_v_sync_option_button)
	_fps_option_button.item_selected.connect(_selected_fps_option_button)
	_fps_display_option_button.item_selected.connect(_selected_fps_display_option_button)

## Video設定値をデフォルト設定値にリセットするメソッド
func set_default_video_option() -> void:
	# 起動時とリセット時で同じ既定値を使い回し、設定の基準値を1箇所に統一する。
	_apply_display_mode(DefaultOption.DEFAULT_VIDEO_DISPLAY_MODE)
	_apply_resolution(DefaultOption.DEFAULT_VIDEO_RESOLUTION)
	_apply_v_sync(DefaultOption.DEFAULT_VIDEO_V_SYNC)
	_apply_fps(DefaultOption.DEFAULT_VIDEO_FPS)
	_select_option_by_text(_fps_display_option_button, DefaultOption.DEFAULT_VIDEO_FPS_DISPLAY)

## 現在設定中のVideo設定値をUIへ同期するメソッド
func sync_ui_from_setting_value() -> void:
	# 現在のVideo設定値を、UI表示用のString型に変換
	var display_mode_text: String = _to_display_mode_text(DisplayServer.window_get_mode())
	var current_window_size: Vector2i = DisplayServer.window_get_size()
	var resolution_text: String = _to_resolution_text(current_window_size)
	var v_sync_text: String = _to_v_sync_text(DisplayServer.window_get_vsync_mode())
	var fps_text: String = _to_fps_text(Engine.max_fps)

	# Video設定の各オプションボタンの選択値を設定
	_select_option_by_text(_display_mode_option_button, display_mode_text)
	_select_option_by_text(_resolution_option_button, resolution_text)
	_select_option_by_text(_v_sync_option_button, v_sync_text)
	_select_option_by_text(_fps_option_button, fps_text)
	# FPS表示はまだ実機能未実装のため、UIは既定値を表示して誤解を防ぐ。
	_select_option_by_text(_fps_display_option_button, DefaultOption.DEFAULT_VIDEO_FPS_DISPLAY)

## 表示モード選択時の処理メソッド
func _selected_display_mode_button(selected_index:int) -> void:
	Log.debug("表示モード変更")
	# 選択された表示モードを取得
	var selected_text:String = _display_mode_option_button.get_item_text(selected_index)
	# 選択された表示モードに応じてゲーム設定を変更
	_apply_display_mode(selected_text)

## 解像度選択時の処理メソッド
func _selected_resolution_option_button(selected_index:int) -> void:
	Log.debug("解像度変更")
	# 選択された解像度を取得
	var selected_text:String = _resolution_option_button.get_item_text(selected_index)
	# 選択された解像度に応じてゲーム設定を変更
	_apply_resolution(selected_text)

## Vsync(垂直同期)選択時の処理メソッド
func _selected_v_sync_option_button(selected_index:int) -> void:
	Log.debug("Vsync変更")
	# 選択された値を取得
	var selected_text:String = _v_sync_option_button.get_item_text(selected_index)
	# 選択された値に応じてVsync(垂直同期)を設定
	_apply_v_sync(selected_text)
	
## FPS選択時の処理メソッド
func _selected_fps_option_button(selected_index:int) -> void:
	Log.debug("FPS変更")
	# 選択された値を取得
	var selected_text:String = _fps_option_button.get_item_text(selected_index)
	# 選択された値に応じてFPSを変更
	_apply_fps(selected_text)

## FPS表示選択時の処理メソッド
func _selected_fps_display_option_button(selected_index:int) -> void:
	Log.debug("FPS表示変更")
	# 選択された値を取得
	var selected_text:String = _fps_display_option_button.get_item_text(selected_index)
	# 選択された値に応じてFPS表示を設定
	match selected_text:
		"無効":
			# ゲームのFPS表示を無効に設定
			pass
		"有効":
			# ゲームのFPS表示を有効に設定
			pass

## 表示モード設定を適用するメソッド
func _apply_display_mode(display_mode_text: String) -> void:
	match display_mode_text:
		"ウインドウ":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		"フルスクリーン":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

## 解像度設定を適用するメソッド
func _apply_resolution(resolution_text: String) -> void:
	match resolution_text:
		"854 × 480":
			DisplayServer.window_set_size(Vector2i(854, 480))
		"1280 × 720":
			DisplayServer.window_set_size(Vector2i(1280, 720))
		"1920 × 1080":
			DisplayServer.window_set_size(Vector2i(1920, 1080))

## VSync設定を適用するメソッド
func _apply_v_sync(v_sync_text: String) -> void:
	match v_sync_text:
		"無効":
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		"有効":
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)

## FPS設定を適用するメソッド
func _apply_fps(fps_text: String) -> void:
	Engine.max_fps = int(fps_text)

## OptionButton内の文字列を選択状態へ反映するメソッド
func _select_option_by_text(option_button: OptionButton, target_text: String) -> void:
	for index in option_button.item_count:
		if option_button.get_item_text(index) == target_text:
			option_button.select(index)
			return

## DisplayServerの表示モードをUI表示文字列へ変換するメソッド
func _to_display_mode_text(window_mode: DisplayServer.WindowMode) -> String:
	match window_mode:
		DisplayServer.WINDOW_MODE_FULLSCREEN:
			return "フルスクリーン"
		_:
			return "ウインドウ"

## 現在のウインドウサイズをUI表示文字列へ変換するメソッド
func _to_resolution_text(window_size: Vector2i) -> String:
	match window_size:
		Vector2i(854, 480):
			return "854 × 480"
		Vector2i(1920, 1080):
			return "1920 × 1080"
		_:
			return "1280 × 720"

## VSyncモードをUI表示文字列へ変換するメソッド
func _to_v_sync_text(v_sync_mode: DisplayServer.VSyncMode) -> String:
	match v_sync_mode:
		DisplayServer.VSYNC_ENABLED:
			return "有効"
		_:
			return "無効"

## Engine.max_fpsをUI表示文字列へ変換するメソッド
func _to_fps_text(max_fps: int) -> String:
	var fps_text: String = str(max_fps)
	for index in _fps_option_button.item_count:
		if _fps_option_button.get_item_text(index) == fps_text:
			return fps_text
	return DefaultOption.DEFAULT_VIDEO_FPS
