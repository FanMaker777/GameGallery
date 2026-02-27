# GUT（Godot Unit Test）テスト実装ガイド（Claude Code 向け）

このドキュメントは、Godot のアドオン **GUT（Godot Unit Test）** を使って、GDScript のユニットテスト／インテグレーションテストを実装・実行するための実務ガイドです。  
**Claude Code に「テストコードを生成・修正」させる前提**で、必須ルール、テンプレ、実行方法、よくある落とし穴をまとめています。

---

## 0. 前提（対象バージョン）

- Godot: **4.x**
- GUT: **9.x（Godot 4.x 向け）**

> 参考: GUT の公式ドキュメント（Quick Start / Install / Command Line）  
> - https://gut.readthedocs.io/en/latest/Quick-Start.html   
> - https://gut.readthedocs.io/en/latest/Command-Line.html  

---

### 1. 推奨ディレクトリ構成

テストを規模拡大しても回しやすいよう、**Unit と Integration を分離**します。

```
res://test/
  unit/
  integration/
```

- unit: 純粋関数や小さなクラスのテスト（高速）
- integration: シーン生成、Node ツリー、シグナル、入力など（低速になりがち）

---

## 2. テストスクリプトの基本ルール（必須）

### 2.1 ファイル命名

デフォルトでは **`test_` で始まるファイル**がテストとして検出されます（設定で変更可）。

例:
- `res://test/unit/test_inventory.gd`
- `res://test/integration/test_player_scene.gd`

### 2.2 クラス継承

**必ず `extends GutTest`** します。

```gdscript
extends GutTest
```

### 2.3 テストメソッド命名（最重要）

**`test_` で始まるメソッドだけがテストとして実行されます。**  
原則、テストメソッドは **引数なし**（例外: パラメタライズドテスト）。

```gdscript
func test_when_hp_is_zero_player_is_dead() -> void:
    assert_true(true) # 例
```

### 2.4 “Risky” を避ける

各テストは最低 1 回は以下のいずれかを呼びます（呼ばないと “risky” 扱いになりがち）。

- `assert_*`
- `pending()`
- `pass_test()`
- `fail_test()`

---

## 3. ライフサイクル（セットアップ／後始末）

テスト前後に共通処理を入れたい場合は、以下の仮想メソッドを実装します（引数なし）。

- `before_all()` : このスクリプト内のテスト開始前に 1 回
- `before_each()` : 各テストの直前
- `after_each()` : 各テストの直後
- `after_all()` : 全テスト終了後に 1 回

```gdscript
extends GutTest

var _subject := null

func before_all() -> void:
    # 1回だけの準備
    pass

func before_each() -> void:
    # 各テストごとに初期化
    _subject = {"hp": 10}

func after_each() -> void:
    # 後始末（必要なら）
    _subject = null

func after_all() -> void:
    # 1回だけの後始末
    pass
```

---

## 4. 最小テンプレ（コピペ用）

`res://test/unit/test_example.gd`

```gdscript
extends GutTest

func test_passes() -> void:
    assert_eq(1, 1)

func test_fails() -> void:
    assert_eq("hello", "goodbye")
```

---

## 5. よく使うアサーション（例）

> アサーションは大量にあります。まずは頻出だけ覚え、必要に応じて追加してください。

```gdscript
func test_basic_asserts() -> void:
    assert_true(1 < 2, "1 < 2 should be true")
    assert_false(2 < 1, "2 < 1 should be false")
    assert_eq("a", "a")
    assert_ne("a", "b")
```

### 5.1 明示的に pass/fail/pending

```gdscript
func test_not_implemented_yet() -> void:
    pending("まだ未実装")

func test_force_pass() -> void:
    pass_test("意味のある assert が不要なケース")

func test_force_fail() -> void:
    fail_test("強制的に失敗させたい")
```

---

## 6. ノード／シーンを扱うテスト（重要）

### 6.1 メモリリーク・オーファンを避ける

- `autofree(obj)` / `autoqfree(obj)` でテスト終了後に自動解放  
- ツリーに add_child するなら `add_child_autofree(node)` / `add_child_autoqfree(node)` が便利

```gdscript
extends GutTest

func test_node_lifecycle() -> void:
    var node := add_child_autofree(Node2D.new())
    assert_not_null(node)
```

### 6.2 Orphan の検出

```gdscript
func test_no_orphans() -> void:
    var node := Node.new()
    assert_no_new_orphans("この時点では orphan が増える（例）")
    node.free()
    assert_no_new_orphans("free 後は orphan 増加なし（例）")
```

`queue_free()` の場合は、実際に解放されるまでフレーム待ちが必要です。

```gdscript
func test_queue_free_needs_wait() -> void:
    var node := Node.new()
    node.queue_free()
    assert_no_new_orphans("queue_free 直後はまだ残ることがある")
    await wait_seconds(0.1)
    assert_no_new_orphans("少し待てば解放される")
```

---

## 7. await / 非同期テスト（フレーム・シグナル待ち）

GUT はテスト内で `await` をサポートします。  
「シグナルが飛ぶまで待つ」「フレームを進める」などができます。

### 7.1 時間を待つ

```gdscript
await wait_seconds(0.5)
```

### 7.2 シグナルを待つ（タイムアウト付きでハング防止）

```gdscript
var obj = load("res://some_obj.gd").new()
await wait_for_signal(obj.some_signal, 3) # 3秒でタイムアウト
```

### 7.3 フレームを待つ（フレーム1はフレイキーになりがち）

- `wait_physics_frames(n)`
- `wait_process_frames(n)`

```gdscript
await wait_physics_frames(2)
await wait_process_frames(2)
```

---

## 8. Doubles / Stubs / Spies（依存を切る）

「外部依存（セーブ、通信、乱数、入力、シングルトン）を切って、テスト対象を孤立化」するための機能です。

### 8.1 double は “ロードされたクラス/シーン” を返す（インスタンスではない）

```gdscript
var Foo = load("res://foo.gd")
var MyScene = load("res://my_scene.tscn")

var double_foo = double(Foo).new()
var double_scene = double(MyScene).instantiate()
```

### 8.2 スタブ（戻り値差し替えなど）

```gdscript
var double_foo = double(Foo).new()

stub(double_foo.bar).to_return(42)
stub(double_foo, "something").to_call_super()
stub(double_foo.other_thing).to_return(77).when_passed(1, 2, "c")
stub(double_foo.other_thing.bind(4, 5, "z")).to_do_nothing()
```

### 8.3 スパイ（呼ばれたか／回数／引数）

```gdscript
assert_called(double_foo, "bar")
assert_not_called(double_foo, "something")
assert_call_count(double_foo, "call_me", 10)

assert_called(double_foo, "other_thing", [1, 2, "c"])

var last_params = get_call_parameters(double_foo, "call_me")
var params_4th = get_call_parameters(double_foo, "call_me", 4)
```

---

## 9. Parameterized Tests（表駆動テスト）

「同じテストを複数の入力で回す」ための仕組みです。

ルール:
- テストは **パラメータ 1 個だけ**
- そのパラメータのデフォルト値を `use_parameters(...)` にする
- `use_parameters` には配列を渡す（要素ごとにテストが走る）

```gdscript
var test_params = [[1, 2, 3], [4, 5, 6]]

func test_with_parameters(p = use_parameters(test_params)) -> void:
    assert_eq(p[0], p[2] - p[1])
```

---

## 10. 実行方法（エディタ／CLI）

### 10.1 エディタ（GUT Panel）

1. **GUT Panel を開く**
2. Settings で `res://test/unit`（必要なら `res://test/integration` も）を登録
3. **Run All** で全実行
4. エディタでテストスクリプトを開くと「スクリプト単位」「関数単位」で実行も可能

### 10.2 コマンドライン（CI で重要）

基本形（プロジェクトルートで実行）:

```bash
godot -d -s --path "$PWD" addons/gut/gut_cmdln.gd
```

- 終了コード: 全テスト成功なら `0`、失敗があれば `1`
- `pending` は終了コードに影響しない

#### 10.2.1 よく使うオプション例

- ディレクトリ指定: `-gdir=res://test/unit`
- サブディレクトリも対象: `-ginclude_subdirs`
- 個別ファイル指定: `-gtest=res://test/unit/test_inventory.gd`
- 終了: `-gexit`
- JUnit XML 出力: `-gjunit_xml_file=path/to/report.xml`

例（ユニットだけ回して、終わったら終了、JUnit 出力）:

```bash
godot -d -s --path "$PWD" addons/gut/gut_cmdln.gd \
  -gdir=res://test/unit -ginclude_subdirs -gexit \
  -gjunit_xml_file=./test-results/gut-junit.xml
```

#### 10.2.2 `.gutconfig.json` で引数を省略する

デフォルトで `res://.gutconfig.json` を読みます。  
CLI 引数は gutconfig より優先されます（default < gutconfig < CLI）。

サンプルを出力:
```bash
godot -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gprint_gutconfig_sample
```

---

## 11. 重要な注意点（落とし穴）

### 11.1 `--script` ではなく `-s` を使う

GUT の CLI 実行例では `-s` が基本です。GUT のオプションパーサの都合で、`--script` が通らないケースが報告されています。  
CLI 実行時は **`godot -s addons/gut/gut_cmdln.gd`** を優先してください。

---

## 12. Claude Code に渡す「コーディング指示」テンプレ

以下を Claude Code のプロンプト先頭に貼り付けると、期待通りのテストを書かせやすくなります。

```text
あなたは Godot 4.x のプロジェクトに GUT（Godot Unit Test）でテストを追加します。
必ず守ること:
- テストファイルは res://test/unit または res://test/integration に置く
- ファイル名は test_*.gd（デフォルト設定）
- スクリプトは必ず extends GutTest
- テスト関数は test_ で開始し、原則引数なし（Parameterized Tests を除く）
- 各テストは必ず assert_* / pending / pass_test / fail_test のいずれかを呼ぶ
- Node や Scene を生成したら autofree/autoqfree/add_child_autofree を使って後始末する
- queue_free を使うなら await wait_seconds / wait_*frames で解放を待つ
- 非同期は wait_for_signal(signal, timeout) を優先してハングを防ぐ
- Unit と Integration は分け、Unit は外部依存を double/stub で切る
出力:
- 追加/変更するファイルパス一覧
- 各ファイルの全文コード（GDScript）
- 実行方法（GUT Panel / CLI コマンド例）
```

---

## 13. 実装チェックリスト

- [ ] `extends GutTest` になっている
- [ ] ファイル名が `test_` で始まる（または GUT 設定で prefix を変更済み）
- [ ] テスト関数名が `test_...` で始まる
- [ ] テスト関数が原則引数なし（Parameterized Tests は 1 引数 + `use_parameters`）
- [ ] 各テストが最低 1 回 assert/pending/pass/fail を実行している
- [ ] Node/Scene を作ったら `autofree` / `add_child_autofree` 等で後始末している
- [ ] `queue_free()` の場合は `await` で解放を待っている
- [ ] 非同期は `wait_for_signal(..., timeout)` でハングを防いでいる
- [ ] unit / integration を意識して配置・命名している
- [ ] CLI 実行は `-s` を使っている（`--script` は避ける）

---

## 参考リンク

- Quick Start: https://gut.readthedocs.io/en/latest/Quick-Start.html
- Command Line: https://gut.readthedocs.io/en/latest/Command-Line.html
- GUT GitHub: https://github.com/bitwes/Gut
