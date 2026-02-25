## 羊のリソースノード — 待機・移動・草食べを繰り返し、採取すると一定時間後に復活する
class_name SheepNode extends ResourceNode


## 羊の行動状態
enum SheepState {
	IDLE,       ## 待機
	MOVE,       ## 移動
	EAT_GRASS,  ## 草を食べる
}

## 移動速度（ピクセル/秒）
const _MOVE_SPEED: float = 15.0
## 初期位置からの最大移動距離（ピクセル）
const _MAX_WANDER_DISTANCE: float = 30.0

## 羊のアニメーションスプライト
@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

## 現在の行動状態
var _current_state: SheepState = SheepState.IDLE
## 行動タイマー（秒）
var _behavior_timer: float = 0.0
## 現在の行動の持続時間（秒）
var _behavior_duration: float = 0.0
## 移動方向（-1.0: 左, 1.0: 右）
var _move_direction: float = 1.0
## 初期位置（移動範囲の基準点）
var _origin_position: Vector2 = Vector2.ZERO


## 採取完了後、リソースを返してからノードを消滅させる
func harvest() -> Dictionary:
	var result: Dictionary = super.harvest()
	if not result.is_empty():
		queue_free()
	return result


## ノードキーを設定し、初期位置を記録して基底クラスの初期化を呼ぶ
func _ready() -> void:
	node_key = "sheep"
	_origin_position = position
	super._ready()


## 毎フレーム行動タイマーと移動を処理する
func _process(delta: float) -> void:
	# 基底クラスのリスポーンタイマーを処理
	super._process(delta)
	# 枯渇中は行動を停止
	if is_depleted:
		return
	# 行動タイマーを進める
	_behavior_timer += delta
	# 移動中は位置を更新
	if _current_state == SheepState.MOVE:
		_process_movement(delta)
	# 行動時間が終了したら次の行動に遷移
	if _behavior_timer >= _behavior_duration:
		_transition_to_next_state()


## 枯渇/復活状態に応じて外観と行動を切り替える
func _update_visual() -> void:
	if _animated_sprite == null:
		return
	if is_depleted:
		# 枯渇時はアイドル状態に固定
		_current_state = SheepState.IDLE
		_animated_sprite.play("Idle")
	else:
		# 復活時は草食べから行動サイクルを再開
		_start_behavior(SheepState.EAT_GRASS)


## 指定した行動を開始し、対応するアニメーションを再生する
func _start_behavior(state: SheepState) -> void:
	_current_state = state
	_behavior_timer = 0.0
	# 持続時間をランダムに決定
	_behavior_duration = _get_state_duration(state)
	# 対応するアニメーションを再生
	_animated_sprite.play(_get_animation_name(state))
	# 移動開始時はランダムな方向を決定
	if state == SheepState.MOVE:
		_choose_move_direction()


## 状態に対応するアニメーション名を返す
func _get_animation_name(state: SheepState) -> String:
	match state:
		SheepState.IDLE:
			return "Idle"
		SheepState.MOVE:
			return "Move"
		SheepState.EAT_GRASS:
			return "EatGrass"
	return "Idle"


## 状態に応じたランダムな持続時間（秒）を返す
func _get_state_duration(state: SheepState) -> float:
	match state:
		SheepState.IDLE:
			return randf_range(2.0, 4.0)
		SheepState.MOVE:
			return randf_range(1.5, 3.0)
		SheepState.EAT_GRASS:
			return randf_range(3.0, 6.0)
	return 3.0


## 現在と異なる行動をランダムに選んで遷移する
func _transition_to_next_state() -> void:
	# 全状態から現在の状態を除外してランダム選択
	var candidates := [SheepState.IDLE, SheepState.MOVE, SheepState.EAT_GRASS]
	candidates.erase(_current_state)
	_start_behavior(candidates.pick_random())


## 移動方向をランダムに決定し、スプライトの向きを合わせる
func _choose_move_direction() -> void:
	var offset: float = position.x - _origin_position.x
	if absf(offset) >= _MAX_WANDER_DISTANCE:
		# 範囲限界に達したら中心方向に戻る
		_move_direction = -signf(offset)
	else:
		# ランダムに左右を選択
		_move_direction = [-1.0, 1.0].pick_random()
	# スプライトの向きを移動方向に合わせる
	_animated_sprite.flip_h = _move_direction < 0


## 移動中の位置更新と範囲制限を処理する
func _process_movement(delta: float) -> void:
	# 移動方向に沿って位置を更新
	position.x += _move_direction * _MOVE_SPEED * delta
	# 初期位置からの距離を制限
	var offset: float = position.x - _origin_position.x
	if absf(offset) > _MAX_WANDER_DISTANCE:
		position.x = _origin_position.x + signf(offset) * _MAX_WANDER_DISTANCE
		# 範囲端に到達したら方向を反転
		_move_direction = -_move_direction
		_animated_sprite.flip_h = _move_direction < 0
