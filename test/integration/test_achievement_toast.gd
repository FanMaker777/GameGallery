## AchievementToast のセットアップとアニメーションをテストする
extends GutTest

# ---- 定数 ----
const TOAST_SCENE: PackedScene = preload(
	"res://root/scenes/game_scene/achievement_master/ui/toast/achievement_toast.tscn"
)

# ---- ヘルパー ----

## テスト用の AchievementDefinition を生成する
func _make_def(
	rank: AchievementDefinition.Rank,
	name_ja: String = "テスト実績",
	ap: int = 10,
) -> AchievementDefinition:
	var d := AchievementDefinition.new()
	d.id = &"test"
	d.name_ja = name_ja
	d.rank = rank
	d.ap = ap
	return d


## トーストインスタンスを生成してシーンツリーに追加する
func _create_toast() -> AchievementToast:
	var toast: AchievementToast = TOAST_SCENE.instantiate()
	add_child_autofree(toast)
	return toast


# ---- テスト: setup ----

func test_setup_bronze_rank() -> void:
	var toast := _create_toast()
	var def := _make_def(AchievementDefinition.Rank.BRONZE, "初めての一歩", 5)
	toast.setup(def)

	assert_eq(toast._rank_label.text, "[B]", "Bronze のランクラベルは [B]")
	assert_eq(
		toast._rank_label.get_theme_color("font_color"),
		AchievementToast.RANK_COLORS[AchievementDefinition.Rank.BRONZE],
		"Bronze のランク色が正しい",
	)
	assert_eq(toast._title_label.text, "初めての一歩", "実績名が正しい")
	assert_eq(toast._ap_label.text, "+5 AP", "AP表示が正しい")


func test_setup_silver_rank() -> void:
	var toast := _create_toast()
	var def := _make_def(AchievementDefinition.Rank.SILVER)
	toast.setup(def)

	assert_eq(toast._rank_label.text, "[S]", "Silver のランクラベルは [S]")


func test_setup_gold_rank() -> void:
	var toast := _create_toast()
	var def := _make_def(AchievementDefinition.Rank.GOLD)
	toast.setup(def)

	assert_eq(toast._rank_label.text, "[G]", "Gold のランクラベルは [G]")


# ---- テスト: play_animation ----

func test_play_animation_emits_toast_finished() -> void:
	var toast := _create_toast()
	var def := _make_def(AchievementDefinition.Rank.BRONZE)
	toast.setup(def)

	# toast_finished はアニメーション完了後に発火し、直後に queue_free() される
	# そのため assert_signal_emitted はオブジェクト解放後に使えない
	# コールバックでシグナル発火を記録する
	var signal_fired := [false]
	toast.toast_finished.connect(func() -> void: signal_fired[0] = true)

	toast.play_animation()

	# アニメーション完了まで待つ（スライドイン + 表示 + スライドアウト）
	var total_duration: float = (
		AchievementToast.SLIDE_DURATION
		+ AchievementToast.DISPLAY_DURATION
		+ AchievementToast.SLIDE_DURATION
		+ 0.1  # マージン
	)
	await wait_seconds(total_duration)

	assert_true(signal_fired[0], "アニメーション完了後に toast_finished が発火する")
