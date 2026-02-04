@tool
@icon("uid://c1y5nxj2xu33x")
extends Control

## An array of dictionaries. Each dictionary has three properties:
## - expression: a [code]Texture[/code] containing an expression
## - text: a [code]String[/code] containing the text the character says
## - character: a [code]Texture[/code] representing the character
@export var dialogue_items: Array[DialogueItem] = []:
	set = set_dialogue_items
func set_dialogue_items(new_dialogue_items: Array[DialogueItem]) -> void:
	# インスペクター上で、自動で空のリソースを設定
	for index in new_dialogue_items.size():
		if new_dialogue_items[index] == null:
			new_dialogue_items[index] = DialogueItem.new()
	dialogue_items = new_dialogue_items

## UI element that shows the texts
@onready var rich_text_label: RichTextLabel = %RichTextLabel
## Audio player that plays voice sounds while text is being written
@onready var audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer
## The character
@onready var body: TextureRect = %Body
## The Expression
@onready var expression: TextureRect = %Expression
@onready var action_buttons_v_box_container: VBoxContainer = %ActionButtonsVBoxContainer
## 表示するDialogueItemのインデックス
var dialogue_item_index:int = 0

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	show_text(dialogue_item_index)

## Draws the current text to the rich text element
func show_text(current_item_index: int) -> void:
	# 表示するDialogueItemのインデックスを設定
	dialogue_item_index = current_item_index
	# 表示する情報を、DialogueItemリソースから取得
	var current_item := dialogue_items[dialogue_item_index]
	# 表示する情報を設定
	rich_text_label.text = current_item.text
	expression.texture = current_item.expression
	body.texture = current_item.character
	# 選択肢ボタンを生成
	create_buttons(current_item.choices)

	# テキストの表示量を0に設定
	rich_text_label.visible_ratio = 0.0
	var tween := create_tween()
	# 表示するテキストの長さから、適切な表示時間を算出
	var text_appearing_duration: float = current_item["text"].length() / 30.0
	# テキストをスムーズに表示
	tween.tween_property(rich_text_label, "visible_ratio", 1.0, text_appearing_duration)

	# テキスト表示音の再生オフセットを算出
	var sound_max_offset := audio_stream_player.stream.get_length() - text_appearing_duration
	var sound_start_position := randf() * sound_max_offset
	# テキスト表示音を再生
	audio_stream_player.play(sound_start_position)
	# テキスト表示終了時、表示音をストップ
	tween.finished.connect(audio_stream_player.stop)
	
	for button: Button in action_buttons_v_box_container.get_children():
		# ボタンを無効化
		button.disabled = true
		button.modulate.a = 0
	
	# テキスト表示終了時
	tween.finished.connect(func() -> void:
		var button_tween := create_tween()
		for button: Button in action_buttons_v_box_container.get_children():
			button.disabled = false
			# ボタンをゆっくりと表示
			button_tween.tween_property(button,"modulate:a", 1.0, 0.3)
	)

func create_buttons(choices_data: Array[DialogueChoice]) -> void:
	# BOX内のボタンを全て削除
	for button in action_buttons_v_box_container.get_children():
		button.queue_free()
	
	# We loop over all the dictionary keys
	for choice in choices_data:
		var button := Button.new()
		action_buttons_v_box_container.add_child(button)
		button.text = choice.text
		if choice.is_quit == true:
			button.pressed.connect(get_tree().quit)
		else:
			var target_line_idx := choice.target_line_idx
			button.pressed.connect(show_text.bind(target_line_idx))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		# 表示するDialogueItemのインデックスをインクリメント
		dialogue_item_index += 1
		show_text(dialogue_item_index)
