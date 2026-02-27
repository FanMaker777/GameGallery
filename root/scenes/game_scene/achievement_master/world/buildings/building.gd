@tool
## 村の建物（衝突付き）— テクスチャを差し替えて再利用する
## @tool によりエディタ上で Inspector の変更が即座にビューポートへ反映される
class_name Building extends StaticBody2D

# ---- エクスポート変数 ----
# セッターで値を保存した直後に _apply_*() を呼び出し、
# Inspector 変更時にもエディタ上へリアルタイム反映する。

## Inspector からテクスチャを設定する。Sprite2D に即時反映される
@export var building_texture: Texture2D:
	set(value):
		building_texture = value
		_apply_building_texture()

## 建物底部の衝突判定サイズ。CollisionShape2D の矩形サイズに即時反映される
@export var collision_size: Vector2 = Vector2(80, 40):
	set(value):
		collision_size = value
		_apply_collision_size()

## 衝突判定の位置オフセット。CollisionShape2D の position に即時反映される
@export var collision_offset: Vector2 = Vector2(0, 0):
	set(value):
		collision_offset = value
		_apply_collision_offset()

# ========== ライフサイクル ==========

## 初期化 — 全エクスポート変数をノードに反映する
## セッターはノード準備前に呼ばれる場合があるため、
## _ready() で改めて _apply_*() を呼び確実に初期化する
func _ready() -> void:
	_apply_building_texture()
	_apply_collision_size()
	_apply_collision_offset()

# ========== エディタ反映 ==========

## building_texture を Sprite2D に反映する
## null の場合はテクスチャをクリアする
func _apply_building_texture() -> void:
	# ノードツリー構築前（シーンロード中）は何もしない
	if not is_node_ready():
		return
	if building_texture:
		$Sprite2D.texture = building_texture
	else:
		$Sprite2D.texture = null


## collision_size を CollisionShape2D の矩形サイズに反映する
## shape.duplicate() で複製し、インスタンス間で形状を共有しないようにする
func _apply_collision_size() -> void:
	# ノードツリー構築前（シーンロード中）は何もしない
	if not is_node_ready():
		return
	var shape: RectangleShape2D = $CollisionShape2D.shape as RectangleShape2D
	if shape:
		# 元の shape を他インスタンスと共有しないよう複製してから変更
		shape = shape.duplicate()
		shape.size = collision_size
		$CollisionShape2D.shape = shape


## collision_offset を CollisionShape2D の position に反映する
func _apply_collision_offset() -> void:
	# ノードツリー構築前（シーンロード中）は何もしない
	if not is_node_ready():
		return
	$CollisionShape2D.position = collision_offset
