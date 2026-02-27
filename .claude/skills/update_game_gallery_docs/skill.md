---
name: update_game_gallery_docs
description: GameGallery プロジェクトの現在の状態を分析し、doc/ 配下の全ドキュメントを最新の実態に合わせて更新する。
user_invocable: true
---

# update_game_gallery_docs スキル

GameGallery プロジェクトの現在の状態（スクリプト、シーン、Autoload、ディレクトリ構造、実装進捗など）を自動分析し、doc/ 配下の各ドキュメントを最新状態に更新する。

**プロジェクトルート:** `D:/MyWork/GameDevelopment/Godot/Godot_v4.5.1/projects/GameGallery`（以下 `$ROOT`）

## 注意事項

- **最小差分原則:** ドキュメントの文体・構造を維持し、実態と乖離している部分のみ更新する。不要な書き換えはしない。
- **日本語:** すべての記述・報告は日本語で行う。
- **新規ファイル禁止:** doc/ 配下に新しいサブディレクトリやファイルが必要な場合は作成を提案するのみ（勝手に作成しない）。
- **規約文書の保護:** `guides/coding-style.md` と `guides/testing-style.md` は規約文書のため、コードベースの変化だけでは更新しない（規約自体が変わった場合のみ更新）。

## 実行ステップ

### ステップ 1: プロジェクト状態の収集（並列実行）

以下を **すべて並列で** 収集する:

1. `$ROOT/project.godot` を Read → Autoload 一覧、入力マッピング（`[input]`）、物理レイヤー（`[layer_names]`）を抽出
2. `.gd` ファイル一覧を Glob で取得（パターン: `$ROOT/**/*.gd`）
3. `.tscn` ファイル一覧を Glob で取得（パターン: `$ROOT/**/*.tscn`）
4. ディレクトリ構造を取得（Bash: `ls -R "$ROOT" | head -100` で2階層程度）
5. 最近の変更履歴を取得（Bash: `cd "$ROOT" && git log --oneline -10`）
6. テストファイル一覧を Glob で取得（パターン: `$ROOT/test/**/*`）

### ステップ 2: 既存ドキュメントの読み込み（並列実行）

doc/ 配下の全 12 ファイルを **すべて並列で** Read する:

- `$ROOT/doc/CLAUDE.md`
- `$ROOT/doc/AGENTS.md`
- `$ROOT/doc/README.md`
- `$ROOT/doc/architecture/overview.md`
- `$ROOT/doc/architecture/decisions.md`
- `$ROOT/doc/architecture/README.md`
- `$ROOT/doc/guides/coding-style.md`
- `$ROOT/doc/guides/testing-style.md`
- `$ROOT/doc/guides/README.md`
- `$ROOT/doc/spec/AchievementMaster_ClaudeCode_Spec.md`
- `$ROOT/doc/spec/README.md`
- `$ROOT/doc/research/README.md`

### ステップ 3: 差分分析

ステップ 1 で収集した実態と、ステップ 2 のドキュメント内容を比較し、以下の乖離を特定する:

- **Autoload:** 追加/削除/変更されたもの
- **ミニゲーム:** 追加/削除されたミニゲーム（games/ 配下の変化）
- **ディレクトリ構造:** 新規/削除されたディレクトリ
- **スクリプト/シーン:** 追加/削除された `.gd` / `.tscn` ファイル
- **物理レイヤー/入力マッピング:** 変更の有無
- **実装進捗:** Achievement Master spec における実装済み/未実装の変化
- **テストファイル:** 追加/削除/変更されたテスト

各ドキュメントごとに「更新が必要かどうか」と「具体的な更新箇所」を判定する。

### ステップ 4: 各ドキュメントの更新

差分分析の結果に基づき、更新が必要なドキュメントのみ Edit ツールで更新する。

| ドキュメント | 更新項目 |
|---|---|
| `architecture/overview.md` | ディレクトリ構造、Autoload 一覧、ミニゲーム一覧、物理レイヤー、入力マッピング |
| `spec/AchievementMaster_ClaudeCode_Spec.md` | 実装状況セクション（実装済み/未実装の機能リスト、最新コミット履歴） |
| `CLAUDE.md` | Autoload 変更があれば反映、MCP ツール情報の更新 |
| `AGENTS.md` | プロジェクト構造・Autoload・重要パスの更新 |
| `guides/coding-style.md` | 規約自体が変わった場合のみ更新（通常は変更なし） |
| `guides/testing-style.md` | 規約自体が変わった場合のみ更新（通常は変更なし） |
| 各 `README.md` | 配下のファイル一覧が変わっていれば更新 |

**更新時の原則:**
- Edit ツールを使い、変更箇所のみピンポイントで書き換える
- ドキュメント全体の文体・フォーマットを崩さない
- 事実に基づく更新のみ行い、推測で内容を追加しない

### ステップ 5: 更新内容の報告

最後に、日本語で以下の形式で報告する:

```
## ドキュメント更新結果

### 更新したドキュメント
- `doc/xxx.md` — （変更概要）
- `doc/yyy.md` — （変更概要）

### 変更なしのドキュメント
- `doc/zzz.md`
- ...

### 備考
（新規ファイルの提案など、必要に応じて）
```

### ステップ 6: 変更なしの場合

分析の結果、すべてのドキュメントが最新の状態であれば:

```
## ドキュメント更新結果

全ドキュメントは最新の状態です。変更は不要でした。
```

と報告して終了する。
