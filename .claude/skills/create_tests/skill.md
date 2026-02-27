---
name: create_tests
description: 指定された対象範囲に対して、testing-style.md に準拠した GUT テストを作成する。
user_invocable: true
---

# create_tests スキル

ユーザーが指定した対象（スクリプト、クラス、機能など）に対して GUT テストを作成する。

**プロジェクトルート:** `D:/MyWork/GameDevelopment/Godot/Godot_v4.5.1/projects/GameGallery`（以下 `$ROOT`）

## 実行ステップ

### ステップ 1: テスト規約の読み込み

`$ROOT/doc/guides/testing-style.md` を Read で読み込み、全ルールを把握する。

### ステップ 2: 対象コードの分析

ユーザーが指定した対象の `.gd` ファイルをすべて Read で読み込み、以下を整理する:

- クラスの責務（何をするクラスか）
- public メソッド一覧（テスト対象候補）
- 依存関係（他ノード、Autoload、シグナル、外部リソース）
- 状態を持つ変数（テストで検証すべき状態遷移）

### ステップ 3: テスト計画の提示

テストコードを書く前に、以下の形式でテスト計画をユーザーに提示し、承認を得る:

```
## テスト計画

### 対象: `path/to/target.gd`（クラス名）

### テスト分類: Unit / Integration
（理由: シーンツリー不要のためUnit / ノード操作があるためIntegration）

### テストケース一覧
1. `test_xxx` — 説明
2. `test_yyy` — 説明
3. ...

### 依存の扱い
- `SomeAutoload` → double/stub で切り離す
- `SomeNode` → add_child_autofree で生成
```

ユーザーの承認後、ステップ 4 に進む。

### ステップ 4: テストコードの作成

以下の必須ルールを守ってテストコードを Write で作成する:

#### 配置ルール
- Unit テスト → `$ROOT/test/unit/test_<対象名>.gd`
- Integration テスト → `$ROOT/test/integration/test_<対象名>.gd`
- ファイル名は `test_` で始める（`snake_case.gd`）

#### コード必須ルール

| # | ルール |
|---|--------|
| 1 | `extends GutTest` |
| 2 | テスト関数は `test_` で始める、原則引数なし |
| 3 | 各テストは最低 1 回 `assert_*` / `pending()` / `pass_test()` / `fail_test()` を呼ぶ |
| 4 | Node/Scene 生成時は `autofree()` / `add_child_autofree()` で後始末 |
| 5 | `queue_free()` 使用時は `await wait_seconds()` / `await wait_*_frames()` で解放待ち |
| 6 | 非同期は `await wait_for_signal(signal, timeout)` でハング防止 |
| 7 | Unit テストは外部依存を `double()` / `stub()` で切り離す |
| 8 | 全クラス・全関数・全変数・全処理ブロックに日本語コメントを付ける（coding-style.md 準拠） |
| 9 | 型注釈を付ける |
| 10 | `print()` は使わず `Log` オートロードを使用（テストコード内のデバッグ出力も同様） |

#### テストコードテンプレート

```gdscript
## <対象クラス名> のユニットテスト
extends GutTest

## テスト対象のインスタンス
var _subject: <Type> = null

## 各テスト前にインスタンスを初期化
func before_each() -> void:
    _subject = <Type>.new()
    # ノードが必要な場合: _subject = add_child_autofree(<Type>.new())

## 各テスト後に後始末
func after_each() -> void:
    _subject = null

## <テストの説明>
func test_xxx() -> void:
    # 準備
    ...
    # 実行
    ...
    # 検証
    assert_eq(actual, expected, "説明")
```

### ステップ 5: 既存テストとの整合性確認

テスト作成後、以下を確認する:

1. `$ROOT/test/` 配下の既存テストを Glob で取得
2. 同じ対象のテストファイルが既に存在しないか確認
3. 既に存在する場合は新規作成ではなく既存ファイルに追記/修正する

### ステップ 6: 作成結果の報告

日本語で以下の形式で報告する:

```
## テスト作成結果

### 作成したテストファイル
- `test/unit/test_xxx.gd`
  - `test_aaa` — 説明
  - `test_bbb` — 説明
  - ...

### テスト実行方法

**GUT Panel:**
1. GUT Panel を開く
2. 該当ファイルを選択して Run

**CLI:**
godot -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_xxx.gd -gexit

### 補足
（double/stub の使い方、テスト実行時の注意点など）
```

### 未実装機能のテストについて

対象に未実装の機能がある場合は `pending("未実装: <説明>")` でテストケースを予約し、報告に記載する。
