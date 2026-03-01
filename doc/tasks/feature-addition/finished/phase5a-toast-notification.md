# Phase 5A: 実績解除トースト通知システムを追加

## 目的

実績解除時に画面にトースト通知を表示し、「気持ちいいが邪魔にならない」フィードバックを実現する。

## 作成ファイル

- `ui/toast/achievement_toast.gd` + `.tscn` — 1 件分の通知パネル（ランクアイコン + 名前 + AP）
- `ui/toast/toast_manager.gd` + `.tscn` — キュー管理（VBoxContainer、画面下部に配置）

## 仕様

- 表示時間: 2 秒、スライドイン/アウト Tween アニメーション
- Bronze: 戦闘中はキューに溜めて戦闘後にまとめて表示
- Silver/Gold: 即時表示（優先キュー）
- `AchievementManager.achievement_unlocked` シグナルを購読

## 修正ファイル

- `pawn.gd` — 戦闘状態シグナル `combat_state_changed(is_in_combat: bool)` を追加
  - ATTACK ステートに入るか被ダメージ時に `true`、5 秒間無活動で `false`

## コミットメッセージ

`feat: 実績解除トースト通知システムを追加`
