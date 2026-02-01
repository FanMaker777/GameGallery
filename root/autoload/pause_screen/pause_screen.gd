@tool
extends Control

@onready var _blur_color_rect: ColorRect = %BlurColorRect
@onready var _ui_panel_container: PanelContainer = %UIPanelContainer
@onready var _resume_button: Button = %ResumeButton
@onready var _quit_button: Button = %QuitButton

## ポーズスクリーンの表示量(0=非表示：1=完全に表示)
@export_range(0, 1.0) var menu_opened_amount := 0.0: set = set_menu_opened_amount
## ポーズスクリーンの表示切り替えアニメーションにかかる時間
@export_range(0.1, 10.0, 0.01, "or_greater") var animation_duration := 2.3

var _tween: Tween
var _is_currently_opening := false

func _ready() -> void:
	# エディター上の場合
	if Engine.is_editor_hint():
		return
		
	# ポーズメニューを非表示に設定
	menu_opened_amount = 0.0
	# 再開ボタン押下時、ポーズスクリーンの表示を切り替え
	_resume_button.pressed.connect(toggle)
	# 終了ボタン押下時、ゲーム終了
	_quit_button.pressed.connect(get_tree().quit)

func set_menu_opened_amount(amount: float) -> void:
	menu_opened_amount = amount
	# ノードのvisibleプロパティを変更することで、ポーズ画面が見えないだけでなく、クリックもできないことを保証します。
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
	
	# ゲームを一時停止
	if not Engine.is_editor_hint():
		get_tree().paused = amount > 0.3

func _input(event: InputEvent) -> void:
	# ESCボタン押下時
	if event.is_action_pressed("ESC"):
		# ポーズスクリーンの表示を切り替え
		toggle()

## ポーズスクリーンの表示を切り替えるメソッド
func toggle() -> void:
	# Switch the flag to the opposite value
	_is_currently_opening = not _is_currently_opening

	var duration := animation_duration
	# If there's a tween, and it is animating, we want to kill it.
	# This stops the previous animation.
	if _tween != null:
		# ポーズ画面が開いていない場合
		if not _is_currently_opening:
			# If the previous tween was animating, we want to animate back
			# from the current point in the animation.
			duration = _tween.get_total_elapsed_time()
		_tween.kill()

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_QUART)

	var target_amount := 1.0 if _is_currently_opening else 0.0
	_tween.tween_property(self, "menu_opened_amount", target_amount, duration)
