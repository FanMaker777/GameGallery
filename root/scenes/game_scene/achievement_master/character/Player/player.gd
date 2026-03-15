## プレイヤーが操作するキャラクター
## 移動・採取・攻撃・被ダメージの行動を状態で管理する
class_name AmPlayer extends CharacterBody2D

# ---- 基礎定数 ----
## 基礎移動速度（ピクセル/秒）
const BASE_SPEED: float = 200.0
## 基礎攻撃力
const BASE_ATTACK_DAMAGE: int = 10
## 基礎最大HP
const BASE_MAX_HP: int = 100
## 被ダメージ後の無敵時間（秒）
const INVINCIBLE_DURATION: float = 1.0
## 戦闘状態の持続時間（最後の戦闘行動からの秒数）
const COMBAT_COOLDOWN: float = 5.0
## 無敵中のスプライト点滅間隔（秒）
const _BLINK_INTERVAL: float = 0.1
## 死亡からリスポーンまでの待機時間（秒）
const RESPAWN_DELAY: float = 2.0
## 基礎スタミナ最大値
const BASE_MAX_STAMINA: float = 100.0
## 基礎スタミナ回復速度（/秒）
const BASE_STAMINA_RECOVERY_RATE: float = 20.0

# ---- ダッシュ・スタミナ設定 ----
## ダッシュ時の移動速度
@export var dash_speed: float = 350.0
## スタミナ最大値
@export var max_stamina: float = BASE_MAX_STAMINA
## ダッシュ中のスタミナ消費量/秒
@export var stamina_drain_rate: float = 30.0
## スタミナ回復量/秒
@export var stamina_recovery_rate: float = BASE_STAMINA_RECOVERY_RATE

# ---- 状態 ----
## プレイヤーの行動状態
enum State { IDLE, MOVE, GATHER, ATTACK, DEAD }
## 現在の行動状態
var _state: State = State.IDLE

# ---- HP関連 ----
## 現在HP
var hp: int = BASE_MAX_HP
## 無敵状態フラグ（被ダメージ後の一時無敵）
var _is_invincible: bool = false
## 無敵タイマー（残り秒数）
var _invincible_timer: float = 0.0
## 点滅用タイマー（スプライトの表示/非表示切り替え用）
var _blink_timer: float = 0.0

# ---- スタミナ ----
## 現在スタミナ
var stamina: float = 100.0
## ダッシュ中フラグ
var _is_dashing: bool = false

# ---- 戦闘状態 ----
## 戦闘中フラグ
var _is_in_combat: bool = false
## 戦闘状態クールダウン残り時間
var _combat_cooldown: float = 0.0

# ---- シグナル ----
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
## スタミナが変化したときに発火する（HUD連携用）
signal stamina_changed(current_stamina: float, max_stamina: float)

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
## 採取プログレスバー
@onready var _gather_progress_bar: ProgressBar = %GatherProgressBar
## 採取コンポーネント
@onready var _gather: AmGatherComponent = $GatherComponent
## 攻撃コンポーネント
@onready var _attack: AmAttackComponent = $AttackComponent

# ========== ライフサイクル ==========

## 初期化 — グループ登録、ヒットボックス無効化、シグナル接続
func _ready() -> void:
	add_to_group("player")
	# 攻撃コンポーネントを初期化する
	_attack.initialize(_animated_sprite, _attack_hitbox, _attack_hitbox_shape)
	_attack.attack_finished.connect(_on_attack_finished)
	_attack.attack_hit.connect(_on_attack_hit)
	# 採取コンポーネントを初期化する
	_gather.initialize(_animated_sprite, _gather_progress_bar)
	_gather.gather_finished.connect(_on_gather_finished)
	_gather.gather_cancelled.connect(_on_gather_ended)
	# ポップアップ初期非表示
	_interact_label.visible = false
	# HP初期値を通知（HUD初期化用）
	hp = AmPlayerStatCalculator.get_effective_max_hp(_get_equip_cache(), _get_effect_cache())
	health_changed.emit(hp, hp)
	# スタミナ初期値を通知（HUD初期化用）
	stamina = AmPlayerStatCalculator.get_effective_max_stamina(_get_equip_cache(), _get_effect_cache())
	stamina_changed.emit(stamina, stamina)
	# 実績マネージャーにプレイヤーを登録する
	AchievementManager.register_player(self)
	# InventoryManager の消耗品使用シグナルを接続する
	InventoryManager.item_used.connect(_on_item_used)
	InventoryManager.equipment_changed.connect(_on_equipment_changed)
	Log.info("Player: 初期化完了 (HP=%d/%d)" % [hp, hp])


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
			_process_stamina(delta)
			# 最寄りのインタラクト対象に応じてプロンプト表示を切り替え
			var nearest: Node2D = _get_nearest_interactable()
			if nearest != null:
				_interact_label.visible = true
				_interact_label.text = "E 話す" if nearest.is_in_group("npc") else "E 採取"
			else:
				_interact_label.visible = false
		State.GATHER:
			_gather.process_tick(delta)
			_interact_label.visible = false
		State.ATTACK:
			_attack.process_tick(delta)
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
	# 採取中なら中断する
	if _state == State.GATHER:
		_gather.cancel()
	# HP を減算（0未満にはしない）
	hp = maxi(hp - amount, 0)
	AudioManager.play_se(AudioConsts.SE_PLAYER_DAMAGE)
	_enter_combat()
	var effective_max_hp: int = AmPlayerStatCalculator.get_effective_max_hp(_get_equip_cache(), _get_effect_cache())
	health_changed.emit(hp, effective_max_hp)
	Log.info("Player: ダメージ %d を受けた (残HP: %d/%d)" % [amount, hp, effective_max_hp])
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
	Log.info("Player: 死亡")
	# 一定時間後に村へリスポーンする
	_start_respawn_timer()


## リスポーンタイマーを開始する
func _start_respawn_timer() -> void:
	var timer: SceneTreeTimer = get_tree().create_timer(RESPAWN_DELAY)
	timer.timeout.connect(_respawn)


## 村シーンの中央にリスポーンする
func _respawn() -> void:
	Log.info("Player: 村にリスポーン")
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
		# ダッシュ判定: Shift＋移動中＋スタミナ残あり
		if Input.is_action_pressed("dash") and stamina > 0.0:
			_is_dashing = true
			velocity = dir * dash_speed
		else:
			_is_dashing = false
			velocity = dir * AmPlayerStatCalculator.get_effective_speed(_get_equip_cache(), _get_effect_cache())
		_set_state(State.MOVE)
		_animated_sprite.play("Run")
		# 左右フリップ
		if dir.x != 0.0:
			_animated_sprite.flip_h = dir.x < 0.0
	else:
		_is_dashing = false
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
			elif _gather.start_gather(nearest):
				velocity = Vector2.ZERO
				_set_state(State.GATHER)
	elif Input.is_action_just_pressed("attack"):
		velocity = Vector2.ZERO
		_set_state(State.ATTACK)
		_enter_combat()
		attack_started.emit()
		_attack.start_attack()

# ========== 採取コンポーネントハンドラ ==========

## 採取完了時の処理 — インベントリに追加して IDLE に復帰する
func _on_gather_finished(result: Dictionary) -> void:
	if not result.is_empty():
		var type: ResourceDefinitions.ResourceType = result.get("type")
		var amount: int = result.get("amount", 0)
		var item_id: StringName = ResourceDefinitions.to_item_id(type)
		InventoryManager.add_item(item_id, amount)
		Log.info("Player: 採取完了 %s x%d" % [
			ResourceDefinitions.get_type_name(type), amount
		])
	_on_gather_ended()


## 採取終了時の共通処理（完了/中断）— IDLE に復帰する
func _on_gather_ended() -> void:
	_set_state(State.IDLE)
	_animated_sprite.play("Idle")


# ========== 攻撃コンポーネントハンドラ ==========

## 攻撃完了時の処理 — IDLE に復帰する
func _on_attack_finished() -> void:
	_set_state(State.IDLE)
	_animated_sprite.play("Idle")


## 攻撃命中時の処理 — attack_landed シグナルを中継する
func _on_attack_hit(target: Node2D, damage: int) -> void:
	attack_landed.emit(target, damage)


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
	Log.debug("Player: NPCに話しかけた → %s" % npc.name)

# ========== インベントリ ==========

## 消耗品が使用されたときの処理 — 効果種別に応じてHP/スタミナを回復する
func _on_item_used(_id: StringName, def: ItemDefinition) -> void:
	var definition: ConsumableDefinition = def as ConsumableDefinition
	if definition == null:
		return
	match definition.effect_type:
		ConsumableDefinition.EffectType.HP_RECOVER:
			# HPを回復する（最大HPを超えない）
			var max_hp: int = AmPlayerStatCalculator.get_effective_max_hp(_get_equip_cache(), _get_effect_cache())
			hp = mini(hp + int(definition.effect_value), max_hp)
			health_changed.emit(hp, max_hp)
			Log.info("Player: HP回復 +%d (現在HP=%d/%d)" % [
				int(definition.effect_value), hp, max_hp
			])
		ConsumableDefinition.EffectType.STAMINA_RECOVER:
			# スタミナを回復する（最大値を超えない）
			var max_stam: float = AmPlayerStatCalculator.get_effective_max_stamina(_get_equip_cache(), _get_effect_cache())
			stamina = minf(stamina + definition.effect_value, max_stam)
			stamina_changed.emit(stamina, max_stam)
			Log.info("Player: スタミナ回復 +%.0f (現在=%.0f/%.0f)" % [
				definition.effect_value, stamina, max_stam
			])


## 装備変更時にHP・スタミナの最大値を再計算し、HUDに通知する
func _on_equipment_changed(_slot: int) -> void:
	var new_max_hp: int = AmPlayerStatCalculator.get_effective_max_hp(
		_get_equip_cache(), _get_effect_cache(),
	)
	hp = mini(hp, new_max_hp)
	health_changed.emit(hp, new_max_hp)

	var new_max_stamina: float = AmPlayerStatCalculator.get_effective_max_stamina(
		_get_equip_cache(), _get_effect_cache(),
	)
	stamina = minf(stamina, new_max_stamina)
	stamina_changed.emit(stamina, new_max_stamina)


## ドロップアイテムを回収して InventoryManager に追加する（DropItem から呼ばれる）
func collect_drop(type: ResourceDefinitions.ResourceType, amount: int) -> void:
	var item_id: StringName = ResourceDefinitions.to_item_id(type)
	InventoryManager.add_item(item_id, amount)
	Log.info("Player: ドロップ回収 %s x%d" % [ResourceDefinitions.get_type_name(type), amount])

# ========== スタミナ処理 ==========

## スタミナの消費・回復を処理する — ダッシュ中は消費、dashキー未押下かつ非攻撃時は回復
func _process_stamina(delta: float) -> void:
	var prev_stamina: float = stamina
	var effective_max: float = AmPlayerStatCalculator.get_effective_max_stamina(_get_equip_cache(), _get_effect_cache())
	var effective_recovery: float = AmPlayerStatCalculator.get_effective_stamina_recovery(_get_effect_cache())
	if _is_dashing:
		stamina = maxf(stamina - stamina_drain_rate * delta, 0.0)
	# dashキー押下中は回復をブロックし、スタミナ0時の振動ループを防止する
	elif not Input.is_action_pressed("dash") and (not _is_in_combat or _state != State.ATTACK):
		stamina = minf(stamina + effective_recovery * delta, effective_max)
	# 変化があった場合のみシグナルを発火する
	if stamina != prev_stamina:
		stamina_changed.emit(stamina, effective_max)


# ========== 戦闘状態管理 ==========

## 戦闘状態に入る — クールダウンをリセットし、未戦闘時はシグナルを発火する
func _enter_combat() -> void:
	_combat_cooldown = COMBAT_COOLDOWN
	if not _is_in_combat:
		_is_in_combat = true
		combat_state_changed.emit(true)
		Log.debug("Player: 戦闘状態に入った")


## 戦闘状態から出る — シグナルを発火する
func _exit_combat() -> void:
	_is_in_combat = false
	combat_state_changed.emit(false)
	Log.debug("Player: 戦闘状態から出た")


## 戦闘状態クールダウンを処理する — 時間経過で戦闘状態を解除する
func _process_combat_cooldown(delta: float) -> void:
	if not _is_in_combat:
		return
	_combat_cooldown -= delta
	if _combat_cooldown <= 0.0:
		_exit_combat()


# ========== スキル効果反映 ==========

## スキル効果キャッシュを取得する
func _get_effect_cache() -> SkillEffectCache:
	return SkillManager.get_effect_cache()


## 装備ステータスキャッシュを取得する
func _get_equip_cache() -> EquipmentStatCache:
	return InventoryManager.get_equip_cache()


# ========== ユーティリティ ==========

## 状態を変更する（同一状態への遷移はスキップ）
func _set_state(new_state: State) -> void:
	if _state != new_state:
		_state = new_state
