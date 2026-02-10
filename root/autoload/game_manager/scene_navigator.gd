## 画面遷移の実行責務を分離し、GameManagerをFacadeとして軽量に保つ。
extends RefCounted
class_name SceneNavigator

var _tree: SceneTree
var _transition_effect_layer: CanvasLayer
var _is_transitioning: bool = false

func _init(tree: SceneTree, transition_effect_layer: CanvasLayer) -> void:
	_tree = tree
	_transition_effect_layer = transition_effect_layer

func load_scene_with_transition(load_to_scene: PackedScene) -> void:
	if load_to_scene == null:
		Log.warn("load_to_scene が null のため遷移を中止")
		return

	if _is_transitioning:
		Log.warn("遷移中のためリクエストを無視")
		return

	_is_transitioning = true
	_transition_effect_layer.fade_out()
	await _transition_effect_layer.finished_fade_out

	var error: Error = _tree.change_scene_to_packed(load_to_scene)
	if error != OK:
		Log.error("シーン遷移に失敗", error)
		_is_transitioning = false
		return

	await _tree.scene_changed
	_transition_effect_layer.fade_in()
	_is_transitioning = false
