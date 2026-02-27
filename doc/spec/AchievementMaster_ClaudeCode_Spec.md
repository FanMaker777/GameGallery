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

### 1.2 プレイ可能な最小範囲
- **村（リソース採取・会話・クエスト受注）**
- **草原（リソース採取・雑魚 + 中ボス）**
- 実績：**50個**（ログ系25 / 目標系15 / チャレンジ系10）
- 報酬ツリー：グローバル/戦闘/採取/探索交流 の4カテゴリ（合計 ~25ノード）

---

## 2. コアコンセプトとゲームループ
### 2.1 コアループ
1) 行動（戦闘/採取/探索/交流）  
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
- 左上：HPバー / 所持金（任意）
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
- 実績定義：**Custom Resource**（`AchievementDefinition` / `AchievementDatabase`）で管理（型安全・Inspector 編集可）
- 報酬ツリー定義：同様にデータで管理
- セーブ：**JSON**（`user://achievement_master_progress.save`）で進捗・解除済み・AP を保存

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
- ノーダメ連戦 / パリィ連続成功 / パリィ成功 / 縛り装備で中ボス / 30秒討伐 / 回復禁止フロア突破 / 多カテゴリ同日達成 …等

※正確な一覧は別途 `achievements.json` に定義して作成すること（ここでは設計指針）。

---

## 6. 報酬ツリー（例）— プロトタイプ版
> こちらもデータ定義で作成。

### 6.1 グローバル（QoL）
- 通知フィルタ、ピン留め枠+1、おすすめ表示、多様性ボーナス、（任意）リスペック

### 6.2 戦闘
- HP+10%、攻撃+5%、ポーション即時スロット、自動回収、敗北復帰短縮

### 6.3 農業/クラフト
- 収穫ボーナス、料理、納品箱、アクション短縮、列植え

### 6.4 探索/交流
- 移動速度、ミニマップ、目的地ピン、ファストトラベル、宝箱レーダー、店割引、会話スキップ+要約

---

## 7. Godot 実装アーキテクチャ（確認の上、変更可能）
### 7.1 シーン（最小）
- `scenes/world/map/village/village.tscn`（村）
- `scenes/world/map/grassland/grassland.tscn`（草原）
- `scenes/ui/hud.tscn`（HUD）
- `scenes/ui/menu.tscn`（メニュー：4タブ）
- `scenes/player/player.tscn`（プレイヤー）
- `scenes/enemies/enemy.tscn`（雑魚例）
- `scenes/enemies/mid_boss.tscn`（中ボス）

※パスはプロジェクトに合わせて調整。Claude Code は **一貫した規則**で作ること。

#### 7.1.1 Village マップ仕様
- **パス**：`res://root/scenes/game_scene/achievement_master/world/map/village/`
- **リソース**：汎用スポナーノード（→7.4参照）を使用し、複数のリソースをスポーンする。スポーン間隔と最大数は `@export` で制御。
- **NPC**：
  - 村に複数体のNPCを配置し、簡単な会話が可能
  - ルートノード：`CharacterBody2D`
  - 描画：`AnimatedSprite2D` ノード
  - スプライト素材：`res://root/scenes/game_scene/achievement_master/character/` 配下（Archer, Lancer, Monk, Warrior のアセットを使用）
  - インタラクション：プレイヤーが `interact` アクションで話しかけると、`Label` ノードでセリフを表示
- **建物**：
  - 村に複数の建物を配置
  - ルートノード：`StaticBody2D`
  - 描画：`Sprite2D` ノード
  - 画像素材：`res://root/scenes/game_scene/achievement_master/world/assets/Buildings/` 配下（Blue, Black, Red, Yellow, Purple セット — 各 House1-3, Castle, Tower, Barracks, Archery, Monastery）
  - 物理レイヤー：プレイヤーやNPCが建物を通り抜けられないよう衝突設定

#### 7.1.2 Grassland マップ仕様
- **パス**：`res://root/scenes/game_scene/achievement_master/world/map/grassland/`
- **リソース**：汎用スポナーノード（→7.4参照）を使用し、複数のリソースをスポーンする。スポーン間隔と最大数は `@export` で制御。
- **敵**：汎用スポナーノード（→7.4参照）を使用し、複数の敵をスポーンする。スポーン間隔と最大数は `@export` で制御。

### 7.2 Autoload（シングルトン）
- `AchievementManager`：実績進捗、解除判定、通知イベント、セーブ/ロード（JSON）
- `RewardManager`：報酬ツリー解放と効果適用
- （任意）`AudioManager`

### 7.3 入力（InputMap）
- `move_up/down/left/right`
- `attack`
- `interact`
- `open_menu`
- `quickslot_1/2/3`

### 7.4 汎用スポナーノード（GenericSpawner）
> 既存の `SheepSpawner` を汎用化し、リソースノード・敵を問わず任意のシーンをスポーンできるようにする。

- **クラス名**：`GenericSpawner extends Node2D`
- **パス**：`res://root/scenes/game_scene/achievement_master/world/spawner/generic_spawner.gd`（+ `.tscn`）
- **Export変数**（Inspectorから設定）：
  - `@export var spawn_scene: PackedScene` — スポーン対象シーン（任意の `.tscn` を指定）
  - `@export var spawn_interval: float = 20.0` — スポーン間隔（秒）
  - `@export var max_count: int = 3` — シーン内の最大同時存在数
  - `@export var spawn_area: Rect2 = Rect2(-200, -200, 400, 400)` — スポーン範囲（ローカル座標）
- **動作**：
  - `_ready()` でタイマーを生成し、`spawn_interval` 秒ごとにスポーン処理を実行
  - スポーン処理：現在の子ノード数（または `tree_exited` で追跡）が `max_count` 未満ならインスタンス生成
  - インスタンスは `spawn_area` 内のランダム位置に配置
  - スポーン済みノードが `queue_free()` された場合、カウントが減り再スポーン可能になる
- **用途例**：
  - 村のリソース：`spawn_scene` に `tree_node.tscn` / `gold_stone_node.tscn` / `sheep_node.tscn` を指定
  - 草原の敵：`spawn_scene` に `enemy.tscn` を指定
- **旧 SheepSpawner との違い**：
  - `preload` によるハードコード → `@export var spawn_scene` で Inspector から指定に変更
  - `max_sheep_count` → `max_count`（汎用名）
  - `SheepNode` 固定のカウント → スポーン済みインスタンスを汎用的に追跡

---

## 8. HUDワイヤーフレーム（Godot実装前提）
> HUDのノードは CanvasLayer + 安全域 MarginContainer を基本にする。

推奨ツリー（概要）：
- `CanvasLayer(HUD)`
  - `MarginContainer(RootSafeArea)`
    - `TopLeft/PlayerStatusPanel`：HP/所持金
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
2) Player 移動/攻撃（最小）
3) 村・ダンジョンの最小ループ（出入り、敵1種）
4) `AchievementManager`（データ定義 + 解除イベント）
5) HUD（HP/プロンプト/トースト/ピン進捗）
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

## 付録B：現在の実装状況（2026-02-27 更新）

### 全体サマリー

セクション11のタスク1〜3が **95% 程度**完了。村に **Pawn プレイヤー**（移動・採取・攻撃・NPC会話・HP・被ダメージ・死亡・★ドロップ回収）、**NPC 3体**（弓使い・修道士・槍兵 — セリフ順送り表示）、Beehave駆動の敵（HP/★死亡演出/★ゴールドドロップあり）、3種のリソースノード（木・金鉱石・羊）、簡易リソースHUDが配置済み。**草原マップ**が新規追加され、GenericSpawner による敵×5体のスポーン、村⇔草原の**フェード遷移（MapGate）**が動作する。ゲーム固有のコアシステム（実績・AP・報酬・セーブ）は**未着手**。

---

### タスク別 進捗一覧

| # | タスク | 状態 | 備考 |
|---|---|---|---|
| 1 | プロジェクト初期化（シーン/フォルダ/入力/Autoload） | **ほぼ完了** | フォルダ構造・InputMap全アクション定義済み。AM専用Autoload未登録のみ残り |
| 2 | Player 移動/攻撃（最小） | **ほぼ完了** | Pawn で移動＋攻撃＋採取＋HP＋被ダメージ＋死亡を実装済み |
| 3 | 村・ダンジョンの最小ループ | **ほぼ完了** | 村＋草原マップ動作、MapGateでフェード遷移、★NPC会話実装済み、★敵死亡演出/ドロップ実装済み。建物配置が未実装 |
| 4 | AchievementManager（データ定義 + 解除イベント） | **実装済み** | Custom Resource + JSON セーブ |
| 5 | HUD（HP/プロンプト/トースト/ピン進捗） | **未着手** | |
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
│   ├── Pawn/           pawn.tscn + pawn.gd（★現プレイヤー：移動・採取・攻撃・NPC会話・HP・死亡）
│   ├── npc/            ★npc.tscn + npc.gd（会話NPC基底：セリフ順送り、SpriteFrames export）
│   └── assets/         Archer, Lancer, Monk（画像のみ）
├── data/
│   └── resource_definitions.gd（★リソース種別・採取データ定義）
├── enemys/
│   ├── enemy.tscn + enemy.gd（Skull敵1種、Beehave BT駆動、HP/死亡あり）
│   └── [15+ フォルダ]  Bear, Gnoll, Minotaur 等（画像のみ、シーンなし）
├── ui/
│   └── resource_hud.tscn + resource_hud.gd（★リソースHUD：HP/Wood/Gold/Meat表示）
└── world/
    ├── map/
    │   ├── village/    village.tscn + village.tres（Pawn+Enemy+リソースノード+★NPC×3+HUD+MapGate配置済）
    │   ├── grassland/  ★grassland.tscn（EnemySpawner×2+リソース+岩装飾+MapGate）
    │   └── gate/       ★map_gate.gd + map_gate.tscn（マップ遷移ゲート）
    ├── spawner/        ★generic_spawner.gd + generic_spawner.tscn（汎用スポナー）
    ├── resource_nodes/（★採取可能オブジェクト）
    │   ├── resource_node.gd（基底クラス：採取/枯渇/リスポーン共通ロジック）
    │   ├── tree_node.gd + tree_node.tscn（木→スタンプ→30秒で復活）
    │   ├── gold_stone_node.gd + gold_stone_node.tscn（金鉱石→暗転→45秒で復活）
    │   ├── sheep_node.gd + sheep_node.tscn（羊→待機→20秒で復活）
    │   └── sheep_spawner.gd + sheep_spawner.tscn（旧スポナー、GenericSpawnerに置換済み）
    ├── drop_item/      ★drop_item.gd + drop_item.tscn（敵ドロップアイテム：自動回収 + 演出）
    ├── assets/         Buildings, Terrain 画像（Resources: Wood/Gold/Meat素材あり）
    └── object/         ← 空フォルダ
```

#### Player（pawn.gd）— ★現在のプレイヤーキャラクター
- `class_name Pawn extends CharacterBody2D`
- **State Machine**：`enum State { IDLE, MOVE, GATHER, ATTACK, DEAD }`
- **移動**：4方向（`move_left/right/up/down`）、SPEED=200、斜め正規化、Run/Idle アニメ
- **インタラクト**（E キー）：InteractArea（半径91、Layer 3+4 検知）で "resource_node" / "npc" 両グループの最寄り対象を検知
  - **採取**（リソースノード）：`get_gather_data()` → 対応アニメ再生 → `harvest()` → インベントリ加算
    - 木：HarvestTree アニメ → Wood +3
    - 金鉱石：HarvestGold アニメ → Gold +2
    - 羊：HarvestSheep アニメ → Meat +1
  - **会話**（NPC）：NPC の `interact()` を呼出 → セリフ Label 表示（順送り、表示秒数後に自動非表示）
  - プロンプト表示：対象に応じて「E 採取」/「E 話す」を自動切替
- **攻撃**（Space キー）：Attack アニメ再生、AttackHitbox（矩形80x60、Layer 2 検知）を0.4秒間有効化、flip_h に応じてヒットボックス左右反転
  - ダメージ：10 / 敵HP：30 → 3回で撃破
- **HP/被ダメージ**（★実装済み）：MAX_HP=100、`take_damage(amount)` → HP減算 → `health_changed` signal → 0以下で DEAD 状態
  - 無敵フレーム：被ダメージ後1秒間、スプライト点滅（0.1秒間隔）
  - DEAD 状態：全入力無効化
- **インベントリ**：Pawn 内部 Dictionary + `inventory_changed` signal（HUD連動）
- **ドロップ回収**（★実装済み）：`collect_drop(type, amount)` メソッド — DropItem から呼ばれ `_add_resource()` 経由でインベントリ加算
- Camera2D 直付け
- **未実装**：アイテム持ち替え表示、死亡後のリスポーン

#### Player 旧（warrior.gd）
- `class_name RpgPlayer extends CharacterBody2D`
- 移動のみ実装。村シーンでは Pawn に差し替え済み
- **問題点**：`ui_left/ui_right` 等のデフォルトアクションを使用（カスタムアクション未使用）

#### Enemy（enemy.gd）
- `class_name Enemy extends CharacterBody2D`
- Beehave行動ツリー：`Selector → [AttackSequence(検知→追跡→攻撃), PatrolSequence(巡回→待機)]`
- DetectArea（半径150）でプレイヤー検知 → Blackboard経由で状態管理
- アニメーション管理（重複防止、flip_hジッター防止）
- **HP/ダメージ**（★実装済み）：`MAX_HP=30`、`take_damage(amount)` → HP減算 → 0以下で `_die()`
  - 死亡演出中は `_is_dying` フラグでダメージ・AI・移動を停止
- **死亡演出**（★実装済み）：`_play_death_effect()` — 白フラッシュ3回（modulate明滅 × 3、計0.3秒）→ フェードアウト + 縮小（0.4秒）→ `queue_free()`
- **ドロップ**（★実装済み）：`_spawn_drop_item()` — `@export var drop_item_scene: PackedScene`（drop_item.tscn）をワールドに生成
  - `@export var drop_gold_amount: int = 5` — Gold ドロップ量
  - `died` シグナル発火（AchievementManager 等の外部連携用）
- **未実装**：ノックバック

#### DropItem（drop_item.gd）（★新規）
- `class_name DropItem extends Node2D`
- **パス**：`world/drop_item/drop_item.gd` + `.tscn`
- **Export変数**：`resource_type: ResourceDefinitions.ResourceType`、`amount: int = 5`
- **スプライト**：Gold_Resource.png（scale 0.5）
- **PickupArea**：Area2D（CircleShape2D 半径30、collision_layer=0, collision_mask=1=Player）
- **スポーン演出**：上に40px跳ねて落下するバウンド（Tween 0.4秒）
- **回収処理**：Pawn が PickupArea に接触 → `collect_drop()` 呼出 → 吸い込み+フェードアウト演出（0.25秒）→ `queue_free()`
- **二重回収防止**：`_picked_up` フラグ

#### リソースノードシステム（★新規）
- **基底クラス** `ResourceNode extends StaticBody2D`：`get_gather_data()` / `harvest()` インターフェース、枯渇→リスポーンタイマー
- **データ駆動**：`ResourceDefinitions` クラスに `enum ResourceType { WOOD, GOLD, MEAT }` と `NODE_DATA` 定数で各リソースの yield_amount / gather_animation / gather_time / respawn_time を定義
- **物理レイヤー**：Layer 3 = "ResourceNode"（collision_layer=4）
- **3種のサブクラス**：
  - `TreeNode`：Tree1.png → Stump 1.png（採取でスタンプ表示、30秒で復活）
  - `GoldStoneNode`：Gold Stone 1.png（採取で暗転、45秒で復活）
  - `SheepNode`：AnimatedSprite2D Grass/Idle（採取でIdle、20秒で復活）

#### リソースHUD（★新規）
- `ResourceHud extends CanvasLayer`：画面左上に HP / Wood / Gold / Meat を表示
- Pawn の `inventory_changed` / `health_changed` signal を購読し自動更新

#### GenericSpawner（★新規）
- `class_name GenericSpawner extends Node2D`
- **パス**：`world/spawner/generic_spawner.gd` + `.tscn`
- `@export var spawn_scene: PackedScene` — Inspector から任意の .tscn を指定
- `@export var spawn_interval: float = 20.0` — スポーン間隔（秒）
- `@export var max_count: int = 3` — 最大同時存在数
- `@export var spawn_area: Rect2 = Rect2(-200, -200, 400, 400)` — スポーン範囲
- `tree_exited` シグナルで削除を検知し、カウントを自動減算
- 旧 `SheepSpawner` を完全に置換

#### NPC（★新規）
- `class_name Npc extends CharacterBody2D`
- **パス**：`character/npc/npc.gd` + `npc.tscn`
- **物理レイヤー**：Layer 4 = "NPC"（collision_layer=8, collision_mask=256=Ground）
- **Export変数**（Inspector から設定）：
  - `@export var npc_name: String` — NPC名（NameLabel に反映）
  - `@export var dialogues: Array[String]` — セリフリスト（順番に表示）
  - `@export var display_duration: float = 3.0` — セリフ表示秒数
  - `@export var sprite_frames: SpriteFrames` — アニメーション用 SpriteFrames リソース
- **シーンツリー**：
  - `Npc` (CharacterBody2D) → AnimatedSprite2D (%AnimatedSprite) + CollisionShape2D (CapsuleShape2D) + DialogueLabel (%DialogueLabel, 頭上) + NameLabel (%NameLabel, 足元)
- **動作**：
  - `_ready()` で "npc" グループに追加、SpriteFrames を AnimatedSprite2D に適用、Idle アニメ再生
  - `interact()` でセリフを順送り表示（`_dialogue_index` をインクリメント、末尾で先頭に戻る）
  - 会話中フラグ `_is_talking` で連打防止（表示秒数経過後に解除）
- **村の配置（3体）**：
  - 弓使い（Archer）— 村の左側 (-250, 50)
  - 修道士（Monk）— 村の中央上 (0, -150)
  - 槍兵（Lancer）— 村の右側 (350, 50)

#### MapGate（★新規）
- `class_name MapGate extends Area2D`
- **パス**：`world/map/gate/map_gate.gd` + `.tscn`
- `@export_file("*.tscn") var target_scene_path: String` — 遷移先シーン
- `@export var gate_label: String` — ゲート表示名
- Pawn 接触時に `GameManager.load_scene_with_transition()` でフェード遷移
- 二重遷移防止フラグ付き
- CollisionShape2D（32×128）+ Label でゲート表示

#### Grassland マップ（★新規）
- **パス**：`world/map/grassland/grassland.tscn`
- 村と同じ TileSet（village.tres）を使用
- **EnemySpawner×2**：GenericSpawner で敵を計5体までスポーン（15秒×3体 + 20秒×2体）
- **リソース**：TreeNode×2 + GoldStone×1
- **装飾**：Rock×3
- **MapGate**：左端に「← 村」ゲート配置
- 村より戦闘中心のエリア

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
| `attack` | 定義済み（Space） |
| `interact` | 定義済み（E） |
| `open_menu` | ★定義済み（Tab） |
| `quickslot_1` | ★定義済み（1） |
| `quickslot_2` | ★定義済み（2） |
| `quickslot_3` | ★定義済み（3） |

#### 物理レイヤー（project.godot）
| Layer | 名前 | 対象 |
|---|---|---|
| 1 | Player | Pawn |
| 2 | Enemy | Enemy |
| 3 | ResourceNode | TreeNode, GoldStoneNode, SheepNode |
| 4 | NPC | ★Npc（会話可能キャラクター） |
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
| `AchievementManager` Autoload | 7.2 | **★実装済み** — Custom Resource 定義(50実績) + 進捗管理 + JSON セーブ/ロード |
| `RewardManager` Autoload | 7.2 | 未着手 |
| 実績データ（AchievementDatabase.tres） | 4.2, 5 | **★実装済み** — 50実績定義（戦闘15/農業12/探索10/交流8/システム5） |
| 報酬ツリーデータ | 6 | 未着手 |
| APシステム | 4.1 | 未着手 |
| HUDシーン（hud.tscn）— 本格版 | 3.1, 8 | 未着手（簡易リソースHUDのみ実装済み） |
| 4タブPauseMenu（実績タブ含む） | 3.2 | 未着手 |
| 実績トースト通知 | 3.1, 8 | 未着手 |
| ピン留め進捗表示 | 3.1, 3.2 | 未着手 |
| 中ボスシーン（mid_boss.tscn） | 7.1 | 未着手 |
| 敵死亡アニメーション/ドロップ | — | **★実装済み** — Tween白フラッシュ+フェードアウト、Goldドロップ（自動回収+HUD連動） |
| NPC会話・インタラクト | 5.1 | **★実装済み** — 簡易会話（Label表示、セリフ順送り）。Dialogic連携は未着手 |
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

#### 2026-02-25 — ゲームプレイ基盤完成（GenericSpawner・草原マップ・マップ遷移）

| 変更 | 詳細 |
|------|------|
| InputMap 追加 | `open_menu`（Tab）、`quickslot_1`（1）、`quickslot_2`（2）、`quickslot_3`（3）を project.godot に追加 |
| GenericSpawner | 汎用スポナー新規作成。`@export var spawn_scene` で任意シーンをスポーン可能。旧 SheepSpawner を村シーンで置換 |
| Grassland マップ | 草原シーン新規作成。EnemySpawner×2（計5体）+ TreeNode×2 + GoldStone×1 + Rock×3 |
| MapGate | マップ遷移ゲート新規作成。Area2D + Label、Pawn 接触で `GameManager.load_scene_with_transition()` 呼出 |
| 村シーン更新 | SheepSpawner→GenericSpawner 置換、GateToGrassland（右端）追加 |
| PathConsts 更新 | AM シーンパス定数（`AM_VILLAGE_SCENE` / `AM_GRASSLAND_SCENE`）追加、ポーズスクリーン有効化 |

**新規ファイル（5件）:**
- `world/spawner/generic_spawner.gd` + `generic_spawner.tscn`
- `world/map/grassland/grassland.tscn`
- `world/map/gate/map_gate.gd` + `map_gate.tscn`

**変更ファイル（3件）:**
- `project.godot`（InputMap に 4 アクション追加）
- `world/map/village/village.tscn`（SheepSpawner→GenericSpawner 置換 + MapGate 追加）
- `root/scripts/const/path_consts.gd`（AM パス定数 + PAUSE_SCREEN_ENABLE_SCENES 追加）

---

#### 2026-02-25 — 村NPC会話システム実装

| 変更 | 詳細 |
|------|------|
| 物理レイヤー追加 | Layer 4 = "NPC" を project.godot に定義 |
| NPC 基底スクリプト | `npc.gd` — `class_name Npc extends CharacterBody2D`、`@export var sprite_frames: SpriteFrames` で Inspector からアニメーション設定、`interact()` でセリフ順送り表示（連打防止付き） |
| NPC シーン | `npc.tscn` — AnimatedSprite2D + CollisionShape2D + DialogueLabel（頭上）+ NameLabel（足元） |
| Pawn インタラクト拡張 | `_get_nearest_resource()` → `_get_nearest_interactable()` に改名、"npc" グループ検索追加、`_start_talk()` 追加、プロンプト自動切替（「E 採取」/「E 話す」） |
| Pawn シーン更新 | InteractArea の collision_mask に Layer 4 (NPC) を追加 |
| 村シーン更新 | NPC 3体をインスタンス配置: 弓使い（Archer, 左側）/ 修道士（Monk, 中央上）/ 槍兵（Lancer, 右側） |

**新規ファイル（2件）:**
- `character/npc/npc.gd`
- `character/npc/npc.tscn`

**変更ファイル（4件）:**
- `project.godot`（Layer 4 "NPC" 追加）
- `character/Pawn/pawn.gd`（インタラクト拡張: NPC 会話対応）
- `character/Pawn/pawn.tscn`（InteractArea mask に Layer 4 追加）
- `world/map/village/village.tscn`（NPC 3体配置）

---

#### 2026-02-27 — 敵死亡演出/ドロップアイテム実装

| 変更 | 詳細 |
|------|------|
| DropItem シーン新規作成 | `drop_item.gd` + `drop_item.tscn` — Node2D + Sprite2D(Gold_Resource.png) + PickupArea(Area2D) |
| DropItem スポーン演出 | 上に40px跳ねて落下するバウンド（Tween 0.4秒） |
| DropItem 回収処理 | Pawn 接近で `collect_drop()` 呼出 → 吸い込み+フェードアウト演出（0.25秒）→ `queue_free()` |
| Enemy 死亡演出 | `_play_death_effect()` — 白フラッシュ3回（0.3秒）→ フェードアウト+縮小（0.4秒）→ `queue_free()` |
| Enemy ドロップ生成 | `_spawn_drop_item()` — ワールドに DropItem を生成（Gold x5） |
| Enemy 死亡ガード | `_is_dying` フラグで死亡演出中のダメージ・AI・移動を停止 |
| Enemy シグナル追加 | `died` シグナル（AchievementManager 連携用） |
| Pawn ドロップ回収 | `collect_drop()` メソッド追加 — `_add_resource()` → `inventory_changed` → ResourceHud 自動更新 |

**新規ファイル（2件）:**
- `world/drop_item/drop_item.gd`
- `world/drop_item/drop_item.tscn`

**変更ファイル（3件）:**
- `enemys/enemy.gd`（死亡演出・ドロップ生成・died シグナル・_is_dying ガード追加）
- `enemys/enemy.tscn`（drop_item_scene / drop_gold_amount エクスポート設定）
- `character/Pawn/pawn.gd`（`collect_drop()` メソッド追加）

---

### 次に着手すべき作業（推奨）

**ステップ2（フェーズ A 残り — 任意、後回し可）:**
1. ~~**NPC会話** — 村に簡易会話キャラクター配置（実績カウント対象）~~ **★完了（2026-02-25）**
2. **建物配置** — 村に Buildings 素材で衝突付き建物配置
3. ~~**敵死亡アニメ/ドロップ** — 倒した敵の演出強化~~ **★完了（2026-02-27）**

**ステップ3（フェーズ B — コアシステム、推奨）:**
4. **AchievementManager** — 実績データ(Resource) + 進捗管理 + 解除判定 + シグナル + セーブ/ロード(JSON)
6. **イベントフック** — 各所に `AchievementManager.record_action()` 呼出を埋め込み

**AM専用 Autoload の配置先（決定済み）:**
```
res://root/scenes/game_scene/achievement_master/autoload/
├── achievement_manager/achievement_manager.gd + .tscn
├── reward_manager/reward_manager.gd
└── save_manager/save_manager.gd
```

以降は設計書セクション11の順序に従い、フェーズ C（HUD）→ D（メニュー）→ E（報酬・セーブ）→ F（テスト）と進める。
