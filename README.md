# GameGallery

複数のミニゲームを1つのハブ（メインメニュー）から起動できる **Godot 4.5 製ゲームギャラリー**プロジェクト。

- **エンジン:** Godot 4.5.1 (Forward Plus)
- **バージョン:** 0.01
- **解像度:** 1280 x 720（canvas_items / expand）

---

## プロジェクト構成

```
GameGallery/
├── root/
│   ├── scenes/                 # シーン
│   │   ├── boot_splash_scene/  #   起動スプラッシュ
│   │   ├── main_menu_scene/    #   メインメニュー（ゲーム選択ハブ）
│   │   └── game_scene/         #   ミニゲーム群
│   ├── autoload/               # シングルトン（Autoload）
│   │   ├── game_manager/       #   GameManager
│   │   ├── audio_manager/      #   AudioManager
│   │   └── settings_repository/#   SettingsRepository
│   ├── scripts/                # 共有スクリプト
│   │   ├── beehave/            #   ビヘイビアツリーノード実装
│   │   └── const/              #   定数定義
│   └── assets/                 # 共有アセット
│       ├── audio/ogg/          #   オーディオ（OGG）
│       ├── fonts/rubik/        #   フォント（Rubik）
│       ├── image/              #   画像（スプラッシュ、ギャラリー）
│       └── TransitionKit/      #   遷移エフェクト（シェーダー/スクリプト）
├── addons/                     # プラグイン
├── test/                       # ユニットテスト（GUT）
├── tools/                      # 開発ツール（MCP等）
└── sandbox/                    # 実験用（level / sample）
```

---

## 収録ミニゲーム

### lucy_adventure — 2Dプラットフォーマー

プレイヤーキャラクターを操作してステージを攻略する横スクロールアクション。

- **操作:** 矢印キー / ゲームパッド移動、C / Space でジャンプ
- **要素:** 敵（Mob）、移動プラットフォーム、押せるブロック、感圧板、ドア、水場、ゴールフラグ
- **AI:** Beehave によるビヘイビアツリー駆動の敵行動（巡回・追跡・攻撃）
- **ステージ:** Mushroom World（L10, L11）
- **配置:** `res://root/scenes/game_scene/lucy_adventure/`

### introduce_godot — ビジュアルノベル

Dialogic 2.0 を使用した対話型ストーリー。キャラクター「Sophia」との会話を通じて進行する。

- **システム:** Dialogic 2.0 Alpha-19（キャラクター定義、タイムライン、ビジュアルノベルスタイル）
- **配置:** `res://root/scenes/game_scene/introduce_godot/`

### achievement_master — アチーブメントコレクション

キャラクターとマップを用いたバッジ／アチーブメント収集ゲーム。

- **要素:** キャラクター、敵、マップ
- **配置:** `res://root/scenes/game_scene/achievement_master/`

---

## Autoload（シングルトン）

| 名前 | 役割 |
|------|------|
| **GameManager** | 画面遷移（SceneNavigator）・オーバーレイUI管理（OverlayController）・ESC入力処理 |
| **AudioManager** | Master / BGM / SE の3バスの音量制御・ミュート・設定同期 |
| **SettingsRepository** | オーディオ／ビデオ設定の状態管理と永続化（`user://settings.cfg`） |
| **Log** | ロガー（Logger アドオン） |
| **Dialogic** | ダイアログシステム |
| **BeehaveGlobalMetrics** | ビヘイビアツリーメトリクス |
| **BeehaveGlobalDebugger** | ビヘイビアツリーデバッガー |

### 画面遷移フロー

```
1. GameManager.load_scene_with_transition(scene_path) を呼び出し
2. SceneNavigator がフェードアウト実行
3. シーン変更
4. scene_changed シグナルで切替完了を待機
5. フェードイン実行
```

---

## 使用アドオン

| アドオン | バージョン | 用途 |
|---------|-----------|------|
| **Beehave** | 2.9.2 | ビヘイビアツリー（敵AIロジック） |
| **Dialogic** | 2.0-Alpha-19 | ビジュアルノベル／ダイアログシステム |
| **GUT** | 9.5.0 | ユニットテストフレームワーク |
| **Logger** | 2.1.1 | ログ出力（複数ストリーム対応） |

---

## 共有スクリプト

### ビヘイビアツリーノード (`root/scripts/beehave/`)

**アクションリーフ:**
- `attack_player.gd` — 攻撃アクション
- `chase_player.gd` — プレイヤー追跡
- `move_to_patrol_point.gd` — 巡回移動
- `wait_at_patrol_point.gd` — 巡回待機

**条件リーフ:**
- `is_player_visible.gd` — プレイヤー検知判定

### 定数 (`root/scripts/const/`)

- `default_option.gd` — 設定デフォルト値（オーディオ / ビデオ）
- `path_consts.gd` — シーンパス・ファイルパス定数
- `beehave_blackbord_value.gd` — ビヘイビアツリー Blackboard キー定数

---

## 物理レイヤー

| レイヤー | 名前 |
|---------|------|
| 1 | Player |
| 2 | Enemy |
| 9 | Ground |

---

## テスト

- **フレームワーク:** GUT 9.5.0
- **配置:** `res://test/unit/`
- **命名規則:** `test_****.gd`

### テスト実行

```bash
# エディタのGUT UIから実行、またはCLI:
godot -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gdir=res://test/unit -ginclude_subdirs -gexit
```

---

## 開発ガイドライン

詳細は [AGENTS.md](AGENTS.md) を参照。

- **言語:** コメント・ドキュメント・コミットメッセージは日本語
- **命名:** 全て英語（変数/関数: `snake_case`、定数: `UPPER_SNAKE_CASE`、クラス: `PascalCase`）
- **型注釈:** 可能な限り付与
- **ログ:** `Log` シングルトンを使用（`print()` は使わない）
- **画面遷移:** 必ず GameManager 経由
- **最小差分:** 依頼範囲外の変更をしない
