# Achievement Master — Claude Code 用インプット設計書（Godot 4.5.1 / プロトタイプ）
> 目的：Claude Code に「Achievement Master」のプロトタイプ開発を自律的に進めさせるための、初回投入用の指示（仕様＋実装方針）をまとめたもの。  
> **可読性と実装可能性を優先**。不明点は「仮仕様」として明記し、後で差し替えやすくする。

---

## 0. 実行環境・前提
- ゲームエンジン：**Godot 4.5.1**
- プラットフォーム：PC（キーボード/マウス）を優先。
- 2D：Top-down（見下ろし）アクションRPG
- 言語：GDScript
- 単体テスト：**GUT** を導入（`res://test/unit/` 配下に `test_*.gd`）
- Git：`main` を主軸。作業はブランチ切って実装→テスト→マージ
- コメント：**日本語で簡潔に**（主要メソッド・意図が伝わる程度）

---

## 1. プロトタイプのゴール（最重要）
### 1.1 成功条件（UX観点）
- **あらゆる行動で実績が解除**される体験が、テンポ良く気持ちいい
- 実績解除 → **AP獲得** → 報酬ツリー解放（強化/QoL） → 次の目標が自然に決まる
- 実績通知が「気持ちいい」が「邪魔にならない」
  - 戦闘中は通知を抑制（Bronzeまとめ表示 / Silver・Goldのみ個別）

### 1.2 プレイ可能な最小範囲
- **村（農業・会話・クエスト受注）**
- **草原（雑魚 + 中ボス）**
- 実績：**50個**（ログ系25 / 目標系15 / チャレンジ系10）
- 報酬ツリー：グローバル/戦闘/農業クラフト/探索交流 の4カテゴリ（合計 ~25ノード）

---

## 2. コアコンセプトとゲームループ
### 2.1 コアループ
1) 行動（戦闘/農業/探索/交流）  
2) 実績解除  
3) AP（Achievement Point）獲得  
4) 報酬ツリー解放（強くなる・快適になる）  
5) より高難度実績に挑戦  
→ ①〜⑤をループ

### 2.2 リスクと対策（仕様に組み込む）
- 実績が多すぎて価値が薄れる  
  → 実績ランク（B/S/G）と解除頻度カーブ（序盤頻繁→中盤目的→終盤挑戦）
- 作業化・悪用（連打/放置）  
  → 実戦条件、同一NPC連打無効、多様性ボーナス（別カテゴリ連続でAPボーナス）
- 成長インフレ  
  → 縦成長だけでなく QoL/横成長を混ぜる（ミニマップ、ピン留め、回収補助など）

---

## 3. 画面・UX仕様（必須）
### 3.1 ゲーム画面（HUD / オーバーレイ）
#### 必須要素（推奨配置）
- 左上：HPバー / スタミナバー / 所持金（任意）
- 右上：ミニマップ（任意だが推奨）
- 右側：**ピン留め実績進捗（最大3件）**(設定で表示/非表示を切り替え可能)
- 左下：インタラクトプロンプト（例：E: 話す / 収穫）
- 右下：クイックスロット（回復/道具）
- 中央下：**実績解除トースト通知**（短く・自動で消える）

#### HUD状態
- NORMAL：通常表示
- COMBAT：Bronze通知はまとめ、Silver/Goldのみ個別
- DIALOG：戦闘系UIは薄く/非表示（仮）
- MENU：HUD非表示（ポーズメニュー優先）

### 3.2 メニュー画面（Pause / 4タブ）
- タブ：**装備 / ステータス / スキル / 実績**
- 共通構成：上部タブ、左リスト、右詳細、下部操作ガイド

#### 実績タブ（最重要）
- フィルタ：カテゴリ（戦闘/農業/探索/交流/システム）、未達成/達成済、ランク
- 詳細：条件、進捗、AP報酬、ヒント（任意）
- **ピン留め（追跡）**：HUDに進捗を表示
- おすすめ（後回し可）：達成が近い3件を提案（カテゴリ分散）

---

## 4. システム仕様（実装の核）
### 4.1 実績・AP・報酬ツリー
- AP（Achievement Point）：実績解除で獲得、報酬ツリー解放に使用
- 実績ランク：Bronze / Silver / Gold
  - B：AP 1〜2
  - S：AP 3〜4
  - G：AP 6〜10
- 報酬ツリー：ノードをAPで解放し、プレイヤーに永続効果を付与
- リスペック：プロトタイプでは **未実装でもOK**（後で追加）

### 4.2 データ駆動（強く推奨）
- 実績定義：JSON か Resource（`.tres`）で管理（**差し替えやすさ重視**）
- 報酬ツリー定義：同様にデータで管理
- セーブ：PlayerStats / UnlockedAchievements / EarnedAP / UnlockedRewards / PinnedAchievements を保存

### 4.3 進捗管理のルール（最低限）
- 同一NPC連打はカウントしない（同一会話を短時間で繰り返しても増えない）
- 実戦条件：戦闘カテゴリの一部は敵対状態でのみカウント
- 多様性ボーナス（任意）：別カテゴリ行動を連続するとAP+10%（最大+30%）

---

## 5. 実績リスト（50個）— プロトタイプ版（要実装）
> 実績はデータ定義で作ること。コードにベタ書きしない。

### 5.1 行動ログ系（25）
- 移動する / 攻撃する / 敵1体撃破 / 回復使用 / 採取 / クラフト / NPC会話 / クエスト受注 / 納品完了 / 収穫 …等
- 目標：序盤10分で **8〜12個**解除されるペース

### 5.2 目標系（15）
- 討伐クエスト3件 / 敵30体 / 宝箱5個 / 採取20回 / 収穫10回 / クラフト10回 / 会話20回 / クエスト10件 / 中ボス撃破 …等

### 5.3 チャレンジ系（10）
- ノーダメ連戦 / 回避連続 / パリィ成功 / 縛り装備で中ボス / 30秒討伐 / 回復禁止フロア突破 / 多カテゴリ同日達成 …等

※正確な一覧は別途 `achievements.json` に定義して作成すること（ここでは設計指針）。

---

## 6. 報酬ツリー（例）— プロトタイプ版
> こちらもデータ定義で作成。

### 6.1 グローバル（QoL）
- 通知フィルタ、ピン留め枠+1、おすすめ表示、多様性ボーナス、（任意）リスペック

### 6.2 戦闘
- HP+10%、攻撃+5%、回避無敵+、パリィ解放、スタミナ回復+、ポーション即時スロット、自動回収、敗北復帰短縮

### 6.3 農業/クラフト
- 種上限、じょうろ範囲、成長+、収穫ボーナス、料理、納品箱、アクション短縮、列植え

### 6.4 探索/交流
- 移動速度、ミニマップ、目的地ピン、ファストトラベル、宝箱レーダー、店割引、会話スキップ+要約

---

## 7. Godot 実装アーキテクチャ（確認の上、変更可能）
### 7.1 シーン（最小）
- `scenes/world/map/village.tscn`（村）
- `scenes/world/map/grassland.tscn`（草原）
- `scenes/ui/hud.tscn`（HUD）
- `scenes/ui/pause_menu.tscn`（メニュー：4タブ）
- `scenes/player/player.tscn`（プレイヤー）
- `scenes/enemies/enemy.tscn`（雑魚例）
- `scenes/enemies/mid_boss.tscn`（中ボス）

※パスはプロジェクトに合わせて調整。Claude Code は **一貫した規則**で作ること。

### 7.2 Autoload（シングルトン）
- `GameState`：戦闘状態、ポーズ状態、現在シーン等
- `SaveManager`：セーブ/ロード（JSON推奨）
- `AchievementManager`：実績進捗、解除判定、通知イベント
- `RewardManager`：報酬ツリー解放と効果適用
- （任意）`AudioManager`

### 7.3 入力（InputMap）
- `move_up/down/left/right`
- `attack`
- `dash`
- `interact`
- `open_menu`
- `quickslot_1/2/3`

---

## 8. HUDワイヤーフレーム（Godot実装前提）
> HUDのノードは CanvasLayer + 安全域 MarginContainer を基本にする。

推奨ツリー（概要）：
- `CanvasLayer(HUD)`
  - `MarginContainer(RootSafeArea)`
    - `TopLeft/PlayerStatusPanel`：HP/スタミナ/所持金
    - `TopRight/MiniMap`：ミニマップ
    - `TopRight/PinnedAchievementPanel`：最大3件
    - `BottomLeft/InteractionPrompt`：インタラクト表示
    - `BottomRight/QuickSlotPanel`：道具スロット
    - `CenterOverlay/ToastContainer`：実績通知キュー

実績通知（Toast）の仕様：
- 表示時間：2秒（仮）
- 戦闘中：Bはまとめ、S/Gは即表示
- ログ：解除履歴は Achievement メニューで確認可能

---

## 9. セーブデータ仕様（プロトタイプ）
### 9.1 保存対象（最低限）
- Player：HP/最大HP、攻撃、防御、所持金、所持アイテム（簡易でOK）
- 実績：解除済みID、進捗値（カウンタ系）
- AP：所持AP、累計AP（任意）
- 報酬：解放済みノードID
- ピン留め：ピンID配列（最大3）

### 9.2 フォーマット
- JSON（`user://save.json`）推奨

---

## 10. テスト（GUT）— 最低限の対象
- `AchievementManager`
  - 進捗加算が正しい
  - 条件達成で解除される
  - 二重解除されない
  - ピン留めが最大数を超えない
- `RewardManager`
  - ノード解放で効果が反映される
  - AP消費が正しい

---

## 11. 開発タスク順（Claude Code はこの順で実装）
1) プロジェクト初期化（シーン/フォルダ/入力/Autoload）
2) Player 移動/攻撃/回避（最小）
3) 村・ダンジョンの最小ループ（出入り、敵1種）
4) `AchievementManager`（データ定義 + 解除イベント）
5) HUD（HP/スタミナ/プロンプト/トースト/ピン進捗）
6) PauseMenu（4タブ）— 実績タブ優先
7) `RewardManager`（報酬解放と効果適用）
8) セーブ/ロード
9) バランス調整（解除頻度・通知・APコスト）
10) GUTテスト追加/整備

---

## 12. 受け入れ条件（Definition of Done）
- 起動してすぐ村で行動できる
- ダンジョンに入って雑魚を倒せる
- 行動に応じて実績が解除され、APが増える
- メニュー実績タブで「未達成」「カテゴリ」「ピン留め」が使える
- ピン留め進捗がHUDに表示される
- 報酬ツリーで解放すると、プレイヤーが強くなる/快適になる
- セーブ→再起動→ロードで状態が復元される
- 実績解除通知が邪魔になりすぎない（戦闘中抑制が効く）

---

## 13. Claude Code への作業指示テンプレ（そのまま貼る用）
以下を Claude Code に貼り付けて作業開始させる：

- この設計書に従って Godot 4.5.1 でプロトタイプを実装すること
- まずフォルダ/シーン/Autoload/InputMap を構築し、次に Player の最小アクション、その後 AchievementManager とHUD、最後にメニューと報酬、セーブを実装すること
- 実績・報酬は **データ駆動**（JSON or Resource）で作ること
- 重要ロジックは GUT でユニットテストを用意すること
- 主要メソッドには日本語で短いコメントを入れること
- 進捗が分かるよう、コミット単位を小さくし、変更点を要約すること

---

## 付録：不足情報（仮置きして進めて良い）
- 正確なアート素材（プレースホルダーでOK）
- 敵/ボスの具体挙動（最小でOK）
- クエストの詳細（最小でOK）
- アイテム/装備の完全設計（プロトタイプでは簡易でOK）

---

## 付録B：現在の実装状況（2026-02-23 更新）

### 全体サマリー

セクション11のタスク1〜3が **50〜60% 程度**完了。村に **Pawn プレイヤー**（移動・採取・攻撃）、Beehave駆動の敵1体（HP/死亡あり）、3種のリソースノード（木・金鉱石・羊）、簡易リソースHUDが配置され、採取・戦闘の最小ループが動作する。ゲーム固有のコアシステム（実績・AP・報酬・セーブ）は**未着手**。

---

### タスク別 進捗一覧

| # | タスク | 状態 | 備考 |
|---|---|---|---|
| 1 | プロジェクト初期化（シーン/フォルダ/入力/Autoload） | **部分完了** | フォルダ構造あり。`attack`/`interact` 追加済み。AM専用Autoload未登録、`dash`/`open_menu`/`quickslot_*` 未定義 |
| 2 | Player 移動/攻撃/回避（最小） | **部分完了** | Pawn で移動＋攻撃＋採取を実装済み。回避/ダッシュ・HP/スタミナは未実装 |
| 3 | 村・ダンジョンの最小ループ | **部分完了** | 村シーン動作（Pawn+Enemy+リソースノード+HUD）。grasslandフォルダは空 |
| 4 | AchievementManager（データ定義 + 解除イベント） | **未着手** | |
| 5 | HUD（HP/スタミナ/プロンプト/トースト/ピン進捗） | **未着手** | |
| 6 | PauseMenu（4タブ）— 実績タブ優先 | **未着手** | グローバルPauseScreenは存在するが4タブ構成ではない |
| 7 | RewardManager（報酬解放と効果適用） | **未着手** | |
| 8 | セーブ/ロード | **未着手** | |
| 9 | バランス調整 | **未着手** | |
| 10 | GUTテスト追加/整備 | **未着手** | テンプレ（test_example.gd）のみ |

---

### 詳細：実装済みの要素

#### プロジェクト構造
```
root/scenes/game_scene/achievement_master/
├── character/
│   ├── Warrior/        warrior.tscn + warrior.gd（旧プレイヤー、村では未使用）
│   ├── Pawn/           pawn.tscn + pawn.gd（★現プレイヤー：移動・採取・攻撃）
│   └── assets/         Archer, Lancer, Monk（画像のみ）
├── data/
│   └── resource_definitions.gd（★リソース種別・採取データ定義）
├── enemys/
│   ├── enemy.tscn + enemy.gd（Skull敵1種、Beehave BT駆動、HP/死亡あり）
│   └── [15+ フォルダ]  Bear, Gnoll, Minotaur 等（画像のみ、シーンなし）
├── ui/
│   └── resource_hud.tscn + resource_hud.gd（★リソースHUD：Wood/Gold/Meat表示）
└── world/
    ├── map/
    │   ├── village/    village.tscn + village.tres（Pawn+Enemy+リソースノード+HUD配置済）
    │   └── grassland/  ← 空フォルダ
    ├── resource_nodes/（★採取可能オブジェクト）
    │   ├── resource_node.gd（基底クラス：採取/枯渇/リスポーン共通ロジック）
    │   ├── tree_node.gd + tree_node.tscn（木→スタンプ→30秒で復活）
    │   ├── gold_stone_node.gd + gold_stone_node.tscn（金鉱石→暗転→45秒で復活）
    │   └── sheep_node.gd + sheep_node.tscn（羊→待機→20秒で復活）
    ├── assets/         Buildings, Terrain 画像（Resources: Wood/Gold/Meat素材あり）
    └── object/         ← 空フォルダ
```

#### Player（pawn.gd）— ★現在のプレイヤーキャラクター
- `class_name Pawn extends CharacterBody2D`
- **State Machine**：`enum State { IDLE, MOVE, GATHER, ATTACK }`
- **移動**：4方向（`move_left/right/up/down`）、SPEED=200、斜め正規化、Run/Idle アニメ
- **採取**（E キー）：InteractArea（半径80、Layer 3 検知）でリソースノード接近検知 → `get_gather_data()` → 対応アニメ再生 → `harvest()` → インベントリ加算
  - 木：Attack1（斧）アニメ → Wood +3
  - 金鉱石：Guard（ハンマー）アニメ → Gold +2
  - 羊：Attack1（斧）アニメ → Meat +1
- **攻撃**（Space キー）：Attack2（ナイフ）アニメ再生、AttackHitbox（矩形80x60、Layer 2 検知）を0.4秒間有効化、flip_h に応じてヒットボックス左右反転
  - ダメージ：10 / 敵HP：30 → 3回で撃破
- **インベントリ**：Pawn 内部 Dictionary + `inventory_changed` signal（HUD連動）
- Camera2D 直付け
- **未実装**：回避/ダッシュ、プレイヤーHP/スタミナ、無敵フレーム、アイテム持ち替え表示

#### Player 旧（warrior.gd）
- `class_name RpgPlayer extends CharacterBody2D`
- 移動のみ実装。村シーンでは Pawn に差し替え済み
- **問題点**：`ui_left/ui_right` 等のデフォルトアクションを使用（カスタムアクション未使用）

#### Enemy（enemy.gd）
- `class_name Enemy extends CharacterBody2D`
- Beehave行動ツリー：`Selector → [AttackSequence(検知→追跡→攻撃), PatrolSequence(巡回→待機)]`
- DetectArea（半径150）でプレイヤー検知 → Blackboard経由で状態管理
- アニメーション管理（重複防止、flip_hジッター防止）
- **HP/ダメージ**（★実装済み）：`MAX_HP=30`、`take_damage(amount)` → HP減算 → 0以下で `_die()` → `queue_free()`
- **未実装**：死亡アニメーション、ドロップ、ノックバック

#### リソースノードシステム（★新規）
- **基底クラス** `ResourceNode extends StaticBody2D`：`get_gather_data()` / `harvest()` インターフェース、枯渇→リスポーンタイマー
- **データ駆動**：`ResourceDefinitions` クラスに `enum ResourceType { WOOD, GOLD, MEAT }` と `NODE_DATA` 定数で各リソースの yield_amount / gather_animation / gather_time / respawn_time を定義
- **物理レイヤー**：Layer 3 = "ResourceNode"（collision_layer=4）
- **3種のサブクラス**：
  - `TreeNode`：Tree1.png → Stump 1.png（採取でスタンプ表示、30秒で復活）
  - `GoldStoneNode`：Gold Stone 1.png（採取で暗転、45秒で復活）
  - `SheepNode`：AnimatedSprite2D Grass/Idle（採取でIdle、20秒で復活）

#### リソースHUD（★新規）
- `ResourceHud extends CanvasLayer`：画面左上に Wood / Gold / Meat の所持数を表示
- Pawn の `inventory_changed` signal を購読し自動更新

#### Beehave BTリーフノード（`root/scripts/beehave/`）
- `chase_player.gd` — 滑らかな速度補間、攻撃範囲到達でSUCCESS
- `attack_player.gd` — アニメーション完了シグナル待ち、クールダウンタイマー
- `move_to_patrol_point.gd` — 巡回移動（到着閾値あり）
- `wait_at_patrol_point.gd` — 時限待機
- `is_player_visible.gd` — Blackboard読み取り、プレイヤー位置キャッシュ

#### InputMap（project.godot 定義済み）
| アクション | 状態 |
|---|---|
| `move_up/down/left/right` | 定義済み（矢印キー + ジョイパッド） |
| `jump` | 定義済み（C, Space, ジョイパッドA/Y）— プラットフォーマー由来 |
| `ESC` | 定義済み |
| `dialogic_default_action` | 定義済み |
| `attack` | ★定義済み（Space） |
| `interact` | ★定義済み（E） |
| `dash` | **未定義** |
| `open_menu` | **未定義** |
| `quickslot_1/2/3` | **未定義** |

#### 物理レイヤー（project.godot）
| Layer | 名前 | 対象 |
|---|---|---|
| 1 | Player | Pawn |
| 2 | Enemy | Enemy |
| 3 | ResourceNode | ★TreeNode, GoldStoneNode, SheepNode |
| 9 | Ground | TileMap |

#### グローバル基盤（共有、本番品質）
- **GameManager** → SceneNavigator（フェード遷移）+ OverlayController（ESCルーティング）
- **AudioManager** — Master/BGM/SE バス制御、linear↔dB変換
- **SettingsRepository** — `user://settings.cfg` 永続化
- **PauseScreen** — ブラー＋デサチュレーション・シェーダー、Tweenアニメーション
- **Log** — Logger アドオン経由（print()禁止ルール）

#### 利用可能アドオン
- **Beehave 2.9.2** — 行動ツリーAI
- **Dialogic 2.0-Alpha-19** — ダイアログシステム
- **GUT 9.5.0** — ユニットテスト
- **Logger 2.1.1** — ログ出力

---

### 詳細：未実装の要素一覧

| 機能 | 仕様セクション | 状態 |
|---|---|---|
| `GameState` Autoload | 7.2 | 未着手 |
| `AchievementManager` Autoload | 7.2 | 未着手 |
| `RewardManager` Autoload | 7.2 | 未着手 |
| `SaveManager` Autoload | 7.2 | 未着手 |
| 実績データ（achievements.json） | 4.2, 5 | 未着手 |
| 報酬ツリーデータ | 6 | 未着手 |
| APシステム | 4.1 | 未着手 |
| HUDシーン（hud.tscn）— 本格版 | 3.1, 8 | 未着手（簡易リソースHUDのみ実装済み） |
| 4タブPauseMenu（実績タブ含む） | 3.2 | 未着手 |
| 実績トースト通知 | 3.1, 8 | 未着手 |
| ピン留め進捗表示 | 3.1, 3.2 | 未着手 |
| 草原/ダンジョンマップ | 7.1 | フォルダのみ（空） |
| 中ボスシーン（mid_boss.tscn） | 7.1 | 未着手 |
| プレイヤー回避/ダッシュ | 7.3 | 未着手 |
| プレイヤーHP/スタミナ | 3.1 | 未着手 |
| 敵死亡アニメーション/ドロップ | — | 未着手（queue_free のみ） |
| NPC会話・インタラクト | 5.1 | 未着手（Dialogicアドオンは導入済み） |
| クエストシステム | 1.2 | 未着手 |
| 農業/クラフト — 本格版 | 6.3 | 未着手（基礎的な採取システムのみ実装済み） |
| アイテム/装備 | 付録 | 未着手 |
| セーブ/ロード | 9 | 未着手 |
| GUTテスト（実質） | 10 | テンプレのみ |

---

### 実装履歴

#### 2026-02-23 — Pawn プレイヤー実装（移動・採取・攻撃）

| 変更 | 詳細 |
|------|------|
| InputMap 追加 | `attack`（Space）、`interact`（E）を project.godot に追加 |
| 物理レイヤー追加 | Layer 3 = "ResourceNode" を定義 |
| Pawn スクリプト | `pawn.gd` — State Machine（IDLE/MOVE/GATHER/ATTACK）、InteractArea + AttackHitbox |
| リソース定義 | `resource_definitions.gd` — ResourceType enum + NODE_DATA（データ駆動） |
| ResourceNode 基底 | `resource_node.gd` — 採取/枯渇/リスポーン共通ロジック |
| TreeNode | 木→スタンプ→30秒復活（Attack1 アニメ、Wood +3） |
| GoldStoneNode | 金鉱石→暗転→45秒復活（Guard アニメ、Gold +2） |
| SheepNode | 羊→待機→20秒復活（Attack1 アニメ、Meat +1） |
| Enemy HP | `take_damage()`/`_die()` 追加（HP30、3回攻撃で撃破） |
| ResourceHud | 画面左上に Wood/Gold/Meat 表示（Pawn の signal 購読） |
| 村シーン更新 | Warrior → Pawn 差し替え、木×3/金鉱石×2/羊×2/HUD 配置 |

**新規ファイル（11件）:**
- `character/Pawn/pawn.gd`
- `data/resource_definitions.gd`
- `world/resource_nodes/resource_node.gd`
- `world/resource_nodes/tree_node.gd` + `tree_node.tscn`
- `world/resource_nodes/gold_stone_node.gd` + `gold_stone_node.tscn`
- `world/resource_nodes/sheep_node.gd` + `sheep_node.tscn`
- `ui/resource_hud.gd` + `resource_hud.tscn`

**変更ファイル（3件）:**
- `project.godot`（InputMap + Layer名）
- `character/Pawn/pawn.tscn`（InteractArea/AttackHitbox 追加 + スクリプトアタッチ）
- `enemys/enemy.gd`（HP + take_damage + _die 追加）
- `world/map/village/village.tscn`（Pawn配置 + リソースノード + HUD）

---

### 次に着手すべき作業（推奨）

1. **プレイヤーHP/スタミナ** — 敵の攻撃が意味を持つようにする（被ダメージ + 死亡処理）
2. **grasslandマップ** — 村→草原の遷移を作り、最小ループ完成
3. **敵死亡アニメ/ドロップ** — 倒した敵の演出強化
4. **AchievementManager** — コアシステム着手（データ駆動）
5. 以降は設計書セクション11の順序に従う
