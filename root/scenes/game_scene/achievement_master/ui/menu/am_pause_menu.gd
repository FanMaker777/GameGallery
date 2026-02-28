## Achievement Master 専用の4タブメニュー
## Tab キーで開閉し、ブラー+彩度低下エフェクト付きでゲームを一時停止する
class_name AmPauseMenu extends CanvasLayer

@onready var _menu_content: Control = %MenuContent
@onready var _blur_color_rect: ColorRect = %BlurColorRect
@onready var _menu_panel: PanelContainer = %MenuPanel
@onready var _tab_container: TabContainer = %TabContainer

## メニューの表示量 (0=非表示, 1=完全表示)
@export_range(0, 1.0) var menu_opened_amount := 0.0: set = set_menu_opened_amount

## メニュー表示量のセッター（ブラー・彩度・パネル透過・一時停止を一括制御する）
func set_menu_opened_amount(amount: float) -> void:
	menu_opened_amount = amount
	# MenuContent（Control）の visible を切り替え、描画と入力ブロックを制御する
	if _menu_content != null:
		_menu_content.visible = amount > 0
	# 描画に必要なノードが存在しない場合
	if _blur_color_rect == null or _menu_panel == null:
		return
	# ブラー量を設定（amount が大きいほどブラーがかかる）
	_blur_color_rect.material.set_shader_parameter("blur_amount", lerp(0.0, 1.5, amount))
	# 彩度を設定（amount が大きいほど灰色になる）
	_blur_color_rect.material.set_shader_parameter("saturation", lerp(1.0, 0.3, amount))
	# 色合いの強さを設定
	_blur_color_rect.material.set_shader_parameter("tint_strength", lerp(0.0, 0.2, amount))
	# メニューパネルの透明度を設定
	_menu_panel.modulate.a = amount
	# エディター上でない場合、ゲームの一時停止を制御する
	if not Engine.is_editor_hint():
		get_tree().paused = amount > 0.3

## メニュー表示切り替えアニメーションの時間（秒）
@export_range(0.1, 10.0, 0.01, "or_greater") var animation_duration := 0.8

## メニューが開いている状態かどうか
var _is_currently_opening: bool = false
## 表示切り替えアニメーション中かどうか（再入防止フラグ）
var _is_in_toggle: bool = false


func _ready() -> void:
	Log.info("_ready AmPauseMenu")
	# エディター上の場合は初期化をスキップする
	if Engine.is_editor_hint():
		return
	# メニューを非表示に初期化する
	menu_opened_amount = 0.0
	# タブの表示名を日本語に設定する
	_setup_tab_titles()
	# OverlayController に自身を登録する
	GameManager.overlay_contoroller.register_am_pause_menu(self)


func _exit_tree() -> void:
	# エディター上でない場合、OverlayController から登録を解除する
	if not Engine.is_editor_hint():
		GameManager.overlay_contoroller.unregister_am_pause_menu()


## メニューを非表示にリセットするメソッド（シーン遷移時に呼ばれる）
func reset_state() -> void:
	# メニューを非表示に設定する
	menu_opened_amount = 0.0
	_is_currently_opening = false
	_is_in_toggle = false


## メニューの表示を切り替えるメソッド
func toggle() -> void:
	Log.debug("toggle AmPauseMenu")
	# アニメーション中は再入を防止する
	if _is_in_toggle:
		return
	# 切り替え中フラグを有効にする
	_is_in_toggle = true
	# 表示状態を反転する
	_is_currently_opening = not _is_currently_opening
	# Tween アニメーションを作成する
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	# 表示状態に応じて目標値を設定する（開く=1.0, 閉じる=0.0）
	var target_amount := 1.0 if _is_currently_opening else 0.0
	tween.tween_property(self, "menu_opened_amount", target_amount, animation_duration)
	# アニメーション完了まで待機する
	await tween.finished
	# 切り替え中フラグを解除する
	_is_in_toggle = false


## メニューを閉じるメソッド（ESC キーから呼ばれる場合用）
func close() -> void:
	# メニューが開いていない場合は何もしない
	if not _is_currently_opening:
		return
	# toggle で閉じる
	toggle()


## メニューが表示中かどうかを返すメソッド
func is_menu_visible() -> bool:
	return menu_opened_amount > 0


## タブの表示名を日本語に設定するメソッド
func _setup_tab_titles() -> void:
	# タブインデックスと日本語名の対応
	var tab_titles: PackedStringArray = ["装備", "ステータス", "スキル", "実績"]
	# 各タブに日本語名を設定する
	for i: int in tab_titles.size():
		_tab_container.set_tab_title(i, tab_titles[i])
