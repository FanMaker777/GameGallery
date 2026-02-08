@tool
extends Control

@onready var _blur_color_rect: ColorRect = %BlurColorRect
@onready var _ui_panel_container: PanelContainer = %UIPanelContainer
@onready var _resume_button: Button = %ResumeButton
@onready var _main_menu_button: Button = %MainMenuButton
@onready var _option_button: Button = %OptionButton
@onready var _quit_button: Button = %QuitButton

## ポーズスクリーンの表示量(0=非表示：1=完全に表示)
@export_range(0, 1.0) var menu_opened_amount := 0.0: set = set_menu_opened_amount
## ポーズスクリーンの表示切り替えアニメーションにかかる時間
@export_range(0.1, 10.0, 0.01, "or_greater") var animation_duration := 1.0

## ポーズスクリーンの表示状態
var _is_currently_opening:bool = false
## ポーズスクリーンの表示切り替え状態
var _is_in_toggle:bool = false

func _ready() -> void:
	Log.info("_ready PauseScreen")
	# エディター上の場合
	if Engine.is_editor_hint():
		return
		
	# ポーズメニューを非表示に設定
	menu_opened_amount = 0.0
	# 再開ボタン押下時、ポーズスクリーンの表示を切り替え
	_resume_button.pressed.connect(toggle)
	# メインメニューボタン押下時、メインメニューに遷移
	_main_menu_button.pressed.connect(_pressed_main_menu_button)
	# 終了ボタン押下時、ゲーム終了
	_quit_button.pressed.connect(get_tree().quit)

func set_menu_opened_amount(amount: float) -> void:
	menu_opened_amount = amount
	# visibleプロパティを変更することで、ポーズ画面が見えないだけでなく、クリックもできないことを保証します。
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
		# ポーズスクリーンが一定以上表示時、ゲームを一時停止
		get_tree().paused = amount > 0.3

## ポーズスクリーンの表示を切り替えるメソッド
func toggle() -> void:
	Log.info("toggle PauseScreen")
	# ポーズスクリーンの表示切り替え中の場合
	if _is_in_toggle:
		return
	
	# ポーズスクリーンの表示切り替え状態に設定
	_is_in_toggle = true
	# ポーズスクリーンの表示状態を反転
	_is_currently_opening = not _is_currently_opening
	
	# ポーズスクリーンの表示切り替えアニメーションを設定
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	#　ポーズスクリーンの表示状態に応じて、表示量(0=非表示：1=完全に表示)を設定
	var target_amount := 1.0 if _is_currently_opening else 0.0
	tween.tween_property(self, "menu_opened_amount", target_amount, animation_duration)
	
	# ポーズスクリーンの表示切り替えが終了するまで待機
	await tween.finished
	# ポーズスクリーンの表示切り替え状態を無効に設定
	_is_in_toggle = false

## メインメニューボタン押下時のメソッド
func _pressed_main_menu_button() -> void:
	# ポーズスクリーンの表示切り替え中の場合
	if _is_in_toggle:
		return
	# アドオン「Dailogic」のダイアログを終了
	Dialogic.end_timeline()
	# ポーズスクリーンを非表示にリセット
	_reset()
	# メインメニューに遷移
	GameManager.load_main_menu_scene()

## ポーズスクリーンを非表示にリセットするメソッド
func _reset() -> void:
	# ポーズメニューを非表示に設定
	menu_opened_amount = 0.0
	_is_currently_opening = false
	_is_in_toggle = false
