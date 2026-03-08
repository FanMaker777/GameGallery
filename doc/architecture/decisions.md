# 設計判断の記録（ADR）

## ADR-001: アイテム定義にアイコン画像を必須とする

- **日付:** 2026-03-06
- **ステータス:** 採用

### 概要

`ItemDefinition`（アイテム基底リソース）に `@export var icon: Texture2D` プロパティを追加し、全アイテムにアイコン画像を設定する。

### ルール

- 新しいアイテムを `item_database.tres` に追加する際は、必ず `icon` プロパティにアイコン画像を設定すること
- アイコン画像は以下のディレクトリ配下から選択する:
  ```
  res://root/scenes/game_scene/achievement_master/ui/assets/icon/
  ├── consumable/     … 消耗品用アイコン
  ├── equipment/      … 装備品用アイコン
  ├── material/       … 素材用アイコン
  └── ten_k_games_icons (204)/  … 汎用アイコン素材集（204種）
  ```
- カテゴリ別フォルダに適切なアイコンがない場合は `ten_k_games_icons (204)/` から選択する

### アイコンの表示箇所

- **バッグリスト:** `InventoryListItem` の各行（24x24）
- **詳細パネル:** `EquipmentTab` の右側詳細ヘッダー（48x48）

---

## ADR-002: ファサード Autoload に委譲メソッドを作らない

- **日付:** 2026-03-08
- **ステータス:** 採用

### 概要

Autoload（ファサード）が内部の子ノードに処理を委譲するだけのメソッドを持つことを禁止する。代わりに、子ノードを公開プロパティとして公開し、外部コードから直接呼び出す。

### 背景

`AchievementManager`（Autoload）が `AchievementTracker`（子ノード）へ単純に委譲するだけのメソッドを18個持っていた。これは二重定義であり、以下の問題を引き起こす:

- **冗長性:** 子ノードにメソッドを追加するたびにファサードにも同じシグネチャのメソッドを追加する必要がある
- **保守コスト:** メソッドの引数や戻り値が変わった際に2箇所を修正する必要がある
- **コード肥大化:** 実質的に何もしないメソッドがファイルの大部分を占める

### ルール

1. **子ノードを公開プロパティとして公開する**
   ```gdscript
   # Good: 公開プロパティ
   @onready var tracker: AchievementTracker = %AchievementTracker

   # Bad: プライベート + 委譲メソッド群
   @onready var _tracker: AchievementTracker = %AchievementTracker
   func get_progress(id: StringName) -> Dictionary:
       return _tracker.get_progress(id)
   ```

2. **外部コードは `Autoload.子ノード.method()` で呼び出す**
   ```gdscript
   # Good
   AchievementManager.tracker.get_progress(id)

   # Bad
   AchievementManager.get_progress(id)
   ```

3. **ファサードに残すもの**
   - **独自ロジックを持つメソッド:** 単純な委譲ではなく、追加処理がある場合は残す
   - **シグナル中継:** Autoload のシグナルを購読するパターンは自然なため、子ノードのシグナルをファサードで中継するのは可
   - **イベントハンドラ:** シーンツリーの監視やシグナル接続など、ファサードの責務に属する処理

4. **定数の参照先**
   - 子ノードで定義された定数はクラス名から直接参照する（`AchievementTracker.MAX_PIN_COUNT`）
   - ファサード側に定数のエイリアスを作らない
