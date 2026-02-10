## ポーズ/オプションの重なり制御を集約し、入力導線の分散を防ぐ。
extends RefCounted
class_name OverlayController

var _tree: SceneTree
var _pause_screen: Control
var _options_menu: Control
var _pause_screen_enable_scene_paths: PackedStringArray

func _init(
	tree: SceneTree,
	pause_screen: Control,
	options_menu: Control,
	pause_screen_enable_scene_paths: PackedStringArray
) -> void:
	_tree = tree
	_pause_screen = pause_screen
	_options_menu = options_menu
	_pause_screen_enable_scene_paths = pause_screen_enable_scene_paths

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
	return _pause_screen_enable_scene_paths.has(current_scene_path)
