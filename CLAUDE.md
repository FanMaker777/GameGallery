# CLAUDE.md — GameGallery（Godot 4.5.1）

本ドキュメントは、Claude Code が本リポジトリで作業する際の **規約・手順・品質基準** を定義する。
**会話・コードコメント・PR説明・コミットメッセージは必ず日本語** で行うこと。

---

## 0. 絶対ルール（最優先）

- **日本語運用:** 仕様説明、作業サマリ、コミット/PR説明、コードコメントは日本語。
- **最小差分:** 依頼範囲外の変更（ついでリファクタリング、不要な整形、無関係な命名変更）をしない。
- **既存方式を優先:** 画面遷移・状態管理は既存の Autoload（GameManager／遷移エフェクト）に従う。
- **必ず動作確認＋テスト:** 変更後は MCP サーバー経由で実際に Godot を実行して動作確認し、必要に応じて GUT テストを追加/更新する。
- **MCP サーバーを積極活用:** シーン作成・ノード追加・実行テスト・デバッグ出力確認など、MCP ツールで実行可能な操作は手動ファイル編集より MCP を優先する。

---

## 1. プロジェクト概要

- **エンジン:** Godot 4.5.1（GDScript）
- **収録形態:** 複数ミニゲームを1つのハブ（メインメニュー）から起動する「GameGallery」
- **プラットフォーム:** PC（キーボード/マウス）
- **Git ブランチ:** `main` を主軸

### 収録ゲーム

| ゲーム | パス | 概要 |
|--------|------|------|
| Achievement Master | `res://root/scenes/game_scene/achievement_master/` | Top-down アクション RPG（実績駆動） |
| Lucy Adventure | `res://root/scenes/game_scene/lucy_adventure/` | 2D プラットフォーマー |
| Introduce Godot | `res://root/scenes/game_scene/introduce_godot/` | Godot チュートリアル（Dialogic） |

---

## 2. 重要パス

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

## 3. Autoload（シングルトン）

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

> Autoload を増やす場合は「責務」を最小にし、この CLAUDE.md にも追記する。

---

## 4. アーキテクチャ方針

### 4.1 画面遷移（統一ルール）

画面遷移は原則 **GameManager 経由** で行い、遷移エフェクト（フェード等）を挟む。

```
1) フェードアウト開始 → 2) 完了待ち → 3) シーン変更 → 4) 切替完了待ち → 5) フェードイン
```

> `get_tree().change_scene_*` を直接呼ばず、GameManager の API を使う。

### 4.2 ミニゲーム追加ルール

- 配置: `res://root/scenes/game_scene/<game_id>/`
- 起動: `GameManager.start_game(scene_path)` 経由
- 戻り: 全ゲームに「メインメニューへ戻る」手段を必ず提供（`GameManager.load_main_scene()`）

### 4.3 入力マッピング

プロジェクトに定義済みのカスタムアクションを使用する：
`move_up` / `move_down` / `move_left` / `move_right` / `jump` / `ESC`

> `ui_left` 等のデフォルトアクションではなく、カスタムアクションを優先する。

### 4.4 物理レイヤー

| Layer | 名前 | 用途 |
|-------|------|------|
| 1 | Player | プレイヤーキャラクター |
| 2 | Enemy | エネミー |
| 9 | Ground | 地形・壁 |

---

## 5. MCP サーバーの活用（重要）

本プロジェクトには複数の MCP サーバーが設定されている。**積極的に活用すること。**

### 5.1 Godot MCP（`mcp__godot__*`）

シーン操作・プロジェクト実行に使用する。**ファイルを手動で .tscn 編集するより MCP を優先する。**

| ツール | 用途 | 使用タイミング |
|--------|------|----------------|
| `run_project` | シーンを実行して動作確認 | 実装完了後の検証時。`scene` パラメータで特定シーンを指定可能 |
| `get_debug_output` | 実行中のコンソール出力・エラー取得 | `run_project` 後にエラー・警告を確認 |
| `stop_project` | 実行中のプロジェクトを停止 | デバッグ完了時 |
| `create_scene` | 新規シーンファイル作成 | 新しいシーンが必要な時 |
| `add_node` | 既存シーンにノード追加 | シーンツリーの構築時 |
| `load_sprite` | Sprite2D にテクスチャ読込 | スプライト設定時 |
| `save_scene` | シーンの保存 | シーン変更後の永続化 |
| `get_project_info` | プロジェクト情報取得 | 構造把握時 |
| `get_uid` | ファイルの UID 取得 | リソース参照時 |
| `update_project_uids` | UID 参照の更新 | リソース追加/移動後 |
| `launch_editor` | Godot エディタ起動 | ユーザーの要望時 |

**プロジェクトパス:** `D:/MyWork/ゲーム開発/Godot/GDQuest/2d/l2dfz_0.51.2_win/projects/GameGallery`

### 5.2 実行テストの標準手順

```
1) mcp__godot__run_project でシーンを実行
2) mcp__godot__get_debug_output でエラー・ログを確認
3) 問題があればコードを修正して再実行
4) mcp__godot__stop_project で停止
```

### 5.3 その他の MCP サーバー

| サーバー | 用途 |
|----------|------|
| `gdscript` | GDScript 関連の補助 |
| `godot_docs` | Godot 公式ドキュメント参照 |
| `github` | GitHub 操作 |
| `context7` | ライブラリドキュメント参照 |

---

## 6. コーディング規約（GDScript）

### 6.1 命名

**最優先: 命名は全て英語のみで構成する**

| 対象 | スタイル | 例 |
|------|----------|-----|
| 変数/関数 | `snake_case` | `move_speed`, `get_player()` |
| 定数 | `UPPER_SNAKE_CASE` | `MAX_HP`, `IDLE_POSITION` |
| クラス名 | `PascalCase` | `ChasePlayer`, `RpgPlayer` |
| ファイル名 | `snake_case.gd` | `chase_player.gd` |
| ノード参照 | `@onready var xxx: Type = %Name` | `@onready var _sprite: AnimatedSprite2D = %AnimatedSprite` |

### 6.2 型注釈

- 可能な限り型注釈を付ける（Godot 4.x の静的チェックを活かす）
- 必要に応じて `class_name` を付与し、型推論を活用する
- null の可能性がある参照はガード節で守る

### 6.3 コメント

- **全ての処理には日本語で簡潔に処理概要をコメント**
- クラス・メソッド・変数には `##` で役割をコメントする
- 複雑な処理や意図が読みにくいコードには「なぜこの実装か」を追加する
- 類似処理が並ぶ場合はひとまとめのコメントにする

### 6.4 ログ

- `Log` オートロードを使用し、`print()` は使用しない
- 重要またはバグが発生しやすいメソッドには追跡用ログを出力する
- エラーは握りつぶさず、原因が追える情報を残す

### 6.5 コード品質

**常に「拡張性・保守性・可読性」を最優先して実装/改修すること。**

- **拡張性:** 新機能追加時に既存コードの変更範囲が最小で済む構造
- **保守性:** 表示文言や UI 構造変更に強い実装（文字列 match 依存を避ける）
- **可読性:** 意図がコードから読み取れる命名・関数分割・データ駆動

#### 責務分離

- **View（UI）:** イベント処理、表示更新のみ
- **Applier（適用）:** DisplayServer 等の副作用処理を集約
- **Store（保存/読込）:** 設定の永続化とデフォルト復元

#### スクリプト分割の判断基準

**内部クラスを使う場合:**
- そのファイル専用の小型 DTO / 状態マシンの State 群

**別ファイルに分割する場合:**
- 複数シーン/スクリプトから再利用したい
- Inspector で割り当てたい / Resource として保存したい
- 単体テスト対象として独立させたい
- ファイルが肥大化し、責務が 3 つ以上混在

---

## 7. Git 運用

- 基本ブランチ: `main`
- 開発フロー: `main` → ブランチ作成 → 実装 → テスト → 手動確認 → マージ
- コミットメッセージ: 日本語で簡潔に（1コミット1論点）
  - 例: `feat: ゲーム選択カードに新規ミニゲームを追加`
  - 例: `fix: メニュー復帰時の遷移不具合を修正`

---

## 8. テスト（GUT）

- 配置: `res://test/unit/` 配下、`test_*.gd` 形式
- **ロジック層**（状態管理/登録リスト/判定処理）を優先してテストする
- `res://test/unit/test_example.gd` を参考にテストメソッドを実装する
- 変更後は MCP で実行し、エラーがないことを確認する

---

## 9. 作業手順（標準フロー）

1. 依頼内容を「目的/変更点/影響範囲」で短く整理
2. 変更対象ファイルを列挙（`.gd` / `.tscn` / テスト）
3. 実装（最小差分、既存方式優先）
4. **MCP で Godot 実行** → デバッグ出力確認 → 問題修正
5. テスト追加/更新（必要時）
6. 変更サマリ作成

---

## 10. 変更サマリ（テンプレ）

```
- 目的:
- 対応内容:
- 変更ファイル:
- MCP 実行確認: （実行シーン、エラー有無）
- テスト結果:
- 補足/注意点:
```

---

## 11. Achievement Master 固有情報

Achievement Master は Top-down アクション RPG。詳細仕様は `AchievementMaster_ClaudeCode_Spec.md` を参照。

### 現在の実装状況

- **プレイヤー:** `res://root/scenes/game_scene/achievement_master/character/Warrior/warrior.tscn`
  - `RpgPlayer` (CharacterBody2D)、Layer 1 "Player"、`move_and_slide()` で移動
- **エネミー:** `res://root/scenes/game_scene/achievement_master/enemys/enemy.tscn`
  - `Enemy` (CharacterBody2D)、Layer 2 "Enemy"、Beehave ビヘイビアツリーで AI 制御
  - BT 構造: Selector → AttackSequence（探知→追跡→攻撃） / PatrolSequence（帰還→待機）
- **マップ:** `res://root/scenes/game_scene/achievement_master/world/map/village/village.tscn`

### Beehave ビヘイビアツリー

リーフスクリプトは `res://root/scripts/beehave/` 配下に配置:
- `action_leaf/chase_player.gd` — プレイヤー追跡
- `action_leaf/attack_player.gd` — プレイヤー攻撃
- `action_leaf/move_to_patrol_point.gd` — パトロール地点への移動
- `action_leaf/wait_at_patrol_point.gd` — パトロール地点での待機
- `condition_leaf/is_player_visible.gd` — プレイヤー探知判定

Blackboard キー定数: `res://root/scripts/const/beehave_blackbord_value.gd`
