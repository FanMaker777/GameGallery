## エネミー1種類のデータ定義（Inspector 編集可能な Custom Resource）
## ステータス・ドロップ・ビジュアル・AIパラメータをエネミー種別ごとに管理する
class_name EnemyData
extends Resource

## エネミーの表示名（UI等で使用）
@export var display_name: String = ""

## ---- ステータス ----
@export_group("ステータス")
## 最大HP
@export var max_hp: int = 30
## プレイヤーに与える攻撃ダメージ
@export var attack_damage: int = 10

## ---- ドロップ ----
@export_group("ドロップ")
## ドロップアイテムのシーン（drop_item.tscn を設定）
@export var drop_item_scene: PackedScene
## ドロップするリソースの種別
@export var drop_resource_type: ResourceDefinitions.ResourceType = ResourceDefinitions.ResourceType.GOLD
## ドロップするリソースの量
@export var drop_amount: int = 5

## ---- ビジュアル ----
@export_group("ビジュアル")
## エネミーのスプライトフレーム（Attack/Guard/Idle/Run アニメーションを含む）
@export var sprite_frames: SpriteFrames
## flip_hを切り替える最小X速度閾値（ちらつき防止）
@export var flip_threshold: float = 10.0
## 攻撃アニメーションのダメージ適用フレーム（0始まり）
@export_range(1, 6, 1) var attack_hit_frame: int = 3

## ---- AI パラメータ ----
@export_group("AI")
## 追跡時の最大移動速度
@export var chase_speed: float = 125.0
## パトロール時の最大移動速度
@export var patrol_speed: float = 50.0
## 攻撃開始距離
@export var attack_range: float = 75.0
## 攻撃後のクールダウン時間（秒）
@export var attack_cooldown: float = 2.0
## プレイヤー探知範囲の半径
@export var detection_radius: float = 150.0
