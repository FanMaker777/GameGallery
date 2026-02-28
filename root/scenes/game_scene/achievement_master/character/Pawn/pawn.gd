## プレイヤーが操作するキャラクター
## 移動・採取・攻撃・被ダメージの行動を状態で管理する
class_name Pawn extends CharacterBody2D

# ---- 定数 ----
## 移動速度（ピクセル/秒）
const SPEED: float = 200.0
## プレイヤーの攻撃力
const ATTACK_DAMAGE: int = 10
## 攻撃アニメーションの持続時間（秒）
const ATTACK_DURATION: float = 0.4
## 最大HP
const MAX_HP: int = 100
## 被ダメージ後の無敵時間（秒）
const INVINCIBLE_DURATION: float = 1.0
## 戦闘状態の持続時間（最後の戦闘行動からの秒数）
const COMBAT_COOLDOWN: float = 5.0
## 無敵中のスプライト点滅間隔（秒）
const _BLINK_INTERVAL: float = 0.1
## 死亡からリスポーンまでの待機時間（秒）
const RESPAWN_DELAY: float = 2.0

# ---- 状態 ----
## プレイヤーの行動状態
enum State { IDLE, MOVE, GATHER, ATTACK, DEAD }
## 現在の行動状態
var _state: State = State.IDLE

# ---- HP関連 ----
## 現在HP
var hp: int = MAX_HP
## 無敵状態フラグ（被ダメージ後の一時無敵）
var _is_invincible: bool = false
## 無敵タイマー（残り秒数）
var _invincible_timer: float = 0.0
## 点滅用タイマー（スプライトの表示/非表示切り替え用）
var _blink_timer: float = 0.0

# ---- 採取関連 ----
## 採取中の対象ノード
var _gather_target: Node2D = null
## 採取経過時間
var _gather_timer: float = 0.0
## 採取に必要な時間
var _gather_duration: float = 0.0

# ---- 攻撃関連 ----
## 攻撃経過時間
var _attack_timer: float = 0.0

# ---- 戦闘状態 ----
## 戦闘中フラグ
var _is_in_combat: bool = false
## 戦闘状態クールダウン残り時間
var _combat_cooldown: float = 0.0

# ---- インベントリ ----
## リソース種別ごとの所持数
var _inventory: Dictionary = {
	ResourceDefinitions.ResourceType.WOOD: 0,
	ResourceDefinitions.ResourceType.GOLD: 0,
	ResourceDefinitions.ResourceType.MEAT: 0,
}

# ---- シグナル ----
## インベントリのリソース量が変化したときに発火する
signal inventory_changed(type: ResourceDefinitions.ResourceType, new_amount: int)
## 攻撃が敵に命中したときに発火する
signal attack_landed(target: Node2D, damage: int)
## HPが変化したときに発火する（HUD連携用）
signal health_changed(current_hp: int, max_hp: int)
## 死亡したときに発火する
signal died
## 攻撃を開始したときに発火する（AchievementManager 連携用）
signal attack_started
## 戦闘状態が変化したときに発火する（ToastManager 連携用）
signal combat_state_changed(is_in_combat: bool)

# ---- ノードキャッシュ ----
## アニメーションスプライト
@onready var _animated_sprite: AnimatedSprite2D = %AnimatedSprite
## リソースノード検知エリア
@onready var _interact_area: Area2D = $InteractArea
## インタラクトプロンプトラベル
@onready var _interact_label: Label = %InteractLabel
## 攻撃判定エリア
@onready var _attack_hitbox: Area2D = $AttackHitbox
## 攻撃判定のコリジョン形状
@onready var _attack_hitbox_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D

# ========== ライフサイクル ==========

## 初期化 — グループ登録、ヒットボックス無効化、シグナル接続
func _ready() -> void:
	add_to_group("player")
	# 攻撃ヒットボックスは通常時無効
	_attack_hitbox.monitoring = false
	_attack_hitbox_shape.disabled = true
	# シグナル接続
	_attack_hitbox.body_entered.connect(_on_attack_hitbox_body_entered)
	# ポップアップ初期非表示
	_interact_label.visible = false
	# HP初期値を通知（HUD初期化用）
	health_changed.emit(hp, MAX_HP)
	# 実績マネージャーにプレイヤーを登録する
	AchievementManager.register_player(self)
	Log.info("Pawn: 初期化完了 (HP=%d/%d)" % [hp, MAX_HP])


## 毎フレームの物理処理 — 状態に応じた処理を振り分ける
func _physics_process(delta: float) -> void:
	# 無敵タイマーは状態に関わらず常に処理する
	_process_invincibility(delta)
	# 戦闘状態クールダウンを処理する
	_process_combat_cooldown(delta)

	match _state:
		State.IDLE, State.MOVE:
			_process_movement()
			_process_action_input()
			# 最寄りのインタラクト対象に応じてプロンプト表示を切り替え
			var nearest: Node2D = _get_nearest_interactable()
			if nearest != null:
				_interact_label.visible = true
				_interact_label.text = "E 話す" if nearest.is_in_group("npc") else "E 採取"
			else:
				_interact_label.visible = false
		State.GATHER:
			_process_gather_tick(delta)
			_interact_label.visible = false
		State.ATTACK:
			_process_attack_tick(delta)
			_interact_label.visible = false
		State.DEAD:
			# 死亡中は全入力を無視する
			_interact_label.visible = false

# ========== HP・ダメージ処理 ==========

## 外部からダメージを受ける — 無敵中はスキップ、HP0以下で死亡
func take_damage(amount: int) -> void:
	# 無敵中または死亡中はダメージを無視
	if _is_invincible or _state == State.DEAD:
		return
	# HP を減算（0未満にはしない）
	hp = maxi(hp - amount, 0)
	_enter_combat()
	health_changed.emit(hp, MAX_HP)
	Log.info("Pawn: ダメージ %d を受けた (残HP: %d/%d)" % [amount, hp, MAX_HP])
	if hp <= 0:
		# HPが0になったら死亡処理へ
		_die()
	else:
		# 被ダメージ後の無敵状態を開始（連続ダメージ防止）
		_start_invincibility()


## 死亡処理 — 入力無効化、アニメーション、シグナル発火、リスポーン開始
func _die() -> void:
	_set_state(State.DEAD)
	velocity = Vector2.ZERO
	# 無敵状態を解除してスプライトを確実に表示する
	_is_invincible = false
	_animated_sprite.visible = true
	_animated_sprite.play("Idle")
	died.emit()
	Log.info("Pawn: 死亡")
	# 一定時間後に村へリスポーンする
	_start_respawn_timer()


## リスポーンタイマーを開始する
func _start_respawn_timer() -> void:
	var timer: SceneTreeTimer = get_tree().create_timer(RESPAWN_DELAY)
	timer.timeout.connect(_respawn)


## 村シーンの中央にリスポーンする
func _respawn() -> void:
	Log.info("Pawn: 村にリスポーン")
	GameManager.load_scene_with_transition(PathConsts.AM_VILLAGE_SCENE)


## 無敵状態を開始する — 一定時間ダメージを無効化し、スプライトを点滅させる
func _start_invincibility() -> void:
	_is_invincible = true
	_invincible_timer = INVINCIBLE_DURATION
	_blink_timer = 0.0


## 無敵タイマーを進める — 時間経過で無敵解除、点滅演出を処理する
func _process_invincibility(delta: float) -> void:
	if not _is_invincible:
		return
	_invincible_timer -= delta
	# 点滅演出: 一定間隔でスプライトの表示/非表示を切り替える
	_blink_timer += delta
	if _blink_timer >= _BLINK_INTERVAL:
		_blink_timer -= _BLINK_INTERVAL
		_animated_sprite.visible = not _animated_sprite.visible
	# 無敵時間が終了したら解除
	if _invincible_timer <= 0.0:
		_is_invincible = false
		_animated_sprite.visible = true

# ========== 移動処理 ==========

## 入力方向に応じて移動・アニメーションを処理する
func _process_movement() -> void:
	var dir: Vector2 = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	# 斜め移動の速度を正規化
	if dir.length() > 1.0:
		dir = dir.normalized()

	if dir != Vector2.ZERO:
		velocity = dir * SPEED
		_set_state(State.MOVE)
		_animated_sprite.play("Run")
		# 左右フリップ
		if dir.x != 0.0:
			_animated_sprite.flip_h = dir.x < 0.0
	else:
		velocity = Vector2.ZERO
		if _state == State.MOVE:
			_set_state(State.IDLE)
			_animated_sprite.play("Idle")

	move_and_slide()

## 採取・会話・攻撃の入力を処理する
func _process_action_input() -> void:
	if Input.is_action_just_pressed("interact"):
		var nearest: Node2D = _get_nearest_interactable()
		if nearest != null:
			# NPC の場合は会話、リソースノードの場合は採取
			if nearest.is_in_group("npc"):
				_start_talk(nearest)
			else:
				_start_gather(nearest)
	elif Input.is_action_just_pressed("attack"):
		_start_attack()

# ========== 採取処理 ==========

## 採取を開始する — 対象ノードから設定を取得しアニメーション再生
func _start_gather(node: Node2D) -> void:
	if not node.has_method("get_gather_data"):
		return
	var data: Dictionary = node.get_gather_data()
	# 枯渇チェック
	if data.is_empty():
		return
	_gather_target = node
	_gather_duration = data.get("gather_time", 1.0)
	_gather_timer = 0.0
	velocity = Vector2.ZERO
	_set_state(State.GATHER)
	_animated_sprite.play(data.get("gather_animation", "Attack1"))
	Log.info("Pawn: 採取開始 → %s" % node.name)


## 採取タイマーを進め、完了したら収穫処理を呼ぶ
func _process_gather_tick(delta: float) -> void:
	_gather_timer += delta
	if _gather_timer >= _gather_duration:
		_finish_gather()


## 採取完了 — リソースをインベントリに追加
func _finish_gather() -> void:
	if _gather_target != null and is_instance_valid(_gather_target) and _gather_target.has_method("harvest"):
		var result: Dictionary = _gather_target.harvest()
		if not result.is_empty():
			var type: ResourceDefinitions.ResourceType = result.get("type")
			var amount: int = result.get("amount", 0)
			_add_resource(type, amount)
			Log.info("Pawn: 採取完了 %s x%d" % [
				ResourceDefinitions.get_type_name(type), amount
			])
	_gather_target = null
	_set_state(State.IDLE)
	_animated_sprite.play("Idle")


# ========== 攻撃処理 ==========

## 攻撃を開始する — アニメ再生、ヒットボックス有効化
func _start_attack() -> void:
	_attack_timer = 0.0
	velocity = Vector2.ZERO
	_set_state(State.ATTACK)
	_enter_combat()
	attack_started.emit()
	_animated_sprite.play("Attack")
	# ヒットボックスの向きを flip_h に合わせる
	var dir_sign: float = -1.0 if _animated_sprite.flip_h else 1.0
	_attack_hitbox.position.x = absf(_attack_hitbox.position.x) * dir_sign
	# ヒットボックスを有効化
	_attack_hitbox.monitoring = true
	_attack_hitbox_shape.disabled = false


## 攻撃タイマーを進め、持続時間を超えたら攻撃終了
func _process_attack_tick(delta: float) -> void:
	_attack_timer += delta
	if _attack_timer >= ATTACK_DURATION:
		_finish_attack()


## 攻撃終了 — ヒットボックス無効化
func _finish_attack() -> void:
	_attack_hitbox.monitoring = false
	_attack_hitbox_shape.disabled = true
	_set_state(State.IDLE)
	_animated_sprite.play("Idle")

## 攻撃ヒットボックスに敵が入ったときの処理
func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(ATTACK_DAMAGE)
		attack_landed.emit(body, ATTACK_DAMAGE)
		Log.info("Pawn: 敵にダメージ %d → %s" % [ATTACK_DAMAGE, body.name])

# ========== インタラクトエリア ==========

## InteractArea 内の最も近いインタラクト対象（リソースノードまたはNPC）を返す
func _get_nearest_interactable() -> Node2D:
	var nearest: Node2D = null
	var nearest_dist: float = INF
	for body: Node2D in _interact_area.get_overlapping_bodies():
		# リソースノード: 枯渇していなければ対象
		if body.is_in_group("resource_node"):
			if body.get("is_depleted") == true:
				continue
		# NPC: 常にインタラクト可能
		elif body.is_in_group("npc"):
			pass
		else:
			continue
		var dist: float = global_position.distance_squared_to(body.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = body
	return nearest

# ========== NPC会話 ==========

## NPC に話しかける — NPC の interact() メソッドを呼び出す
func _start_talk(npc: Node2D) -> void:
	if not npc.has_method("interact"):
		return
	npc.interact()
	Log.debug("Pawn: NPCに話しかけた → %s" % npc.name)

# ========== インベントリ ==========

## ドロップアイテムを回収してインベントリに加算する（DropItem から呼ばれる）
func collect_drop(type: ResourceDefinitions.ResourceType, amount: int) -> void:
	_add_resource(type, amount)
	Log.info("Pawn: ドロップ回収 %s x%d" % [ResourceDefinitions.get_type_name(type), amount])


## リソースをインベントリに追加する
func _add_resource(type: ResourceDefinitions.ResourceType, amount: int) -> void:
	_inventory[type] = _inventory.get(type, 0) + amount
	inventory_changed.emit(type, _inventory[type])

## 指定リソースの所持数を返す
func get_resource_amount(type: ResourceDefinitions.ResourceType) -> int:
	return _inventory.get(type, 0)

# ========== 戦闘状態管理 ==========

## 戦闘状態に入る — クールダウンをリセットし、未戦闘時はシグナルを発火する
func _enter_combat() -> void:
	_combat_cooldown = COMBAT_COOLDOWN
	if not _is_in_combat:
		_is_in_combat = true
		combat_state_changed.emit(true)
		Log.debug("Pawn: 戦闘状態に入った")


## 戦闘状態から出る — シグナルを発火する
func _exit_combat() -> void:
	_is_in_combat = false
	combat_state_changed.emit(false)
	Log.debug("Pawn: 戦闘状態から出た")


## 戦闘状態クールダウンを処理する — 時間経過で戦闘状態を解除する
func _process_combat_cooldown(delta: float) -> void:
	if not _is_in_combat:
		return
	_combat_cooldown -= delta
	if _combat_cooldown <= 0.0:
		_exit_combat()


# ========== ユーティリティ ==========

## 状態を変更する（同一状態への遷移はスキップ）
func _set_state(new_state: State) -> void:
	if _state != new_state:
		_state = new_state
