## 感圧板と連動して開閉するドアの制御を担当する
## 感圧板が押されるとドアが開き、離されると閉じる
@tool
class_name Door extends StaticBody2D

# ---- エクスポート変数 ----
# Exporting a node type like this allows you to assign a node from the scene
# tree to this variable in the editor.
## 連動する感圧板ノード
@export var pressure_plate: PressurePlate = null: set = set_pressure_plate

# ---- 変数 ----
## 開閉アニメーション用Tween
var _tween: Tween = null

# ---- ノード参照 ----
## ドアの見た目（NinePatchRect）
@onready var _sprite: NinePatchRect = %Sprite
## ドアの当たり判定
@onready var _collision_shape: CollisionShape2D = %CollisionShape2D


## 初期化処理（感圧板のシグナルに接続してドアの開閉を制御する）
func _ready() -> void:
	# In the editor, we don't need to connect to the pressure plate's signal.
	if Engine.is_editor_hint():
		return

	# 感圧板が設定されている場合、状態変化シグナルに接続する
	if pressure_plate != null:
		pressure_plate.pressed_state_changed.connect(func(is_pressure_plate_pressed: bool) -> void:
			# The animation of the door is only visual. The collision shape
			# doesn't move, but gets instantly deactivated or activated,
			# depending on the pressure plate, so the player can't get stuck
			# into the door.
			_collision_shape.set_deferred("disabled", is_pressure_plate_pressed)

			# This tween moves the door up and down when the pressure plate is
			# pressed or released.
			if _tween != null and _tween.is_valid():
				_tween.kill()
			_tween = create_tween()
			_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
			const HEIGHT_CLOSED := 48.0
			const HEIGHT_OPENED := 16.0
			_tween.tween_property(
				_sprite,
				"size:y",
				HEIGHT_OPENED if is_pressure_plate_pressed else HEIGHT_CLOSED,
				0.8
			)
		)


## 感圧板プロパティのセッター（設定変更時にエディタ警告を更新する）
# This setter function exists only to update the configuration warnings when
# setting or clearing the pressure plate
func set_pressure_plate(value: PressurePlate) -> void:
	pressure_plate = value
	update_configuration_warnings()


## エディタ上の設定警告を返す（感圧板未設定時に警告を表示する）
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if pressure_plate == null:
		warnings.push_back("The door needs a pressure plate to work (otherwise it won't open).")
	return warnings
