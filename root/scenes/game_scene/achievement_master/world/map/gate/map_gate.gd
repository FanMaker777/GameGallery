## マップ間遷移のトリガーとなるゲートノード
## プレイヤーが接触すると GameManager 経由でフェード遷移を実行する
class_name MapGate extends Area2D


## 遷移先シーンのパス（res:// 形式）
@export_file("*.tscn") var target_scene_path: String
## ゲートのラベルテキスト（表示名）
@export var gate_label: String = "→ 次のエリア"

## 遷移中フラグ（二重遷移防止）
var _is_transitioning: bool = false

## ラベルノードの参照
@onready var _label: Label = %GateLabel


## 初期化：ラベルテキストを設定し、body_entered シグナルを接続する
func _ready() -> void:
	_label.text = gate_label
	# プレイヤーが接触したら遷移処理を呼ぶ
	body_entered.connect(_on_body_entered)
	Log.debug("MapGate: 初期化完了 (遷移先=%s)" % target_scene_path)


## プレイヤーがゲートに接触した時の処理
func _on_body_entered(body: Node2D) -> void:
	# Pawn（プレイヤー）以外は無視
	if not body is Pawn:
		return
	# 遷移先が未設定の場合は警告して処理しない
	if target_scene_path.is_empty():
		Log.warn("MapGate: target_scene_path が未設定です")
		return
	# 二重遷移を防止
	if _is_transitioning:
		return
	_is_transitioning = true
	Log.info("MapGate: シーン遷移開始 → %s" % target_scene_path)
	# GameManager 経由でフェード遷移を実行
	GameManager.load_scene_with_transition(target_scene_path)
