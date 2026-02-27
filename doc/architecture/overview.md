# プロジェクト概要

- **エンジン:** Godot 4.5.1（GDScript）
- **収録形態:** 複数ミニゲームを1つのハブ（メインメニュー）から起動する「GameGallery」
- **プラットフォーム:** PC（キーボード/マウス）
- **Git ブランチ:** `main` を主軸

## 収録ゲーム

| ゲーム | パス | 概要 |
|--------|------|------|
| Achievement Master | `res://root/scenes/game_scene/achievement_master/` | Top-down アクション RPG（実績駆動） |
| Lucy Adventure | `res://root/scenes/game_scene/lucy_adventure/` | 2D プラットフォーマー |
| Introduce Godot | `res://root/scenes/game_scene/introduce_godot/` | Godot チュートリアル（Dialogic） |

---

## 重要パス

```
res://root/
├── assets/             # 共通アセット（audio/fonts/image/TransitionKit）
├── autoload/           # Autoload シングルトン群
│   ├── game_manager/   # GameManager, SceneNavigator, OverlayController
│   ├── audio_manager/  # AudioManager
│   └── settings_repository/  # SettingsRepository
├── scenes/
│   ├── boot_splash_scene/    # 起動シーン（メインシーン）
│   ├── main_menu_scene/      # ゲーム選択メニュー
│   └── game_scene/           # 各ミニゲーム
└── scripts/
    ├── beehave/              # Beehave ビヘイビアツリーのリーフ
    │   ├── action_leaf/
    │   └── condition_leaf/
    └── const/                # 定数定義

res://test/unit/              # GUT ユニットテスト（test_*.gd）
res://addons/                 # プラグイン（beehave, dialogic, gut, logger）
```

---

## Autoload（シングルトン）

| 名前 | パス | 責務 |
|------|------|------|
| **GameManager** | `res://root/autoload/game_manager/game_manager.tscn` | 画面遷移・ゲーム状態管理の中心 |
| **SceneNavigator** | 同上配下 | 画面遷移の処理を集約 |
| **OverlayController** | 同上配下 | ポーズスクリーン等のオーバーレイ UI 操作 |
| **AudioManager** | `res://root/autoload/audio_manager/audio_manager.tscn` | オーディオ操作と設定 |
| **SettingsRepository** | `res://root/autoload/settings_repository/settings_repository.tscn` | オプション設定の永続化 |
| **Log** | `res://addons/logger/logger.gd` | ロガー（`print()` は使わない） |
| **Dialogic** | `res://addons/dialogic/Core/DialogicGameHandler.gd` | 会話システム |
| **BeehaveGlobalMetrics** | `res://addons/beehave/metrics/beehave_global_metrics.gd` | BT メトリクス |
| **BeehaveGlobalDebugger** | `res://addons/beehave/debug/global_debugger.gd` | BT デバッガー |

> Autoload を増やす場合は「責務」を最小にし、CLAUDE.md にも追記する。

---

## アーキテクチャ方針

### 画面遷移（統一ルール）

画面遷移は原則 **GameManager 経由** で行い、遷移エフェクト（フェード等）を挟む。

```
1) フェードアウト開始 → 2) 完了待ち → 3) シーン変更 → 4) 切替完了待ち → 5) フェードイン
```

> `get_tree().change_scene_*` を直接呼ばず、GameManager の API を使う。

### ミニゲーム追加ルール

- 配置: `res://root/scenes/game_scene/<game_id>/`
- 起動: `GameManager.start_game(scene_path)` 経由
- 戻り: 全ゲームに「メインメニューへ戻る」手段を必ず提供（`GameManager.load_main_scene()`）

### 入力マッピング

プロジェクトに定義済みのカスタムアクションを使用する：
`move_up` / `move_down` / `move_left` / `move_right` / `jump` / `ESC`

> `ui_left` 等のデフォルトアクションではなく、カスタムアクションを優先する。

### 物理レイヤー

| Layer | 名前 | 用途 |
|-------|------|------|
| 1 | Player | プレイヤーキャラクター |
| 2 | Enemy | エネミー |
| 3 | ResourceNode | 採取可能リソース |
| 4 | NPC | 会話可能な NPC |
| 9 | Ground | 地形・壁 |
