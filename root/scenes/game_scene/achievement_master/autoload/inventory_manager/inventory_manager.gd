## インベントリの管理（バッグ・装備）・セーブ/ロードを担当する Autoload
extends Node

# ---- シグナル ----
## バッグ内のアイテム数量が変化したときに発火する
signal bag_changed(id: StringName, new_count: int)
## 装備スロットが変化したときに発火する
signal equipment_changed(slot: int)
## 消耗品が使用されたときに発火する（効果適用は Pawn 側で行う）
signal item_used(id: StringName, definition: ItemDefinition)

# ---- 定数 ----
## セーブファイルのパス
const SAVE_PATH: String = "user://achievement_master_inventory.save"

# ---- アイテムデータベース ----
## preload したアイテム定義リソース
var _database: ItemDatabase = preload(
	"res://root/scenes/game_scene/achievement_master/data/item_database.tres"
)
## { id: ItemDefinition } の高速引きマップ
var _def_map: Dictionary = {}

# ---- インベントリ状態 ----
## バッグ内のアイテム数量 { StringName: int }
var _bag: Dictionary = {}
## 装備スロットごとの装備中アイテムID { EquipSlot: StringName }
var _equipment: Dictionary = {
	EquipmentDefinition.EquipSlot.WEAPON: &"",
	EquipmentDefinition.EquipSlot.ARMOR: &"",
	EquipmentDefinition.EquipSlot.ACCESSORY: &"",
}
## 装備ステータスキャッシュ（装備変更時に更新、Pawn が参照する）
var _equip_cache: EquipmentStatCache = EquipmentStatCache.new()


# ========== ライフサイクル ==========

## 初期化 — 定義マップ構築・セーブ復元・装備キャッシュ再構築
func _ready() -> void:
	# データベースの高速引きマップを構築する
	for def: ItemDefinition in _database.items:
		_def_map[def.id] = def
	# セーブデータを復元する
	_load()
	# 装備キャッシュを再構築する
	_rebuild_equip_cache()
	Log.info("InventoryManager: 初期化完了 (%d件のアイテム定義, バッグ=%d種, 装備=%d)" % [
		_def_map.size(), _bag.size(), _get_equipped_count()
	])


# ========== バッグ操作 API ==========

## バッグにアイテムを追加する（max_stack を超える場合は追加可能な分だけ追加する）
func add_item(id: StringName, count: int = 1) -> bool:
	if not _add_item_internal(id, count):
		return false
	_save()
	return true


## バッグからアイテムを削除する
func remove_item(id: StringName, count: int = 1) -> bool:
	if not _remove_item_internal(id, count):
		return false
	_save()
	return true


## バッグにアイテムを追加する（セーブなし・内部用）
func _add_item_internal(id: StringName, count: int = 1) -> bool:
	if not _def_map.has(id):
		Log.warn("InventoryManager: 未定義のアイテムID — %s" % id)
		return false
	var def: ItemDefinition = _def_map[id]
	var current: int = _bag.get(id, 0)
	# max_stack を超えないように追加数を制限する
	var addable: int = mini(count, def.max_stack - current)
	if addable <= 0:
		Log.debug("InventoryManager: スタック上限のため追加不可 — %s (%d/%d)" % [
			id, current, def.max_stack
		])
		return false
	_bag[id] = current + addable
	bag_changed.emit(id, _bag[id])
	Log.debug("InventoryManager: アイテム追加 %s x%d (所持=%d)" % [id, addable, _bag[id]])
	return true


## バッグからアイテムを削除する（セーブなし・内部用）
func _remove_item_internal(id: StringName, count: int = 1) -> bool:
	var current: int = _bag.get(id, 0)
	if current < count:
		Log.debug("InventoryManager: 所持数不足 — %s (所持=%d, 要求=%d)" % [id, current, count])
		return false
	_bag[id] = current - count
	# 0個になったらバッグから除去する
	if _bag[id] <= 0:
		_bag.erase(id)
	bag_changed.emit(id, _bag.get(id, 0))
	Log.debug("InventoryManager: アイテム削除 %s x%d (残=%d)" % [id, count, _bag.get(id, 0)])
	return true


## 指定アイテムの所持数を返す
func get_item_count(id: StringName) -> int:
	return _bag.get(id, 0)


## 指定アイテムを指定数以上持っているかを返す
func has_item(id: StringName, count: int = 1) -> bool:
	return _bag.get(id, 0) >= count


## バッグ内容のコピーを返す
func get_bag_contents() -> Dictionary:
	return _bag.duplicate()


# ========== 装備操作 API ==========

## アイテムを装備する（バッグから装備スロットへ移動する）
func equip_item(id: StringName) -> bool:
	if not _def_map.has(id):
		Log.warn("InventoryManager: 未定義のアイテムID — %s" % id)
		return false
	var def: ItemDefinition = _def_map[id]
	# 装備品かどうかを確認する
	if not def is EquipmentDefinition:
		Log.debug("InventoryManager: 装備品ではない — %s" % id)
		return false
	var equip_def: EquipmentDefinition = def as EquipmentDefinition
	var slot: EquipmentDefinition.EquipSlot = equip_def.equip_slot
	# バッグに所持しているか確認する
	if not has_item(id):
		Log.debug("InventoryManager: バッグに所持していない — %s" % id)
		return false
	# 既に同じスロットに装備がある場合は外す
	var current_equipped: StringName = _equipment[slot]
	if current_equipped != &"":
		_unequip_to_bag(slot)
	# バッグから1個減らして装備スロットに設定する
	_remove_item_internal(id)
	_equipment[slot] = id
	# 装備キャッシュを再構築する
	_rebuild_equip_cache()
	_save()
	equipment_changed.emit(slot)
	Log.info("InventoryManager: 装備 [%s] → %s" % [
		EquipmentDefinition.EquipSlot.keys()[slot], id
	])
	return true


## 装備を外す（装備スロットからバッグへ戻す）
func unequip_item(slot: EquipmentDefinition.EquipSlot) -> bool:
	var current_id: StringName = _equipment[slot]
	if current_id == &"":
		Log.debug("InventoryManager: スロットが空 — %s" % EquipmentDefinition.EquipSlot.keys()[slot])
		return false
	_unequip_to_bag(slot)
	# 装備キャッシュを再構築する
	_rebuild_equip_cache()
	_save()
	equipment_changed.emit(slot)
	Log.info("InventoryManager: 装備解除 [%s]" % EquipmentDefinition.EquipSlot.keys()[slot])
	return true


## 指定スロットの装備中アイテムIDを返す（未装備は空文字列）
func get_equipped(slot: EquipmentDefinition.EquipSlot) -> StringName:
	return _equipment.get(slot, &"")


## 装備ステータスキャッシュを返す（Pawn が参照する）
func get_equip_cache() -> EquipmentStatCache:
	return _equip_cache


# ========== 消耗品 API ==========

## 消耗品を使用する（バッグから1個消費し、item_used シグナルを発火する）
func use_item(id: StringName) -> bool:
	if not _def_map.has(id):
		Log.warn("InventoryManager: 未定義のアイテムID — %s" % id)
		return false
	var def: ItemDefinition = _def_map[id]
	# 消耗品かどうかを確認する
	if not def is ConsumableDefinition:
		Log.debug("InventoryManager: 消耗品ではない — %s" % id)
		return false
	# バッグに所持しているか確認する
	if not has_item(id):
		Log.debug("InventoryManager: バッグに所持していない — %s" % id)
		return false
	# バッグから1個消費する
	_remove_item_internal(id)
	_save()
	# 効果適用は Pawn 側で行う（シグナルのみ発火）
	item_used.emit(id, def as ConsumableDefinition)
	Log.info("InventoryManager: 消耗品使用 — %s" % id)
	return true


# ========== 定義参照 API ==========

## 指定IDのアイテム定義を返す（未定義の場合は null）
func get_definition(id: StringName) -> ItemDefinition:
	return _def_map.get(id)


## 全アイテム定義を返す
func get_all_definitions() -> Array[ItemDefinition]:
	var result: Array[ItemDefinition] = []
	for def: ItemDefinition in _database.items:
		result.append(def)
	return result


## 全インベントリ状態をリセットする
func reset_inventory() -> void:
	_bag = {}
	_equipment = {
		EquipmentDefinition.EquipSlot.WEAPON: &"",
		EquipmentDefinition.EquipSlot.ARMOR: &"",
		EquipmentDefinition.EquipSlot.ACCESSORY: &"",
	}
	_equip_cache.reset()
	_save()
	Log.info("InventoryManager: 全インベントリをリセットしました")


# ========== 装備キャッシュ（内部） ==========

## 装備中アイテムから装備キャッシュを全再構築する（ロード時・装備変更時に使用）
func _rebuild_equip_cache() -> void:
	_equip_cache.reset()
	for slot: EquipmentDefinition.EquipSlot in _equipment:
		var id: StringName = _equipment[slot]
		if id == &"":
			continue
		var def: ItemDefinition = _def_map.get(id)
		if def != null and def is EquipmentDefinition:
			_equip_cache.apply_equipment(def as EquipmentDefinition)
	Log.debug("InventoryManager: 装備キャッシュ再構築 (HP+%d, ATK+%d, SPD+%.0f%%)" % [
		_equip_cache.hp_flat, _equip_cache.attack_flat, _equip_cache.speed_percent
	])


## スロットの装備品をバッグに戻す（内部ヘルパー）
func _unequip_to_bag(slot: EquipmentDefinition.EquipSlot) -> void:
	var id: StringName = _equipment[slot]
	if id == &"":
		return
	_equipment[slot] = &""
	# バッグに戻す
	_add_item_internal(id)


## 装備中アイテム数を返す（ログ用）
func _get_equipped_count() -> int:
	var count: int = 0
	for slot: EquipmentDefinition.EquipSlot in _equipment:
		if _equipment[slot] != &"":
			count += 1
	return count


# ========== セーブ/ロード ==========

## インベントリ状態をJSONファイルに保存する
func _save() -> void:
	# バッグデータを変換する（StringName → String）
	var bag_data: Dictionary = {}
	for id: StringName in _bag:
		bag_data[String(id)] = _bag[id]
	# 装備データを変換する（EquipSlot int → String キー）
	var equip_data: Dictionary = {}
	for slot: EquipmentDefinition.EquipSlot in _equipment:
		equip_data[str(int(slot))] = String(_equipment[slot])
	var data: Dictionary = {
		"bag": bag_data,
		"equipment": equip_data,
	}
	var json_string: String = JSON.stringify(data, "\t")
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		Log.warn("InventoryManager: セーブ失敗 — %s" % FileAccess.get_open_error())
		return
	file.store_string(json_string)
	file.close()
	Log.debug("InventoryManager: セーブ完了")


## JSONファイルからインベントリ状態を復元する
func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		Log.info("InventoryManager: セーブデータなし — 初回起動")
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		Log.warn("InventoryManager: ロード失敗 — %s" % FileAccess.get_open_error())
		return
	var json_string: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	var error: Error = json.parse(json_string)
	if error != OK:
		Log.warn("InventoryManager: JSONパース失敗 — %s" % json.get_error_message())
		return
	var data: Dictionary = json.data
	# バッグの復元（存在しないIDは除外する）
	_bag = {}
	var bag_data: Dictionary = data.get("bag", {})
	for id_str: String in bag_data:
		var id: StringName = StringName(id_str)
		if _def_map.has(id):
			_bag[id] = int(bag_data[id_str])
	# 装備の復元（存在しないIDは除外する）
	var equip_data: Dictionary = data.get("equipment", {})
	for slot_str: String in equip_data:
		var slot_int: int = int(slot_str)
		var id: StringName = StringName(equip_data[slot_str])
		if id != &"" and _def_map.has(id):
			_equipment[slot_int] = id
		else:
			_equipment[slot_int] = &""
	Log.info("InventoryManager: ロード完了 (バッグ=%d種, 装備=%d)" % [
		_bag.size(), _get_equipped_count()
	])
