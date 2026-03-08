## AmAttackComponent の攻撃開始・タイマー・ヒットボックス制御・命中判定をテストする
extends GutTest

# ---- 定数 ----
const AttackComponentScript := preload(
	"res://root/scenes/game_scene/achievement_master/character/Player/am_attack_component.gd"
)
const MockEnemyScript := preload("res://test/helper/mock_enemy.gd")

# ---- インスタンス ----
var _comp: AmAttackComponent
var _sprite: AnimatedSprite2D
var _hitbox: Area2D
var _hitbox_shape: CollisionShape2D


## テスト用の SpriteFrames を生成する（アニメーション名エラー回避）
func _make_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation(&"Attack")
	return frames


## テスト用のコンポーネントと依存ノードを生成する
func before_each() -> void:
	_comp = AttackComponentScript.new()
	add_child_autofree(_comp)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = _make_sprite_frames()
	add_child_autofree(_sprite)
	_hitbox = Area2D.new()
	_hitbox.position.x = 50.0
	add_child_autofree(_hitbox)
	_hitbox_shape = CollisionShape2D.new()
	_hitbox.add_child(_hitbox_shape)
	_comp.initialize(_sprite, _hitbox, _hitbox_shape)


# ==================================================
# start_attack テスト
# ==================================================

func test_start_attack_enables_hitbox() -> void:
	_comp.start_attack()

	assert_true(_hitbox.monitoring, "monitoring が true になる")
	assert_false(_hitbox_shape.disabled, "shape が有効になる")


func test_start_attack_positions_hitbox_right() -> void:
	_sprite.flip_h = false

	_comp.start_attack()

	assert_gt(_hitbox.position.x, 0.0, "flip_h=false 時 hitbox.x > 0")


func test_start_attack_positions_hitbox_left() -> void:
	_sprite.flip_h = true

	_comp.start_attack()

	assert_lt(_hitbox.position.x, 0.0, "flip_h=true 時 hitbox.x < 0")


# ==================================================
# process_tick テスト
# ==================================================

func test_process_tick_finishes_after_duration() -> void:
	_comp.start_attack()
	var finished: Array = []
	_comp.attack_finished.connect(func() -> void: finished.append(true))

	_comp.process_tick(AmAttackComponent.ATTACK_DURATION + 0.01)

	assert_eq(finished.size(), 1, "ATTACK_DURATION 経過で attack_finished が発火する")


func test_process_tick_does_not_finish_early() -> void:
	_comp.start_attack()
	var finished: Array = []
	_comp.attack_finished.connect(func() -> void: finished.append(true))

	_comp.process_tick(AmAttackComponent.ATTACK_DURATION - 0.1)

	assert_eq(finished.size(), 0, "ATTACK_DURATION 未満では発火しない")


# ==================================================
# _finish テスト
# ==================================================

func test_finish_disables_hitbox() -> void:
	_comp.start_attack()

	# 持続時間を超えて _finish を発火させる
	_comp.process_tick(AmAttackComponent.ATTACK_DURATION + 0.01)

	assert_false(_hitbox.monitoring, "終了後 monitoring が false になる")
	assert_true(_hitbox_shape.disabled, "終了後 shape が無効になる")


# ==================================================
# ヒット判定テスト
# ==================================================

func test_hit_detection_emits_signal() -> void:
	var enemy: Node2D = MockEnemyScript.new()
	enemy.add_to_group("enemies")
	add_child_autofree(enemy)
	var hit_results: Array = []
	_comp.attack_hit.connect(func(t: Node2D, d: int) -> void: hit_results.append({"target": t, "damage": d}))

	# body_entered シグナルを手動で発火する
	_comp._on_hitbox_body_entered(enemy)

	assert_eq(hit_results.size(), 1, "attack_hit シグナルが発火する")
	assert_gt(enemy.damage_received, 0, "敵に take_damage が呼ばれる")


func test_hit_ignores_non_enemy() -> void:
	var non_enemy: Node2D = MockEnemyScript.new()
	# enemies グループに追加しない
	add_child_autofree(non_enemy)
	var hit_results: Array = []
	_comp.attack_hit.connect(func(t: Node2D, d: int) -> void: hit_results.append({"target": t, "damage": d}))

	_comp._on_hitbox_body_entered(non_enemy)

	assert_eq(hit_results.size(), 0, "enemies グループ外のボディは無視される")
	assert_eq(non_enemy.damage_received, 0, "take_damage は呼ばれない")
