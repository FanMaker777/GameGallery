## 会話吹き出しUIの表示・追従・アニメーションを管理する
extends MarginContainer

# ---- ノード参照 ----
## テキスト表示用ラベル
@onready var label: Label = $MarginContainer/Label

# ---- 変数 ----
## 吹き出しが開いているかどうか
var active := false
## 追従対象のノード
var _current_target: Node2D = null
## 自身のサイズの半分（中央揃え用）
var _half_size := Vector2.ONE


## 初期化処理（非表示にして処理を停止し、フォントサイズを設定する）
func _ready() -> void:
	hide()
	set_process(false)
	_set_font_size()


## 吹き出しを開いて対象ノードへの追従を開始する
func open(target: Node2D) -> void:
	active = true
	_current_target = target
	set_process(true)
	show()


## 吹き出しにテキストを表示し、ポップアニメーションを再生する
func write(line: String) -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.1).from(Vector2.ONE * 0.9).set_trans(Tween.TRANS_BACK)
	label.text = line
	# Need to reset size so main container shrinks back?
	size = Vector2.ZERO


## 吹き出しを閉じて縮小アニメーション後に非表示にする
func close() -> void:
	active = false
	set_process(false)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * 0.6, 0.1).from(Vector2.ONE).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	await tween.finished
	# 閉じている最中に再度開かれていなければ非表示にする
	if not active:
		hide()


## 毎フレーム吹き出しの位置を対象ノードに追従させる
func _process(_delta: float) -> void:
	position = _current_target.get_global_transform_with_canvas().origin - (_half_size)


## リサイズ時にフォントサイズとピボットを更新する
func _on_resized() -> void:
	_set_font_size()
	_half_size = size / 2
	pivot_offset = _half_size


## ビューポートサイズに応じてフォントサイズを動的に設定する
func _set_font_size() -> void:
	if not label:
		return
	var viewport_size := get_viewport_rect().size
	var min_size := minf(viewport_size.x, viewport_size.y)
	label.set("theme_override_font_sizes/font_size", min_size * 0.035)
