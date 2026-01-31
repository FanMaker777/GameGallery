extends Control

@export var highlight_color: Color = Color("ffb000")
@export var card_border_color: Color = Color("bcd3ff")
@export var card_background_color: Color = Color("f7f9ff")
@export var card_shadow_color: Color = Color(0, 0, 0, 0.15)

@onready var cards: Array[PanelContainer] = [
	$MainVBox/CardsRow/Card1,
	$MainVBox/CardsRow/Card2,
	$MainVBox/CardsRow/Card3,
	$MainVBox/CardsRow/Card4,
]

var _base_style: StyleBoxFlat
var _selected_style: StyleBoxFlat
var _selected_index := 0

func _ready() -> void:
	_setup_styles()
	for index in cards.size():
		var card := cards[index]
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.gui_input.connect(func(event: InputEvent) -> void:
			_on_card_gui_input(event, index)
		)
	set_selected(0)

func _setup_styles() -> void:
	_base_style = StyleBoxFlat.new()
	_base_style.bg_color = card_background_color
	_base_style.border_color = card_border_color
	_base_style.set_border_width_all(4)
	_base_style.set_corner_radius_all(18)
	_base_style.shadow_color = card_shadow_color
	_base_style.shadow_size = 6
	_base_style.shadow_offset = Vector2(0, 4)

	_selected_style = _base_style.duplicate()
	_selected_style.border_color = highlight_color

func _on_card_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		set_selected(index)

func set_selected(index: int) -> void:
	_selected_index = clamp(index, 0, cards.size() - 1)
	for i in cards.size():
		var style := _base_style
		if i == _selected_index:
			style = _selected_style
		cards[i].add_theme_stylebox_override("panel", style)
