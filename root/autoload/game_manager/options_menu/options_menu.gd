## オプションメニュークラス
class_name OptionsMenu extends Control

@onready var _back_button: Button = %BackButton
@onready var _audio_tab: VBoxContainer = %Audio

func _ready() -> void:
	Log.info("_ready OptionsMenu")
	# 初期では非表示に設定
	visible = false
	# backボタン押下時、オプションメニューを閉じる
	_back_button.pressed.connect(close)

## オプションメニューを表示するメソッド
func open() -> void:
	# メニュー再表示時に保持済み音量を反映し、他画面で変更された値とのズレを防ぐ。
	if _audio_tab.has_method("sync_from_sound_manager"):
		_audio_tab.call("sync_from_sound_manager")
	visible = true

## オプションメニューを非表示にするメソッド
func close() -> void:
	visible = false
