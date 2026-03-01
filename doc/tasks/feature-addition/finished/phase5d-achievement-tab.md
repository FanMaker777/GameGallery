# Phase 5D: 実績タブ（フィルタ・詳細・ピン留め・おすすめ）を実装

## 目的

ポーズメニューの実績タブに全実績の閲覧・フィルタ・ピン留め機能を実装する。

## 作成ファイル

- `ui/menu/achievement_tab/achievement_tab.gd` + `.tscn` — タブ本体（左: リスト、右: 詳細）
- `ui/menu/achievement_tab/achievement_list_item.gd` + `.tscn` — 1 行分の実績表示

## 仕様

- フィルタ: カテゴリ（全て/戦闘/農業/探索/交流/システム）、状態（全て/未達成/達成済）、ランク
- 詳細パネル: 名前・説明・進捗バー・AP 報酬・ランク
- ピン留め: 最大 3 件、トグルボタン
- おすすめ: 達成率が高い未解除実績を 3 件（カテゴリ分散）

## AchievementManager への追加

- `pinned_ids: Array[StringName]` プロパティ
- `pinned_changed` シグナル
- `pin_achievement()` / `unpin_achievement()` メソッド
- セーブ/ロードに `pinned_ids` を追加

## 修正ファイル

- `achievement_manager.gd` — ピン留め機能追加
- `am_pause_menu.tscn` — 実績タブスロットに AchievementTab を埋め込み

## コミットメッセージ

`feat: 実績タブ（フィルタ・詳細・ピン留め・おすすめ）を実装`
