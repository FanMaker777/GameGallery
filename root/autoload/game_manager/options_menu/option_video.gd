## オプションメニューのビデオ設定タブのスクリプト
class_name OptionVideo extends VBoxContainer

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
	_select_option_by_text(_display_mode_option_button, str(video_settings.get("display_mode", "ウインドウ")))
	_select_option_by_text(_resolution_option_button, str(video_settings.get("resolution", "1280 × 720")))
	_select_option_by_text(_v_sync_option_button, str(video_settings.get("v_sync", "無効")))
	_select_option_by_text(_fps_option_button, str(video_settings.get("fps", "60")))
	_select_option_by_text(_fps_display_option_button, str(video_settings.get("fps_display", "無効")))

## 表示モード選択時の処理メソッド
func _selected_display_mode_button(selected_index: int) -> void:
	Log.debug("表示モード変更")
	var selected_text: String = _display_mode_option_button.get_item_text(selected_index)
	VideoManager.set_display_mode(selected_text)

## 解像度選択時の処理メソッド
func _selected_resolution_option_button(selected_index: int) -> void:
	Log.debug("解像度変更")
	var selected_text: String = _resolution_option_button.get_item_text(selected_index)
	VideoManager.set_resolution(selected_text)

## Vsync(垂直同期)選択時の処理メソッド
func _selected_v_sync_option_button(selected_index: int) -> void:
	Log.debug("Vsync変更")
	var selected_text: String = _v_sync_option_button.get_item_text(selected_index)
	VideoManager.set_v_sync(selected_text)

## FPS選択時の処理メソッド
func _selected_fps_option_button(selected_index: int) -> void:
	Log.debug("FPS変更")
	var selected_text: String = _fps_option_button.get_item_text(selected_index)
	VideoManager.set_fps(selected_text)

## FPS表示選択時の処理メソッド
func _selected_fps_display_option_button(selected_index: int) -> void:
	Log.debug("FPS表示変更")
	var selected_text: String = _fps_display_option_button.get_item_text(selected_index)
	VideoManager.set_fps_display(selected_text)

## OptionButton内の文字列を選択状態へ反映するメソッド
func _select_option_by_text(option_button: OptionButton, target_text: String) -> void:
	for index in option_button.item_count:
		if option_button.get_item_text(index) == target_text:
			option_button.select(index)
			return
