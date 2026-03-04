## 汎用警告ダイアログ — confirmed シグナルを接続するだけで任意の処理をトリガー可能
class_name WarningDialog extends ColorRect

## Yes ボタン押下時に発火する
signal confirmed

@onready var _title_label: Label = %TitleLabel
@onready var _body_label: Label = %BodyLabel
@onready var _yes_button: Button = %YesButton
@onready var _no_button: Button = %NoButton


## 初期状態を非表示にし、ボタンシグナルを接続する
func _ready() -> void:
	visible = false
	_yes_button.pressed.connect(_on_yes_pressed)
	_no_button.pressed.connect(_on_no_pressed)


## タイトルと本文を設定して表示する
func show_warning(title: String, body: String) -> void:
	_title_label.text = title
	_body_label.text = body
	visible = true


## Yes ボタン押下 → ダイアログを閉じて confirmed を発火する
func _on_yes_pressed() -> void:
	visible = false
	confirmed.emit()


## No ボタン押下 → ダイアログを閉じる（処理なし）
func _on_no_pressed() -> void:
	visible = false
