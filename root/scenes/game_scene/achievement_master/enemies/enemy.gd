@tool
## 一般エネミーの基底スクリプト
## アニメーション管理を一元化し、リーフはBlackboard経由で希望アニメーションを指定する
## EnemyData リソースからステータス・ドロップ・ビジュアル・AI パラメータを適用する
## @tool によりエディタ上で EnemyData のスプライト変更がプレビューされる
class_name Enemy extends CharacterBody2D

# ---- シグナル ----
## 死亡時に発火する（AchievementManager 等の外部連携用）
signal died

# ---- エクスポート ----
## エネミーのデータ定義リソース（ステータス・ドロップ・ビジュアル・AI を一括管理）
@export var enemy_data: EnemyData:
	set(value):
		enemy_data = value
		# エディタ上で enemy_data を変更した際にスプライトを即時反映する
		_apply_editor_preview()

# ---- 内部状態（EnemyData から適用される値） ----
## 現在HP
var hp: int = 0
## flip_hを切り替える最小X速度閾値
var _flip_threshold: float = 10.0
## 攻撃アニメーションのダメージ適用フレーム
var _attack_hit_frame: int = 3
## ドロップアイテムのシーン
var _drop_item_scene: PackedScene
## ドロップするリソースの種別
var _drop_resource_type: ResourceDefinitions.ResourceType = ResourceDefinitions.ResourceType.GOLD
## ドロップするリソースの量
var _drop_amount: int = 5
## 死亡演出中フラグ（true の間はダメージ・AI・移動を停止する）
var _is_dying: bool = false
## ヒットフラッシュ用 Tween（連続ヒット時に前回分を停止するため保持する）
var _hit_flash_tween: Tween

@onready var _blackboard: Blackboard = %Blackboard
@onready var _animated_sprite: AnimatedSprite2D = %AnimatedSprite

## 現在再生中のアニメーション名（重複play防止用）
var _current_anim: String = ""

func _ready() -> void:
	# エディタ上ではビジュアルプレビューのみ適用する
	if Engine.is_editor_hint():
		_apply_editor_preview()
		return
	add_to_group("enemies")
	# EnemyData リソースからパラメータを適用する
	_apply_enemy_data()
	# blackboardに初期地点を待機地点として登録
	_blackboard.set_value(BlackBoardValue.IDLE_POSITION, global_position)
	# 攻撃アニメーション完了シグナルを接続
	_animated_sprite.animation_finished.connect(_on_animation_finished)
	# ヒットフレーム検出用のフレーム変化シグナルを接続
	_animated_sprite.frame_changed.connect(_on_frame_changed)


## エディタ上で EnemyData のスプライトをプレビュー表示する
func _apply_editor_preview() -> void:
	# ノードがシーンツリーに入る前（セッター初回呼出時）はスキップする
	if not is_node_ready():
		return
	var sprite: AnimatedSprite2D = %AnimatedSprite
	if sprite == null:
		return
	# EnemyData の SpriteFrames をプレビュー適用する
	if enemy_data != null and enemy_data.sprite_frames != null:
		sprite.sprite_frames = enemy_data.sprite_frames
	else:
		sprite.sprite_frames = null


## EnemyData リソースから各種パラメータを適用する（ランタイム専用）
func _apply_enemy_data() -> void:
	# EnemyData が未設定の場合はエラーログを出力して処理を中断する
	if enemy_data == null:
		Log.warn("Enemy: enemy_data が未設定です（ノード: %s）" % name)
		return
	# ステータスを適用する
	hp = enemy_data.max_hp
	# ビジュアルを適用する（SpriteFrames の差し替え）
	if enemy_data.sprite_frames != null:
		_animated_sprite.sprite_frames = enemy_data.sprite_frames
	# アニメーション調整値を適用する
	_flip_threshold = enemy_data.flip_threshold
	_attack_hit_frame = enemy_data.attack_hit_frame
	# ドロップ設定を適用する
	_drop_item_scene = enemy_data.drop_item_scene
	_drop_resource_type = enemy_data.drop_resource_type
	_drop_amount = enemy_data.drop_amount
	# Blackboard に AI パラメータを書き込む（リーフが参照するため）
	_blackboard.set_value(BlackBoardValue.ATTACK_DAMAGE, enemy_data.attack_damage)
	_blackboard.set_value(BlackBoardValue.MOVE_SPEED, enemy_data.chase_speed)
	_blackboard.set_value(BlackBoardValue.PATROL_SPEED, enemy_data.patrol_speed)
	_blackboard.set_value(BlackBoardValue.ATTACK_RANGE, enemy_data.attack_range)
	_blackboard.set_value(BlackBoardValue.ATTACK_COOLDOWN, enemy_data.attack_cooldown)
	# DetectArea の検知半径を適用する（shape を複製して他インスタンスへの影響を防ぐ）
	var detect_collision: CollisionShape2D = %DetectArea.get_child(0) as CollisionShape2D
	if detect_collision != null:
		var new_shape: CircleShape2D = detect_collision.shape.duplicate() as CircleShape2D
		new_shape.radius = enemy_data.detection_radius
		detect_collision.shape = new_shape
	Log.debug("Enemy: EnemyData 適用完了 (%s, HP=%d)" % [enemy_data.display_name, hp])


func _physics_process(_delta: float) -> void:
	# エディタ上ではゲームロジックを実行しない
	if Engine.is_editor_hint():
		return
	# 死亡演出中はアニメーション更新を停止する
	if _is_dying:
		return
	# --- アニメーション管理（一元化） ---
	# リーフがBlackboardに書いた希望アニメーションを読み取り、重複再生を防止しつつ更新
	var desired_anim: String = _blackboard.get_value(
		BlackBoardValue.DESIRED_ANIM_STATE, "Idle"
	)
	_update_animation(desired_anim)

	# --- flip_h管理（閾値付きでちらつき防止） ---
	if absf(velocity.x) > _flip_threshold:
		_animated_sprite.flip_h = velocity.x < 0.0

## アニメーションを更新する（重複再生を防止）
func _update_animation(anim_name: String) -> void:
	if _current_anim != anim_name:
		_animated_sprite.play(anim_name)
		_current_anim = anim_name

## 攻撃アニメーションのヒットフレーム到達時にブラックボードを更新する
func _on_frame_changed() -> void:
	if _animated_sprite.animation == &"Attack" and _animated_sprite.frame == _attack_hit_frame:
		_blackboard.set_value(BlackBoardValue.ATTACK_HIT_FRAME_REACHED, true)


## 攻撃アニメーション完了時のコールバック
func _on_animation_finished() -> void:
	if _animated_sprite.animation == &"Attack":
		_blackboard.set_value(BlackBoardValue.ATTACK_ANIM_FINISHED, true)

## Playerの攻撃ヒットボックスから呼ばれる — ダメージを受ける
func take_damage(amount: int) -> void:
	# 死亡演出中はダメージを無視する
	if _is_dying:
		return
	hp -= amount
	Log.info("Enemy: ダメージ %d を受けた (残HP: %d)" % [amount, hp])
	if hp <= 0:
		_die()
	else:
		_play_hit_flash()


## 被ダメージ時の白フラッシュ演出（modulate を一瞬白くして戻す）
func _play_hit_flash() -> void:
	# 前回のフラッシュが残っていれば停止してから新たに開始する
	if _hit_flash_tween and _hit_flash_tween.is_valid():
		_hit_flash_tween.kill()
	_animated_sprite.modulate = Color(3.0, 3.0, 3.0, 1.0)
	_hit_flash_tween = create_tween()
	_hit_flash_tween.tween_property(_animated_sprite, "modulate", Color.WHITE, 0.15)


## 死亡処理 — 演出・ドロップ生成後に queue_free で削除する
func _die() -> void:
	Log.info("Enemy: 死亡 [%s]" % name)
	AudioManager.play_se(AudioConsts.SE_ENEMY_DEFEAT)
	# 死亡演出中フラグを立てる（ダメージ・AI・移動を停止）
	_is_dying = true
	# BeehaveTree の処理を停止する
	set_physics_process(false)
	set_process(false)
	# コリジョンを無効化して他オブジェクトとの衝突を防ぐ
	collision_layer = 0
	collision_mask = 0
	# DetectArea のモニタリングを停止する
	var detect_area: Area2D = %DetectArea
	detect_area.monitoring = false
	# 移動を停止する
	velocity = Vector2.ZERO
	# 死亡シグナルを発火する（AchievementManager 等の外部連携用）
	died.emit()
	# ドロップアイテムをワールドに生成する
	_spawn_drop_item()
	# 死亡演出を再生し、完了を待つ
	await _play_death_effect()
	# ノードを削除する（GenericSpawner の tree_exited が発火 → 再スポーン）
	queue_free()


## ドロップアイテムをワールドに生成する
func _spawn_drop_item() -> void:
	# シーンが未設定の場合はスキップする（安全ガード）
	if _drop_item_scene == null:
		return
	# DropItem インスタンスを生成する
	var drop: Node2D = _drop_item_scene.instantiate()
	# 自身の位置にドロップアイテムを配置する
	drop.global_position = global_position
	# リソース種別とドロップ量を設定する
	drop.resource_type = _drop_resource_type
	drop.amount = _drop_amount
	# シーンのルートに追加する（親がSpawner等の場合でも正しい位置に配置される）
	# physics コールバック中は即時追加できないため call_deferred を使用
	get_tree().current_scene.call_deferred("add_child", drop)
	Log.info("Enemy: ドロップアイテム生成 (%s x%d)" % [ResourceDefinitions.ResourceType.keys()[_drop_resource_type], _drop_amount])


## 死亡演出 — 白フラッシュ3回 → フェードアウト + 縮小（合計約0.7秒）
func _play_death_effect() -> void:
	var tween: Tween = create_tween()
	# フェーズ1: 白フラッシュ3回（modulate を明るく→元に戻す × 3、計約0.3秒）
	for i: int in range(3):
		# 白く光らせる（0.05秒）
		tween.tween_property(_animated_sprite, "modulate", Color(3.0, 3.0, 3.0, 1.0), 0.05)
		# 元の色に戻す（0.05秒）
		tween.tween_property(_animated_sprite, "modulate", Color.WHITE, 0.05)
	# フェーズ2: フェードアウト + 縮小（0.4秒）
	tween.set_parallel(true)
	# 透明度を 0 にフェードアウトする
	tween.tween_property(_animated_sprite, "modulate:a", 0.0, 0.4) \
		.set_trans(Tween.TRANS_BACK)
	# スケールを縮小する
	tween.tween_property(self, "scale", Vector2(0.3, 0.3), 0.4) \
		.set_trans(Tween.TRANS_BACK)
	# Tween 完了を待つ
	await tween.finished


func _on_detect_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_blackboard.set_value(BlackBoardValue.IS_PLAYER_VISIBLE, true)

func _on_detect_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_blackboard.set_value(BlackBoardValue.IS_PLAYER_VISIBLE, false)
