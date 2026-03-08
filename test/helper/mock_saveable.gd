## テスト用の Saveable モック
## 単一キーまたは複数キーの Saveable をシミュレートする
extends Node

## セーブキー（テストで設定する）
var _keys: Array[StringName] = []
## キーごとのセーブデータ
var data_store: Dictionary = {}
## reset_save_state が呼ばれた回数
var reset_count: int = 0


func setup_keys(keys: Array[StringName]) -> void:
	_keys = keys


func get_save_keys() -> Array[StringName]:
	return _keys


func get_save_data_for_key(key: StringName) -> Dictionary:
	return data_store.get(key, {})


func load_save_data_for_key(key: StringName, data: Dictionary) -> void:
	data_store[key] = data


func reset_save_state() -> void:
	reset_count += 1
	data_store = {}
