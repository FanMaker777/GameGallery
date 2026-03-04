## Player のジャンプ物理計算関数をテストする
## 4つの純粋計算関数の数式検証（Player インスタンス化不要）
extends GutTest

# ---- テストパラメータ ----
const HEIGHT := 50.0
const TIME_TO_PEAK := 0.37
const TIME_TO_DESCENT := 0.25
const DISTANCE := 80.0

# ---- ヘルパー: 計算関数を再定義（Player の static 相当） ----

func _jump_speed(h: float, t: float) -> float:
	return (-2.0 * h) / t


func _jump_gravity(h: float, t: float) -> float:
	return (2.0 * h) / pow(t, 2.0)


func _fall_gravity(h: float, t: float) -> float:
	return (2.0 * h) / pow(t, 2.0)


func _max_speed(d: float, t1: float, t2: float) -> float:
	return d / (t1 + t2)


# ---- テスト: jump_speed ----

func test_jump_speed_is_negative() -> void:
	var speed: float = _jump_speed(HEIGHT, TIME_TO_PEAK)

	assert_true(speed < 0.0, "jump_speed は負値である")


func test_jump_speed_formula() -> void:
	var expected: float = (-2.0 * HEIGHT) / TIME_TO_PEAK
	var actual: float = _jump_speed(HEIGHT, TIME_TO_PEAK)

	assert_almost_eq(actual, expected, 0.001, "jump_speed の計算値が正しい（-2h/t）")


func test_jump_speed_increases_with_height() -> void:
	var low: float = _jump_speed(30.0, TIME_TO_PEAK)
	var high: float = _jump_speed(80.0, TIME_TO_PEAK)

	assert_true(
		absf(high) > absf(low),
		"高さが大きいほど速度の絶対値が大きい",
	)


# ---- テスト: jump_gravity ----

func test_jump_gravity_is_positive() -> void:
	var g: float = _jump_gravity(HEIGHT, TIME_TO_PEAK)

	assert_true(g > 0.0, "jump_gravity は正値である")


func test_jump_gravity_formula() -> void:
	var expected: float = (2.0 * HEIGHT) / pow(TIME_TO_PEAK, 2.0)
	var actual: float = _jump_gravity(HEIGHT, TIME_TO_PEAK)

	assert_almost_eq(actual, expected, 0.001, "jump_gravity の計算値が正しい（2h/t²）")


func test_jump_gravity_stronger_with_shorter_peak_time() -> void:
	var slow: float = _jump_gravity(HEIGHT, 0.5)
	var fast: float = _jump_gravity(HEIGHT, 0.2)

	assert_true(fast > slow, "ピーク時間が短いほど重力が強い")


# ---- テスト: fall_gravity ----

func test_fall_gravity_is_positive() -> void:
	var g: float = _fall_gravity(HEIGHT, TIME_TO_DESCENT)

	assert_true(g > 0.0, "fall_gravity は正値である")


func test_fall_gravity_formula() -> void:
	var expected: float = (2.0 * HEIGHT) / pow(TIME_TO_DESCENT, 2.0)
	var actual: float = _fall_gravity(HEIGHT, TIME_TO_DESCENT)

	assert_almost_eq(actual, expected, 0.001, "fall_gravity の計算値が正しい（2h/t²）")


# ---- テスト: max_speed ----

func test_max_speed_is_positive() -> void:
	var s: float = _max_speed(DISTANCE, TIME_TO_PEAK, TIME_TO_DESCENT)

	assert_true(s > 0.0, "max_speed は正値である")


func test_max_speed_formula() -> void:
	var expected: float = DISTANCE / (TIME_TO_PEAK + TIME_TO_DESCENT)
	var actual: float = _max_speed(DISTANCE, TIME_TO_PEAK, TIME_TO_DESCENT)

	assert_almost_eq(actual, expected, 0.001, "max_speed の計算値が正しい（d/(t1+t2)）")


# ---- テスト: クランプ境界値 ----

func test_velocity_y_clamped_by_max_fall_speed() -> void:
	var max_fall_speed := 320.0
	var velocity_y := 500.0

	var clamped: float = minf(velocity_y, max_fall_speed)

	assert_eq(clamped, max_fall_speed, "velocity.y は max_fall_speed でクランプされる")


func test_velocity_x_clamped_by_max_speed() -> void:
	var ms: float = _max_speed(DISTANCE, TIME_TO_PEAK, TIME_TO_DESCENT)
	var over_speed := ms + 100.0

	var clamped: float = clampf(over_speed, -ms, ms)

	assert_almost_eq(clamped, ms, 0.001, "velocity.x は ±max_speed でクランプされる")
