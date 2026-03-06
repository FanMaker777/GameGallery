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
