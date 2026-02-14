## オプションメニュークラス
class_name OptionsMenu extends Control

@onready var _back_button: Button = %BackButton
@onready var _option_reset_button: Button = %OptionResetButton
@onready var _tab_container: TabContainer = %TabContainer
@onready var _audio_tab: OptionAudio = %Audio
@onready var _video_tab: OptionVideo = %Video

func _ready() -> void:
	Log.info("_ready OptionsMenu")
	# 初期では非表示に設定
	visible = false
	# backボタン押下時、オプションメニューを閉じる
	_back_button.pressed.connect(close)
	# リセットボタン押下時、オプションをデフォルト設定にリセット
	_option_reset_button.pressed.connect(reset_option)

## オプションメニューを表示するメソッド
func open() -> void:
	# メニュー再表示時に現在設定値をUIに反映する
	_audio_tab.sync_from_sound_manager()
	_video_tab.sync_ui_from_setting_value()
	
	visible = true

## オプションメニューを非表示にするメソッド
func close() -> void:
	visible = false

## オプションをデフォルト設定にリセットするメソッド
func reset_option() -> void:
	# リセットボタン押下時のタブのインデックスを取得
	var selected_option_tab_index:int = _tab_container.current_tab
	
	match selected_option_tab_index:
		0:  # Audioタブの場合
			# Audio設定値をデフォルト値に初期化
			AudioManager.set_default_audio_option()
			# AudioManagerの保持値をUIへ同期
			_audio_tab.sync_from_sound_manager()
		
		1:  # Videoタブの場合
			# Video設定値をデフォルト値に初期化
			_video_tab.set_default_video_option()
			# Video設定値をUIへ同期
			_video_tab.sync_ui_from_setting_value()
	
