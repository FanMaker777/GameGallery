## オーバーレイUIの操作を担当するクラス
class_name OverlayController extends Node2D

@onready var _tree: SceneTree = get_tree()
@onready var _pause_screen: Control = %PauseScreen
@onready var _options_menu: Control = %OptionsMenu

## ポーズスクリーンの表示が可能なシーンのパスリスト
const PAUSE_SCREEN_ENABLE_SCENE_PATHS: PackedStringArray = [
	"res://root/scenes/game_scene/introduce_godot/game/introduce_godot.tscn"
]

func _ready() -> void:
	if _pause_screen.has_signal("option_requested"):
		_pause_screen.option_requested.connect(_open_options_menu)

func handle_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ESC"):
		return

	if _options_menu.visible:
		_options_menu.close()
		return

	if _can_toggle_pause_screen():
		_pause_screen.toggle()

func reset_overlays() -> void:
	if _options_menu.visible:
		_options_menu.close()

	# シーン遷移前にポーズ状態を解除し、次シーンへ pause 状態を持ち越さない。
	if _pause_screen.has_method("reset_state"):
		_pause_screen.reset_state()

func _open_options_menu() -> void:
	_options_menu.open()

func _can_toggle_pause_screen() -> bool:
	var current_scene: Node = _tree.current_scene
	if current_scene == null:
		return false

	var current_scene_path: String = current_scene.scene_file_path
	return PAUSE_SCREEN_ENABLE_SCENE_PATHS.has(current_scene_path)
