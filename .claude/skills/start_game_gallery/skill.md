---
name: start_game_gallery
description: GameGallery プロジェクトの開発環境を準備する。作業ディレクトリ移動・CLAUDE.md 読み込み・プロジェクト状態確認を一括で行い、すぐに開発作業に入れる状態にする。
user_invocable: true
---

# start_game_gallery スキル

GameGallery（Godot マルチミニゲームプロジェクト）の開発セッションを開始する。

## 実行ステップ

以下の手順を **すべて順番に** 実行すること:

### 1. CLAUDE.md を読み込む
- `D:/MyWork/GameDevelopment/Godot/Godot_v4.5.1/projects/GameGallery/doc/CLAUDE.md` を Read ツールで読み込み、プロジェクトの規約・アーキテクチャ・コーディング規約を把握する。

### 2. プロジェクト情報を取得
- `mcp__godot__get_project_info` を使って `projectPath: "D:/MyWork/GameDevelopment/Godot/Godot_v4.5.1/projects/GameGallery"` のプロジェクト状態を確認する。

### 3. Git 状態を確認
以下のコマンドを並列で実行:
- `git status` — 未コミットの変更・ブランチ名を把握
- `git log --oneline -5` — 最近のコミット履歴を把握

### 6. 開発準備完了を報告
上記で得た情報をもとに、**日本語で** 以下の内容を簡潔にまとめて表示する:
- プロジェクト名とGodotバージョン
- 現在のブランチと最新コミット
- 未コミットの変更があればその概要
- 「開発準備が完了しました。何を作業しますか？」と尋ねてユーザーの指示を待つ
