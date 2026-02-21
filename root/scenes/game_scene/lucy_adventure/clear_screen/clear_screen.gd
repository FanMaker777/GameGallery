@tool
class_name ClearScreen extends Control

@onready var _blur_color_rect: ColorRect = %BlurColorRect
@onready var _ui_panel_container: PanelContainer = %UIPanelContainer
@onready var _retry_button: Button = %RetryButton
@onready var _main_menu_button: Button = %MainMenuButton

## クリアスクリーンの表示量(0=非表示：1=完全に表示)
@export_range(0, 1.0) var menu_opened_amount := 0.0: set = set_menu_opened_amount
func set_menu_opened_amount(amount: float) -> void:
	menu_opened_amount = amount
	# visibleプロパティを変更することで、クリア画面が見えないだけでなく、クリックもできないことを保証します。
	# UIノードのvisibleプロパティがfalseの場合、入力イベントを受け取りません。
	visible = amount > 0
	# 描画に必要なノードが存在しない場合
	if _ui_panel_container == null or _blur_color_rect == null:
		return
	
	# ブラー量を設定(amoutが大きいほどブラーがかかる)
	_blur_color_rect.material.set_shader_parameter("blur_amount", lerp(0.0, 1.5, amount))
	# ブラーの彩度を設定(amoutが大きいほど灰色になる)
	_blur_color_rect.material.set_shader_parameter("saturation", lerp(1.0, 0.3, amount))
	# ブラーの色合いを設定
	_blur_color_rect.material.set_shader_parameter("tint_strength", lerp(0.0, 0.2, amount))
	# UIパネルの透明度を設定
	_ui_panel_container.modulate.a = amount
	
	# エディター上ではない場合
	if not Engine.is_editor_hint():
		# クリアスクリーンが一定以上表示時、ゲームを一時停止
		get_tree().paused = amount > 0.3

## クリアスクリーンの表示切り替えアニメーションにかかる時間
@export_range(0.1, 10.0, 0.01, "or_greater") var animation_duration := 1.0

## スクリーンの表示切り替え状態
var _is_in_toggle:bool = false

func _ready() -> void:
	# エディター上の場合
	if Engine.is_editor_hint():
		return
		
	# クリアスクリーンを非表示に設定
	menu_opened_amount = 0.0
	# リトライボタン押下時、プラットフォーマーシーンに遷移
	_retry_button.pressed.connect(func() -> void:
		# クリアスクリーンの表示切り替え中の場合
		if _is_in_toggle:
			return
		
		GameManager.load_scene_with_transition(PathConsts.LUCY_ADVENTURE_SCENE)
		)
	# メインメニューボタン押下時、メインスクリーンに遷移
	_main_menu_button.pressed.connect(_pressed_main_menu_button)

## クリアスクリーンを非表示にリセットするメソッド
func reset_state() -> void:
	# クリアスクリーンを非表示に設定
	menu_opened_amount = 0.0
	_is_in_toggle = false

## クリアスクリーンの表示を切り替えるメソッド
func open() -> void:
	# クリアスクリーンの表示切り替え状態に設定
	_is_in_toggle = true
	
	# クリアスクリーンの表示切り替えアニメーションを設定
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	tween.tween_property(self, "menu_opened_amount", 1.0, animation_duration)
	
	# クリアスクリーンの表示切り替えが終了するまで待機
	await tween.finished
	# クリアスクリーンの表示切り替え状態を無効に設定
	_is_in_toggle = false

## メインメニューボタン押下時のメソッド
func _pressed_main_menu_button() -> void:
	# クリアスクリーンの表示切り替え中の場合
	if _is_in_toggle:
		return
	# クリアスクリーンを非表示にリセット
	reset_state()
	# メインスクリーンに遷移
	GameManager.load_scene_with_transition(PathConsts.MAIN_MENU_SCENE)
