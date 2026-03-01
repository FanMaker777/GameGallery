# Beehave（Godot アドオン）実装ガイド（Claude Code 向け）
対象：Godot 4.x / Beehave 2.x 系  
目的：**Claude Code に「Beehave 前提のAI（ビヘイビアツリー）実装」を依頼するための仕様・作法を1ファイルに集約**  
備考：**インストール関連は含めない**  
公式Wiki： https://bitbra.in/beehave/#/

---

## 1. Beehaveの全体像（何を提供しているか）
Beehave は **Godot のノード（Node）としてビヘイビアツリーを構築・実行**するアドオン。

- ルート：`BeehaveTree`
- ツリー要素：`BeehaveNode`（各種Composite/Decorator/Leaf）
- 実行：各ノードの `tick(actor, blackboard)` により進行し、**Status**で制御する  
  - `SUCCESS` / `FAILURE` / `RUNNING`

---

## 2. コア概念
### 2.1 Status（tickの戻り値契約）
`tick(actor, blackboard)` は必ず以下のいずれかを返す。

- `SUCCESS`：成功（次へ進む/確定）
- `FAILURE`：失敗（別分岐へ/中断）
- `RUNNING`：継続（次フレーム以降も同ノードを評価し続ける）

> 実装上、`tick()` の戻り値が不正な場合は安全側（失敗側）に倒れる想定で設計されているため、必ず int のStatusを返す。

### 2.2 actor（行動主体）
`actor` は「ツリーが操作する対象ノード」。

- 通常：`BeehaveTree` の親ノード
- `BeehaveTree.actor_node_path` を指定：その NodePath のノードを actor にする

### 2.3 blackboard（共有データ）
`Blackboard` はノード間の共有状態ストア。

- 代表API：`set_value()`, `get_value()`, `has_value()`, `erase_value()`
- **名前付きBlackboard**（第三引数 `blackboard_name`）を使うと、共有blackboard運用時でも衝突しにくい

---

## 3. BeehaveTree（ルートノード）
### 3.1 役割
ツリー全体の実行管理を行う。

- 子は原則1つ（ルートCompositeを1つ）
- 実行頻度：`tick_rate`（フレーム間引き）
- ON/OFF：`enabled`
- 実行タイミング：`process_thread`
  - `PHYSICS`：`_physics_process` で tick
  - `IDLE`：`_process` で tick
  - `MANUAL`：自動tickしない（任意の箇所で `tick()` する）

### 3.2 Claude Code に伝えるべき運用ルール
- `BeehaveTree` は actor 配下に配置（例：Enemy の子）
- `BeehaveTree` の子は **コンポジットを1つだけ**
- `MANUAL` を採用する場合は、**どこで tick するか**（例：AIマネージャの `_physics_process`）を明示する

---

## 4. Blackboard（データ共有）
### 4.1 基本API（よく使う）
```gdscript
# 書き込み
blackboard.set_value("target", target_node)

# 読み込み（デフォルト値付き）
var target = blackboard.get_value("target", null)

# 存在確認（nullは「存在しない」扱いになり得るため、has_valueを使う）
if blackboard.has_value("target"):
    pass

# 削除（内部的にはnull化など）
blackboard.erase_value("target")
```

### 4.2 共有Blackboard運用（衝突回避）
同一Blackboardを複数actorで共有する場合、**actorごとに名前を分ける**のが安全。

```gdscript
var id := str(actor.get_instance_id())
blackboard.set_value("target", target_node, id)
var target = blackboard.get_value("target", null, id)
```

---

## 5. ノード種別（BeehaveNode階層）
概ね以下カテゴリで構成される。

- `BeehaveNode`：全ノードの基底
- **Composite**：子を複数持ち、実行フロー制御（Selector/Sequence 系）
- **Decorator**：子を1つ持ち、結果（Status）を変換/制御
- **Leaf**：末端（Action/Condition）。原則子を持たない
- **Blackboard系Leaf**：Expressionでblackboard読み書きする補助ノード

---

## 6. 実装で頻出のクラスと挙動
### 6.1 BeehaveNode（基底）
- `tick(actor, blackboard)` を override
- 長い処理は `RUNNING` を返し、完了時に `SUCCESS` / `FAILURE`
- 分岐切り替え等で中断されるため、必要なら `interrupt()` を実装して後始末する

### 6.2 Leaf / ActionLeaf / ConditionLeaf
- `ActionLeaf`：移動・攻撃・待機など「行動」
- `ConditionLeaf`：条件判定（基本は即時判定で `RUNNING` を返さない）

**ConditionLeaf テンプレ**
```gdscript
class_name IsPlayerVisibleCondition
extends ConditionLeaf

func tick(actor: Node, blackboard: Blackboard) -> int:
    if actor.has_method("can_see_player") and actor.can_see_player():
        return SUCCESS
    return FAILURE
```

**ActionLeaf（RUNNINGの例）**
```gdscript
class_name ChasePlayerAction
extends ActionLeaf

func before_run(actor: Node, blackboard: Blackboard) -> void:
    pass

func tick(actor: Node, blackboard: Blackboard) -> int:
    var player := blackboard.get_value("player", null)
    if player == null:
        return FAILURE

    actor.global_position = actor.global_position.move_toward(
        player.global_position,
        120.0 * get_physics_process_delta_time()
    )

    if actor.global_position.distance_to(player.global_position) < 24.0:
        return SUCCESS

    return RUNNING

func interrupt(actor: Node, blackboard: Blackboard) -> void:
    # 中断時の後始末（速度/状態リセット等）
    pass

func after_run(actor: Node, blackboard: Blackboard) -> void:
    pass
```

---

## 7. Composite（フロー制御）
### 7.1 SelectorComposite（優先分岐）
- 子を上から評価し、最初に `SUCCESS` / `RUNNING` を返した子を採用
- 全部 `FAILURE` なら Selector も `FAILURE`

用途例：攻撃→追跡→巡回（上ほど優先）

### 7.2 SelectorReactiveComposite（リアクティブ優先分岐）
- 優先条件を毎tick再評価しやすい（割り込みを強めたいとき）
- 条件判定の頻度が上がるためコストに注意

用途例：HP低下で即逃走へ切替

### 7.3 SequenceComposite（手順実行）
- 子を順に実行
- 全部 `SUCCESS` なら `SUCCESS`
- 途中 `FAILURE` で `FAILURE`
- 途中 `RUNNING` で継続

用途例：目標確認→接近→攻撃

### 7.4 SequenceReactiveComposite（リアクティブ手順）
- RUNNING中も手順の前段条件を再評価しやすい（挙動は実装依存）
- 「走りながら条件監視」系に向く

---

## 8. Decorator（結果の変換・制約）
Decoratorは **子を1つだけ**持ち、Statusを加工する。

### 8.1 InverterDecorator（成功/失敗反転）
- `SUCCESS` ↔ `FAILURE`
- `RUNNING` は維持

用途例：否定条件（見えていないなら～）

### 8.2 AlwaysSucceedDecorator / AlwaysFailDecorator
- 子の結果にかかわらず `SUCCESS` / `FAILURE` を返す（RUNNINGは継続）

用途例：失敗してもシーケンスを止めたくない

### 8.3 LimiterDecorator（回数制限）
- tick回数などの上限で強制 `FAILURE`（挙動は実装依存）
- ブランチ切替（interrupt）でリセットされる想定

用途例：追跡を最大Nフレームまで

### 8.4 CooldownDecorator（クールダウン）
- 子の完了後、一定時間は実行させず `FAILURE`（挙動は実装依存）

用途例：攻撃の連打防止

### 8.5 RepeaterDecorator（繰り返し）
- 子が `SUCCESS` を一定回数返すまで繰り返す（失敗で中断）

用途例：探索をN回試す

---

## 9. Blackboard系の組み込みLeaf（Expression）
Beehaveには blackboard を扱うための組み込みLeafがあり、**Godotの Expression** を使う。

### 9.1 BlackboardSetAction（式でキー/値を評価してセット）
- `key` と `value` は Expression 文字列
- 評価のベースは blackboard（Expressionのbase_instanceがblackboard想定）

> 注意：キーは基本 `"..."` で文字列にする（未クォートは変数参照になって失敗しやすい）

例：
- key: `"player_sighted"`
- value: `true`

### 9.2 BlackboardHasCondition（指定キーの有無）
- `key` を Expression 評価 → そのキーが存在すれば `SUCCESS`

---

## 10. デバッグとパフォーマンス（運用方針）
- デバッグ可視化は便利だが、量産AI全体で常時有効にすると負荷になり得る
- 基本方針：
  - 追うのは「代表1体」または「代表ツリー」
  - 必要時のみデバッグ可視化をON

また、Performance Monitor に beehave系のメトリクスが登録されるため、負荷確認に活用できる。  
（個別ツリーの計測などは `BeehaveTree.custom_monitor` で切替える設計）

---

## 11. Claude Code に渡す「実装依頼テンプレ」（必須情報）
### 11.1 前提（actor / blackboard / ツリー構造）
- actor のクラス（例：Enemy.gd / CharacterBody2D）
- `BeehaveTree` の配置先（actorの子）
- `actor_node_path` の有無（あればNodePath）
- blackboard 運用（個別 or 共有 / 名前付き利用の有無）
- blackboard キー一覧（型・意味・更新責務）

### 11.2 行動仕様（ノード定義）
- ConditionLeaf：判定条件、参照するactor/blackboardキー、戻り値（SUCCESS/FAILURE）
- ActionLeaf：開始条件、完了条件、失敗条件、RUNNING中の更新、interrupt時の後始末

### 11.3 指示文ミニ例
- 「`IsPlayerVisibleCondition` と `ChasePlayerAction` を作成」
- 「ツリーは `SelectorComposite` をルートにし、分岐は『攻撃→追跡→巡回』」
- 「追跡は距離<24でSUCCESS、見失ったらFAILURE、追跡中はRUNNING」
- 「HP<20%なら `SelectorReactiveComposite` で逃走へ割り込み」

---

## 12. 参照（公式）
- 公式Wiki： https://bitbra.in/beehave/#/
- ソース（リポジトリ）： https://github.com/bitbrain/beehave
