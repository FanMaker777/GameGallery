## オプションメニューのビデオ設定タブのスクリプト
class_name OptionVideo extends VBoxContainer

## 表示モードの内部キー（ウインドウ）
const DISPLAY_MODE_WINDOWED: String = SettingsRepository.DISPLAY_MODE_WINDOWED
## 表示モードの内部キー（フルスクリーン）
const DISPLAY_MODE_FULLSCREEN: String = SettingsRepository.DISPLAY_MODE_FULLSCREEN
## VSyncの内部キー（無効）
const V_SYNC_DISABLED: String = SettingsRepository.V_SYNC_DISABLED
## VSyncの内部キー（有効）
const V_SYNC_ENABLED: String = SettingsRepository.V_SYNC_ENABLED

## 表示モードUI文言→内部キーの対応表
const DISPLAY_MODE_TEXT_TO_KEY: Dictionary = {
	"ウインドウ": DISPLAY_MODE_WINDOWED,
	"フルスクリーン": DISPLAY_MODE_FULLSCREEN,
}
## 表示モード内部キー→UI文言の対応表
const DISPLAY_MODE_KEY_TO_TEXT: Dictionary = {
	DISPLAY_MODE_WINDOWED: "ウインドウ",
	DISPLAY_MODE_FULLSCREEN: "フルスクリーン",
}
## VSync UI文言→内部キーの対応表
const V_SYNC_TEXT_TO_KEY: Dictionary = {
	"無効": V_SYNC_DISABLED,
	"有効": V_SYNC_ENABLED,
}
## VSync内部キー→UI文言の対応表
const V_SYNC_KEY_TO_TEXT: Dictionary = {
	V_SYNC_DISABLED: "無効",
	V_SYNC_ENABLED: "有効",
}
## FPS表示 UI文言→内部状態の対応表
const FPS_DISPLAY_TEXT_TO_VALUE: Dictionary = {
	"無効": false,
	"有効": true,
}
## FPS表示 内部状態→UI文言の対応表
const FPS_DISPLAY_VALUE_TO_TEXT: Dictionary = {
	false: "無効",
	true: "有効",
}

@onready var _display_mode_option_button: OptionButton = %DisplayModeOptionButton
@onready var _resolution_option_button: OptionButton = %ResolutionOptionButton
@onready var _v_sync_option_button: OptionButton = %VSyncOptionButton
@onready var _fps_option_button: OptionButton = %FpsOptionButton
@onready var _fps_display_option_button: OptionButton = $OptionsMarginContainer/OptionsVBoxContainer/FpsDisplayBoxContainer/FpsDisplayOptionButton

func _ready() -> void:
	# Video設定値を現在設定値に同期
	sync_ui_from_setting_value()
	# オプションボタンの選択時シグナルを接続
	_display_mode_option_button.item_selected.connect(_selected_display_mode_button)
	_resolution_option_button.item_selected.connect(_selected_resolution_option_button)
	_v_sync_option_button.item_selected.connect(_selected_v_sync_option_button)
	_fps_option_button.item_selected.connect(_selected_fps_option_button)
	_fps_display_option_button.item_selected.connect(_selected_fps_display_option_button)

## 現在設定中のVideo設定値をUIへ同期するメソッド
func sync_ui_from_setting_value() -> void:
	var video_settings: Dictionary = SettingsRepository.get_video_settings()
	_apply_video_settings(video_settings)

## Video設定値を一括適用してUIへ反映するメソッド
func _apply_video_settings(video_settings: Dictionary) -> void:
	# SettingsRepositoryから取得した現在のVideo設定値を変数に格納
	var display_mode_key: String = str(video_settings.get("display_mode", DISPLAY_MODE_WINDOWED))
	var resolution_text: String = str(video_settings.get("resolution", "1280 × 720"))
	var v_sync_key: String = str(video_settings.get("v_sync", V_SYNC_DISABLED))
	var fps_value: int = int(video_settings.get("fps", 60))
	var fps_display_enabled: bool = bool(video_settings.get("fps_display", false))
	# 設定値をゲームに反映
	_apply_display_mode(display_mode_key)
	_apply_resolution(resolution_text)
	_apply_v_sync(v_sync_key)
	_apply_fps(fps_value)
	# 設定値をオプションメニューのUIに反映
	_select_option_by_text(_display_mode_option_button, _display_mode_key_to_text(display_mode_key))
	_select_option_by_text(_resolution_option_button, resolution_text)
	_select_option_by_text(_v_sync_option_button, _v_sync_key_to_text(v_sync_key))
	_select_option_by_text(_fps_option_button, str(fps_value))
	_select_option_by_text(_fps_display_option_button, _fps_display_value_to_text(fps_display_enabled))

## Video設定値をデフォルト設定値にリセットするメソッド
func set_default_video_option() -> void:
	# 起動時とリセット時で同じ既定値を使い回し、設定の基準値を1箇所に統一する。
	var default_video_settings: Dictionary = SettingsRepository.create_default_state()["video"]
	SettingsRepository.update_video_settings(default_video_settings)
	_apply_video_settings(SettingsRepository.get_video_settings())

## 表示モード選択時の処理メソッド
func _selected_display_mode_button(selected_index: int) -> void:
	Log.debug("表示モード変更")
	# 選択された表示モードを取得
	var selected_text: String = _display_mode_option_button.get_item_text(selected_index)
	var display_mode_key: String = _display_mode_text_to_key(selected_text)
	# 選択された表示モードに応じてゲーム設定を変更
	_apply_display_mode(display_mode_key)
	_save_video_setting("display_mode", display_mode_key)

## 解像度選択時の処理メソッド
func _selected_resolution_option_button(selected_index: int) -> void:
	Log.debug("解像度変更")
	# 選択された解像度を取得
	var selected_text: String = _resolution_option_button.get_item_text(selected_index)
	# 選択された解像度に応じてゲーム設定を変更
	_apply_resolution(selected_text)
	_save_video_setting("resolution", selected_text)

## Vsync(垂直同期)選択時の処理メソッド
func _selected_v_sync_option_button(selected_index: int) -> void:
	Log.debug("Vsync変更")
	# 選択された値を取得
	var selected_text: String = _v_sync_option_button.get_item_text(selected_index)
	var v_sync_key: String = _v_sync_text_to_key(selected_text)
	# 選択された値に応じてVsync(垂直同期)を設定
	_apply_v_sync(v_sync_key)
	_save_video_setting("v_sync", v_sync_key)

## FPS選択時の処理メソッド
func _selected_fps_option_button(selected_index: int) -> void:
	Log.debug("FPS変更")
	# 選択された値を取得
	var selected_text: String = _fps_option_button.get_item_text(selected_index)
	# 選択された値に応じてFPSを変更
	var fps_value: int = int(selected_text)
	_apply_fps(fps_value)
	_save_video_setting("fps", fps_value)

## FPS表示選択時の処理メソッド
func _selected_fps_display_option_button(selected_index: int) -> void:
	Log.debug("FPS表示変更")
	# 選択された値を取得
	var selected_text: String = _fps_display_option_button.get_item_text(selected_index)
	# 選択された値に応じてFPS表示を設定
	var is_enabled: bool = _fps_display_text_to_value(selected_text)
	if is_enabled:
		# ゲームのFPS表示を有効に設定
		pass
	else:
		# ゲームのFPS表示を無効に設定
		pass
	_save_video_setting("fps_display", is_enabled)

## 表示モード設定を適用するメソッド
func _apply_display_mode(display_mode_key: String) -> void:
	match display_mode_key:
		DISPLAY_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DISPLAY_MODE_FULLSCREEN:
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
func _apply_v_sync(v_sync_key: String) -> void:
	match v_sync_key:
		V_SYNC_DISABLED:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		V_SYNC_ENABLED:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)

## FPS設定を適用するメソッド
func _apply_fps(fps_value: int) -> void:
	Engine.max_fps = fps_value

## OptionButton内の文字列を選択状態へ反映するメソッド
func _select_option_by_text(option_button: OptionButton, target_text: String) -> void:
	for index in option_button.item_count:
		if option_button.get_item_text(index) == target_text:
			option_button.select(index)
			return

## 現在のVideo設定値を更新保存するメソッド
func _save_video_setting(setting_key: String, setting_value: Variant) -> void:
	var video_settings: Dictionary = SettingsRepository.get_video_settings()
	video_settings[setting_key] = setting_value
	SettingsRepository.update_video_settings(video_settings)

## 表示モードのUI文言を内部キーへ変換するメソッド
func _display_mode_text_to_key(display_mode_text: String) -> String:
	return str(DISPLAY_MODE_TEXT_TO_KEY.get(display_mode_text, DISPLAY_MODE_WINDOWED))

## 表示モードの内部キーをUI文言へ変換するメソッド
func _display_mode_key_to_text(display_mode_key: String) -> String:
	return str(DISPLAY_MODE_KEY_TO_TEXT.get(display_mode_key, "ウインドウ"))

## VSyncのUI文言を内部キーへ変換するメソッド
func _v_sync_text_to_key(v_sync_text: String) -> String:
	return str(V_SYNC_TEXT_TO_KEY.get(v_sync_text, V_SYNC_DISABLED))

## VSyncの内部キーをUI文言へ変換するメソッド
func _v_sync_key_to_text(v_sync_key: String) -> String:
	return str(V_SYNC_KEY_TO_TEXT.get(v_sync_key, "無効"))

## FPS表示のUI文言を内部状態へ変換するメソッド
func _fps_display_text_to_value(fps_display_text: String) -> bool:
	return bool(FPS_DISPLAY_TEXT_TO_VALUE.get(fps_display_text, false))

## FPS表示の内部状態をUI文言へ変換するメソッド
func _fps_display_value_to_text(fps_display_enabled: bool) -> String:
	return str(FPS_DISPLAY_VALUE_TO_TEXT.get(fps_display_enabled, "無効"))
