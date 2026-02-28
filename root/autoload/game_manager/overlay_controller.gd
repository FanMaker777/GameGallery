## オーバーレイUIの操作を担当するクラス
class_name OverlayController extends Node2D

@onready var _tree: SceneTree = get_tree()
@onready var _pause_screen: Control = %PauseScreen
@onready var _options_menu: OptionsMenu = %OptionsMenu

## Achievement Master 専用メニューへの参照（シーンローカルノードが登録する）
var _am_pause_menu: AmPauseMenu = null

## AmPauseMenu を OverlayController に登録するメソッド
func register_am_pause_menu(menu: AmPauseMenu) -> void:
	_am_pause_menu = menu
	Log.debug("OverlayController: AmPauseMenu 登録")

## AmPauseMenu の登録を解除するメソッド
func unregister_am_pause_menu() -> void:
	_am_pause_menu = null
	Log.debug("OverlayController: AmPauseMenu 登録解除")

## オーバーレイUIを非表示状態にリセットするメソッド
func reset_overlays() -> void:
	_options_menu.close()
	# シーン遷移前にポーズ状態を解除し、次シーンへ pause 状態を持ち越さない。
	_pause_screen.reset_state()
	# AmPauseMenu が登録されている場合はリセットする
	if _am_pause_menu != null and is_instance_valid(_am_pause_menu):
		_am_pause_menu.reset_state()

## Autoloadに含まれるオプションメニューを表示するメソッド
func open_options_menu() -> void:
	_options_menu.open()

## Autoloadに含まれるポーズスクリーンの表示切替するメソッド
func toggle_pause_screen() -> void:
	_pause_screen.toggle()

## ESCボタン押下イベントを処理するメソッド
func handle_input_esc(event: InputEvent) -> void:
	if not event.is_action_pressed("ESC"):
		return

	# オプションメニューの表示が有効な場合
	if _options_menu.visible:
		_options_menu.close()
		return

	# AmPauseMenu が表示中の場合は ESC で閉じる
	if _am_pause_menu != null and is_instance_valid(_am_pause_menu) and _am_pause_menu.is_menu_visible():
		_am_pause_menu.close()
		return

	# ポーズスクリーンが表示可能なシーンの場合
	if _can_toggle_pause_screen():
		_pause_screen.toggle()

## open_menu 入力イベントを処理するメソッド（Tab キー）
func handle_input_open_menu(event: InputEvent) -> void:
	if not event.is_action_pressed("open_menu"):
		return
	# オプションメニュー表示中は Tab を無視する
	if _options_menu.visible:
		return
	# PauseScreen が表示中は Tab を無視する
	if _pause_screen.visible:
		return
	# AmPauseMenu が登録されていない場合は無視する
	if _am_pause_menu == null or not is_instance_valid(_am_pause_menu):
		return
	# AmPauseMenu の表示を切り替える
	_am_pause_menu.toggle()

## 現在シーンがポーズスクリーン表示可能か判定するメソッド
func _can_toggle_pause_screen() -> bool:
	var current_scene: Node = _tree.current_scene
	if current_scene == null:
		return false

	var current_scene_path: String = current_scene.scene_file_path
	return PathConsts.PAUSE_SCREEN_ENABLE_SCENES.has(current_scene_path)
