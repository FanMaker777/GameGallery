extends Node2D

@onready var _end_flag: EndFlag = %EndFlag
@onready var _clear_screen: ClearScreen = %ClearScreen

func _ready() -> void:
	
	_end_flag.body_entered.connect(func (body: Node2D) -> void:
		await get_tree().create_timer(2.0).timeout
		_clear_screen.open()
	)
