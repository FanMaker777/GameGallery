# CLAUDE.md — GameGallery（Godot 4.5.1）

本ドキュメントは、Claude Code が本リポジトリで作業する際の **規約・手順・品質基準** を定義する。
**会話・コードコメント・PR説明・コミットメッセージは必ず日本語** で行うこと。

---

## 1. 絶対ルール（最優先）

- **日本語運用:** 仕様説明、作業サマリ、コミット/PR説明、コードコメントは日本語。
- **最小差分:** 依頼範囲外の変更（ついでリファクタリング、不要な整形、無関係な命名変更）をしない。
- **必ず動作確認＋テスト:** 変更後は MCP サーバー経由で実際に Godot を実行して動作確認し、必要に応じて GUT テストを追加/更新する。
- **MCP サーバーを積極活用:** シーン作成・ノード追加・実行テスト・デバッグ出力確認など、MCP ツールで実行可能な操作は手動ファイル編集より MCP を優先する。
- **Skills を積極活用:** コーディング時は利用可能な Skills（`godot-expert` 等）を積極的に呼び出し、専門知識やベストプラクティスを活用すること。
- **読み取り許可ディレクトリの制限:**  
  コード調査等で読み取りするディレクトリは **以下の2つおよびその配下のみ** に限定する。
  この2ディレクトリに限り、読み取り（Read / Glob / Grep）およびコマンド使用の承認は不要。  
  **下記以外のディレクトリを読み取る場合は、理由を説明した上でユーザーの承認を得ること。**    
  1. プロジェクト(GameGallery)のソースフォルダ
      `D:\MyWork\GameDevelopment\Godot\Godot_v4.5.1\projects\GameGallery`
  2. Claude Codeの設定(このディレクトリでプロジェクトのソース探索は禁止)
      `C:/Users/myoso/.claude`

---

## 2. doc/ ドキュメント見取り図

```
doc/
├── CLAUDE.md                    … 本ファイル（常時読み込み済み）
├── README.md                    … doc/ 全体の案内
├── architecture/
│   ├── overview.md              … プロジェクト構造・Autoload・ミニゲーム一覧
│   └── decisions.md             … 設計判断の記録（ADR）
├── guides/
│   ├── coding-style.md          … GDScript コーディング規約
│   └── testing-style.md         … GUT テスト規約
├── spec/
│   └── AchievementMaster_ClaudeCode_Spec.md … Achievement Master 詳細仕様
├── tasks/
│   └── *.md                     … 残作業・TODO（タスクごとに1ファイル）
└── research/
    └── README.md                … 調査メモの案内
```

**ドキュメント読み込み指示:** 本ファイル（CLAUDE.md）は常時コンテキストに含まれる。
上記の各ドキュメントは作業内容に応じて **必要なものを Read で読み込む** こと:

| 作業内容 | 読むドキュメント |
|----------|------------------|
| 実装・設計作業 | `architecture/overview.md` — 構造・Autoload・ミニゲーム一覧 |
| 設計判断が必要な場面 | `architecture/decisions.md` — 過去の ADR |
| コーディング | `guides/coding-style.md` — GDScript 規約 |
| テスト追加・修正 | `guides/testing-style.md` — GUT テスト規約 |
| Achievement Master 関連 | `spec/AchievementMaster_ClaudeCode_Spec.md` — 仕様・実装状況 |
| 作業開始時 | `tasks/*.md` — 未完了の残作業を確認 |

### tasks/ の運用ルール

残作業が発生した場合、`doc/tasks/` にマークダウンファイルとして記録する。

- **ファイル名:** 内容がわかる短い名前（例: `fix-menu-transition.md`, `add-score-saving.md`）
- **記載内容:** 何を・なぜ・どこを変更すべきかを簡潔に書く
- **完了時:** タスクが完了したらファイルを削除する
- **作業開始時:** `tasks/` 配下を確認し、関連する残作業があれば先に対応を検討する

---

## 3. MCP サーバーの活用

本プロジェクトには複数の MCP サーバーが設定されている。**積極的に活用すること。**

### 3.1 Godot MCP（`mcp__godot__*`）

シーン操作・プロジェクト実行に使用する。**ファイルを手動で .tscn 編集するより MCP を優先する。**

| ツール | 用途 | 使用タイミング |
|--------|------|----------------|
| `run_project` | シーンを実行して動作確認 | 実装完了後の検証時。`scene` パラメータで特定シーンを指定可能 |
| `get_debug_output` | 実行中のコンソール出力・エラー取得 | `run_project` 後にエラー・警告を確認 |
| `stop_project` | 実行中のプロジェクトを停止 | デバッグ完了時 |
| `create_scene` | 新規シーンファイル作成 | 新しいシーンが必要な時 |
| `add_node` | 既存シーンにノード追加 | シーンツリーの構築時 |
| `load_sprite` | Sprite2D にテクスチャ読込 | スプライト設定時 |
| `save_scene` | シーンの保存 | シーン変更後の永続化 |
| `get_project_info` | プロジェクト情報取得 | 構造把握時 |
| `get_uid` | ファイルの UID 取得 | リソース参照時 |
| `update_project_uids` | UID 参照の更新 | リソース追加/移動後 |
| `launch_editor` | Godot エディタ起動 | ユーザーの要望時 |

**プロジェクトパス:** `D:/MyWork/GameDevelopment/Godot/Godot_v4.5.1/projects/GameGallery`

### 3.2 実行テストの標準手順

```
1) mcp__godot__run_project でシーンを実行
2) mcp__godot__get_debug_output でエラー・ログを確認
3) 問題があればコードを修正して再実行
4) mcp__godot__stop_project で停止
```

### 3.3 その他の MCP サーバー

| サーバー | 用途 |
|----------|------|
| `gdscript` | GDScript 関連の補助 |
| `godot_docs` | Godot 公式ドキュメント参照 |
| `context7` | ライブラリドキュメント参照 |

---

## 4. 作業手順

### 4.1 標準フロー

1. 依頼内容を「目的/変更点/影響範囲」で短く整理
2. 変更対象ファイルを列挙（`.gd` / `.tscn` / テスト）
3. 実装（最小差分、既存方式優先）
4. **MCP で Godot 実行** → デバッグ出力確認 → 問題修正
5. テスト追加/更新（必要時）
6. 変更サマリ作成

### 4.2 Git 運用

- 基本ブランチ: `main`
- 開発フロー: `main` → ブランチ作成 → 実装 → テスト → 手動確認 → マージ
- コミットメッセージ: 日本語で簡潔に（1コミット1論点）
  - 例: `feat: ゲーム選択カードに新規ミニゲームを追加`
  - 例: `fix: メニュー復帰時の遷移不具合を修正`

### 4.3 変更サマリ（テンプレ）

```
- 目的:
- 対応内容:
- 変更ファイル:(作成・変更・削除したファイルを表形式で一覧表示する)
- MCP 実行確認: （実行シーン、エラー有無）
- テスト結果:
- 補足/注意点:
```
