## 水面のシェーダー表現を管理する
## 色やサイズ比率のシェーダーパラメータを自動で設定する
@tool
class_name Water extends ColorRect

# ---- エクスポート変数 ----
## 水の色
@export var water_color := Color("2d78ba"): set = set_water_color


## コンストラクタ（マテリアルが未設定の場合にプリロードする）
func _init() -> void:
	if material == null:
		material = preload("water_mat.tres")


## 初期化処理（マテリアルの複製とシェーダーパラメータの設定を行う）
func _ready() -> void:
	# Make the material unique so that changing the ratio
	# of one water bed does not affect other water beds.
	material = material.duplicate()
	# リサイズ時にシェーダーの比率を更新する
	resized.connect(func() -> void: _set_ratio())
	_set_ratio()
	set_water_color(water_color)


## 水の色を設定し、シェーダーパラメータに反映する
func set_water_color(value: Color) -> void:
	water_color = value
	if material != null:
		material.set_shader_parameter("water_color", water_color)


## シェーダーに高さと縦横比パラメータを設定する
func _set_ratio() -> void:
	material.set_shader_parameter("height", size.y)
	material.set_shader_parameter("ratio", size.x / size.y)
