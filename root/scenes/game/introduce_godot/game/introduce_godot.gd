@tool
@icon("uid://c1y5nxj2xu33x")
extends Control

## Audio player that plays voice sounds while text is being written
@onready var audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer
@onready var pause_screen: Control = %PauseScreen

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	Dialogic.start("introduce_godot")
