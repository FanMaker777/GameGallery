## テスト用のリソースノードモック
extends Node2D

var _gather_data: Dictionary = {}
var _harvest_result: Dictionary = {}
var harvest_called: bool = false


func setup_gather(gather_data: Dictionary, harvest_result: Dictionary) -> void:
	_gather_data = gather_data
	_harvest_result = harvest_result


func get_gather_data() -> Dictionary:
	return _gather_data


func harvest() -> Dictionary:
	harvest_called = true
	return _harvest_result
