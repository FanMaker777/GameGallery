## 画面遷移の実行を担当するクラス
class_name SceneNavigator extends Node2D

@onready var _tree: SceneTree = get_tree()
@onready var _transition_effect_layer: CanvasLayer = %TransitionEffectLayer

## 画面遷移判定(true:画面遷移中, false：画面遷移中ではない)
var _is_transitioning: bool = false

## 遷移エフェクト付きで引数のシーンに遷移するメソッド
func load_scene_with_transition(load_to_scene_path: String) -> void:
	# 遷移先のシーンをパスから生成
	var load_to_scene: PackedScene = load(load_to_scene_path)
	Log.info("func load_scene_with_transition", load_to_scene)
	
	if load_to_scene == null:
		Log.warn("遷移先シーンが null のため遷移を中止")
		return

	if _is_transitioning:
		Log.warn("遷移中のためリクエストを無視")
		return
	
	# 画面遷移中に設定
	_is_transitioning = true
	# 遷移エフェクト付きでフェードアウト
	_transition_effect_layer.fade_out()
	# フェードアウト完了まで待機
	await _transition_effect_layer.finished_fade_out
	
	# シーンチェンジのエラー確認
	var error: Error = _tree.change_scene_to_packed(load_to_scene)
	if error != OK:
		Log.error("シーン遷移に失敗", error)
		_is_transitioning = false
		return
	
	#  シーンチェンジ完了まで待機
	await _tree.scene_changed
	# 遷移エフェクト付きでフェードイン
	_transition_effect_layer.fade_in()
	# 画面遷移外に設定
	_is_transitioning = false
