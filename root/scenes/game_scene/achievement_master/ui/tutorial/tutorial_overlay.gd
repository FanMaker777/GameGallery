## チュートリアルオーバーレイ — ニューゲーム時に操作ガイドを全画面表示する
class_name TutorialOverlay extends CanvasLayer

@onready var _overlay_content: Control = %OverlayContent
@onready var _content_container: VBoxContainer = %ContentContainer
@onready var _close_button: Button = %CloseButton

## コンテンツ構築済みフラグ（重複追加防止）
var _is_built: bool = false


func _ready() -> void:
	_overlay_content.visible = false
	_close_button.pressed.connect(_close)


## チュートリアルを表示する
func show_tutorial() -> void:
	if not _is_built:
		_is_built = true
		HelpContentBuilder.build_content(_content_container)
	_overlay_content.visible = true
	GameManager.overlay_contoroller.set_tutorial_active(true)


## チュートリアルを閉じる
func _close() -> void:
	_overlay_content.visible = false
	GameManager.overlay_contoroller.set_tutorial_active(false)


## 表示中にキーボード入力で閉じる（マウスクリックは CloseButton に委譲）
func _input(event: InputEvent) -> void:
	if not _overlay_content.visible:
		return
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.is_pressed() or key_event.is_echo():
		return
	# 修飾キー単独押下では閉じない
	if key_event.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]:
		return
	_close()
	get_viewport().set_input_as_handled()
