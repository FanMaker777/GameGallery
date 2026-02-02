@tool
#@icon("res://assets/dialogue_scene_icon.svg")
extends Control

## An array of dictionaries. Each dictionary has three properties:
## - expression: a [code]Texture[/code] containing an expression
## - text: a [code]String[/code] containing the text the character says
## - character: a [code]Texture[/code] representing the character
@export var dialogue_items: Array[DialogueItem] = []:
	set = set_dialogue_items
	

## UI element that shows the texts
@onready var rich_text_label: RichTextLabel = %RichTextLabel
## Audio player that plays voice sounds while text is being written
@onready var audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer
## The character
@onready var body: TextureRect = %Body
## The Expression
@onready var expression: TextureRect = %Expression
@onready var action_buttons_v_box_container: VBoxContainer = %ActionButtonsVBoxContainer


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	show_text(0)

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

## Draws the current text to the rich text element
func show_text(current_item_index: int) -> void:
	# We retrieve the current item from the array
	var current_item := dialogue_items[current_item_index]
	# from the item, we extract the properties.
	# We set the text to the rich text control
	# And we set the appropriate expression texture
	rich_text_label.text = current_item.text
	expression.texture = current_item.expression
	body.texture = current_item.character
	create_buttons(current_item.choices)

	# We set the initial visible ratio to the text to 0, so we can change it in the tween
	rich_text_label.visible_ratio = 0.0
	# We create a tween that will draw the text
	var tween := create_tween()
	# A variable that holds the amount of time for the text to show, in seconds
	# We could write this directly in the tween call, but this is clearer.
	# We will also use this for deciding on the sound length
	var text_appearing_duration: float = current_item["text"].length() / 30.0
	# We show the text slowly
	tween.tween_property(rich_text_label, "visible_ratio", 1.0, text_appearing_duration)
	# We randomize the audio playback's start time to make it sound different
	# every time.
	# We obtain the last possible offset in the sound that we can start from
	var sound_max_offset := audio_stream_player.stream.get_length() - text_appearing_duration
	# We pick a random position on that length
	var sound_start_position := randf() * sound_max_offset
	# We start playing the sound
	audio_stream_player.play(sound_start_position)
	# We make sure the sound stops when the text finishes displaying
	tween.finished.connect(audio_stream_player.stop)

	# We animate the character sliding in.
	slide_in()
	
	for button: Button in action_buttons_v_box_container.get_children():
		button.disabled = true
		# Make the buttons transparent.
		button.modulate.a = 0
		
	tween.finished.connect(func() -> void:
		# We create a tween before the loop to queue the animations.
		var button_tween := create_tween()
		for button: Button in action_buttons_v_box_container.get_children():
			button.disabled = false
			# We tween the modulate property to fade in the button.
			button_tween.tween_property(button,"modulate:a", 1.0, 0.3)
	)
	
	for button: Button in action_buttons_v_box_container.get_children():
		# ボタンを透明にする
		button.modulate.a = 0
	


## Animates the character when they start talking
func slide_in() -> void:
	var slide_tween := create_tween()
	slide_tween.set_ease(Tween.EASE_OUT)
	body.position.x = get_viewport_rect().size.x / 7
	slide_tween.tween_property(body, "position:x", 0, 0.3)
	body.modulate.a = 0
	slide_tween.parallel().tween_property(body, "modulate:a", 1, 0.2)

func set_dialogue_items(new_dialogue_items: Array[DialogueItem]) -> void:
	for index in new_dialogue_items.size():
		if new_dialogue_items[index] == null:
			new_dialogue_items[index] = DialogueItem.new()
	dialogue_items = new_dialogue_items
	update_configuration_warnings()

func _get_configuration_warnings() -> PackedStringArray:
	if dialogue_items.is_empty():
		return ["You need at least one dialogue item for the dialogue system to work."]
	return []
