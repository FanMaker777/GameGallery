## AGENT.md（Codex用）- Godot 4.51 / GameGallery



本ドキュメントは、Codex（AI）が本リポジトリで実装・修正・テスト追加を行う際の**作業規約／手順／品質基準**を定義します。  

**会話・コードコメント・PR説明は必ず日本語**で行ってください。



---



## 0. 絶対ルール（最優先）



- **日本語運用:** 仕様説明、作業サマリ、コミット/PR説明、コードコメントは日本語。

- **最小差分:** 依頼範囲外の変更（ついでリファクタリング、不要な整形、無関係な命名変更）をしない。

- **既存方式を優先:** 画面遷移・状態管理は既存のAutoload（GameManager／遷移エフェクト）に従う。直接 `change_scene_*` を乱用しない。

- **必ず動作確認＋テスト:** 指示がない場合でも、変更後は最低限の手動確認と、必要に応じたGUTテスト追加/更新を行う。



---



## 1. プロジェクト前提



- エンジン: **Godot 4.51**

- 収録形態: 複数ミニゲームを1つのハブ（メインメニュー）から起動する「GameGallery」



---



## 2. 重要パス（確定）



- 起動（メイン）シーン  

&nbsp; `res://root/scenes/boot_splash_scene/boot_splash_scene.tscn`

- ゲーム選択（メインメニュー）シーン  

&nbsp; `res://root/scenes/main_menu_scene/main-menu-scene.tscn`

- ミニゲーム配置ディレクトリ  

&nbsp; `res://root/scenes/game_scene/`

- ユニットテスト（GUT）配置  

&nbsp; `res://test/unit/`

&nbsp; - 命名: `test_****.gd`



---



## 3. アーキテクチャ方針



### 3.1 画面遷移（統一ルール）

- 画面遷移は原則 **GameManager経由**で行う。

- 画面遷移時は原則 遷移エフェクト（フェード等）を挟む。

- 遷移の基本シーケンス例（概念）:

&nbsp; 1) 遷移エフェクトでフェードアウト開始  

&nbsp; 2) フェードアウト完了を待つ  

&nbsp; 3) シーン変更  

&nbsp; 4) `scene_changed` 等で切替完了を待つ  

&nbsp; 5) フェードイン開始



> ミニゲーム側で `get_tree().change_scene_*` を直接呼ぶ必要がある場合でも、まず GameManager に遷移APIを追加して統一する。



### 3.2 Autoload（シングルトン）

- **GameManager:** 画面遷移・ゲーム状態管理の中心。  

&nbsp; - 「メインメニューへ戻る」「指定ゲームシーンを起動」など、共通導線をここに集約する。

- **画面遷移エフェクト（Transition/SceneTransition等）:** フェード・演出担当。  

&nbsp; - `fade_out()` / `fade_in()` と完了シグナルを提供している想定。既存APIに合わせること。

- **OverlayController:** オーバーレイUI(ポーズスクリーンやオプションメニューなど)の操作担当。  

&nbsp; - 「ポーズスクリーンの切り替え」「オプションメニュー表示など、画面をオーバーレイするUIの操作を集約する。

- **SceneNavigator:** 画面遷移の処理担当。  

&nbsp; -画面遷移時の一連の処理を集約する。

- **AudioManager:** ゲーム内のオーディオ操作担当。  

&nbsp; -オーディオの操作と設定の担当。

- **SettingsRepository:** オプション設定の現在値管理と永続化担当。  

&nbsp; -DefaultOptionの定数からデフォルト値を生成し、読込/保存とメモリ上のstateを管理する。



> Autoloadを増やす場合は「責務」を最小にし、AGENTS.mdにも追記する。



---



## 4. ミニゲームの追加・登録ルール



### 4.1 追加場所

- ミニゲームはそれぞれ独自シーンとして `res://root/scenes/game_scene/` 配下に作成する。



推奨構成（例）:

- `res://root/scenes/game_scene/<game_id>/<game_id>.tscn`

- `res://root/scenes/game_scene/<game_id>/<game_id>.gd`

- 必要なら `ui/`, `assets/`, `scripts/` 等を同階層に整理



### 4.2 起動導線（統一）

- メインメニュー（ゲーム選択画面）から起動する。

- 起動処理は **GameManager のAPI** を呼び出す形に統一する。  

&nbsp; 例: `GameManager.start_game(scene_path_or_packed_scene)`



### 4.3 戻る導線（必須）

- すべてのミニゲームは、ユーザーが確実にメインメニューへ戻れる手段を提供する。

&nbsp; - 例: 「戻る」ボタン、ESC入力、ポーズメニューから退出など

- 実装は **GameManagerへ戻すAPI** を使用する。  

&nbsp; 例: `GameManager.load_main_scene()`



### 4.4 登録方式について

- 現状の登録方式（メニューシーン内のカード/ボタンを手動追加、もしくはスクリプトでリスト管理）を**必ず踏襲**する。

- もし一覧が散在して管理が困難になってきた場合は、以下のいずれかで「単一ソース化」を提案して良い（ただし依頼範囲内のみ）:

&nbsp; - Resource（`.tres`）による `MiniGameInfo`

&nbsp; - JSON

&nbsp; - レジストリGDScript



---



## 5. コーディング規約（GDScript）



### 5.1 命名

- 変数/関数: `snake_case`

- 定数: `UPPER_SNAKE_CASE`

- クラス名（`class_name`）: `PascalCase`

- ファイル名: 原則 `snake_case.gd`（既存に合わせる）

- ノード参照: `@onready var xxx: NodeType = %NodeName` を基本（既存流儀優先）



### 5.2 型注釈

- 可能な限り型注釈を付ける（Godot 4.xの静的チェックを活かす）。
  
- 必要に応じてスクリプトにはclass_nameを付与し、型注釈・推論出来るようにする。

- nullの可能性がある参照はガード節で守る。



### 5.3 コメント

- 追加/修正箇所には日本語で簡潔に処理概要をコメント。
- 複雑な処理や意図が読みにくいコードには、 「**“なぜこの実装か”**」かを追加でコメントする。
- 必ず、クラス・メソッド・変数には「##」を用いて対象の役割や処理をコメントする。
- 類似処理が並ぶ場合は、下記のように、ひとまとめのコメントにする。
  ```gdscript
  # 各増減ボタンに音量更新メソッドをコネクト
	_connect_master_buttons()
	_connect_bgm_buttons()
	_connect_effect_buttons()

### 5.4 ログ

- プロジェクトにロガー（例: `Log`）がある場合はそれを優先し、`print()`乱用は避ける。
- 重要またはバグが発生しやすいメソッドの場合、情報を追跡しやすいようにログ出力する。
   ```gdscript
  ## 遷移エフェクト付きで引数のシーンに遷移するメソッド
  func load_scene_with_transition(load_to_scene_path: String) -> void:
	# 遷移先のシーンをパスから生成
	var load_to_scene: PackedScene = load(load_to_scene_path)
	Log.info("func load_scene_with_transition", load_to_scene)

- エラーは握りつぶさず、原因が追える情報を残す。



---



## 6. Git運用



- 基本ブランチ: **main**

- 開発フロー:

&nbsp; 1. `main` からブランチ作成（例: `feature/<topic>` / `fix/<topic>`）

&nbsp; 2. 実装 → テスト → 手動確認

&nbsp; 3. `main` にマージ

- コミットメッセージ: 日本語で簡潔に（1コミット1論点）

&nbsp; - 例: `feat: ゲーム選択カードに新規ミニゲームを追加`

&nbsp; - 例: `fix: メニュー復帰時の遷移不具合を修正`



---



## 7. テスト（GUT）



### 7.1 配置ルール

- `res://test/unit/` 配下

- `test_****.gd` 形式

- UIそのものより、**ロジック層（状態管理／登録リスト／判定処理）**を優先してユニットテストする。

### 7.2 テストメソッド

- `res://test/unit/test_example.gd` に実装されたテストメソッドを参考に実装する。

### 7.3 実行（例）

- エディタのGUT UIから実行、またはCLI実行（環境により差あり）

&nbsp; - 例: `godot -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gdir=res://test/unit -ginclude_subdirs -gexit`



> 実行コマンドはプロジェクトの導入形態により異なるため、既存のREADME/CIがある場合はそれを優先する。



---



## 8. Definition of Done（完了条件）



タスク完了の最低条件:

- 依頼要件を満たす

- 既存機能を壊していない（メニュー表示・起動・戻りの導線が維持される）

- 変更点が最小差分で、意図がコメント/サマリで追える

- 必要に応じてGUTテストを追加/更新し、成功している

- 最低限の手動確認を実施し、サマリに記載している



---



## 9. Codex標準手順（固定）



1. 依頼内容を「目的/変更点/影響範囲」で短く整理

2. 変更対象ファイルを列挙（`.gd`/`.tscn`/テスト）

3. 実装（最小差分、既存方式優先）

4. テスト追加/更新（必要時）

5. 手動確認（最低限）

6. 変更サマリ作成



---



## 10. 変更サマリ（テンプレ）



- 目的:

- 対応内容:

- 変更ファイル:

- 手動確認:

- テスト結果:

- 補足/注意点:

