## 報酬ノード1件の定義データ（Inspector 編集可能な Custom Resource）
class_name RewardDefinition
extends Resource

## 報酬カテゴリ
enum Category { GLOBAL_QOL, COMBAT, FARMING, EXPLORATION }

## 効果の種類
enum EffectType {
	## グローバルQoL
	PIN_SLOT_PLUS_1,      ## ピン留め枠を+1拡張
	DIVERSITY_BONUS,      ## 多様性ボーナス有効化
	## 戦闘
	HP_PERCENT_UP,        ## 最大HP +N%
	ATTACK_PERCENT_UP,    ## 攻撃力 +N%
	AUTO_COLLECT,         ## ドロップ自動回収範囲拡大
	RESPAWN_TIME_DOWN,    ## 死亡復帰時間短縮 N%
	STAMINA_MAX_UP,       ## スタミナ最大値 +N%
	STAMINA_RECOVERY_UP,  ## スタミナ回復速度 +N%
	## 農業/クラフト
	HARVEST_BONUS,        ## 収穫量 +N%
	GATHER_SPEED_UP,      ## 採取速度 +N%
	## 探索/交流
	MOVE_SPEED_UP,        ## 移動速度 +N%
	MINIMAP,              ## ミニマップ表示
	FAST_TRAVEL,          ## ファストトラベル解放
	SHOP_DISCOUNT,        ## 店割引 N%
}

## 報酬の一意識別子
@export var id: StringName = &""
## 表示名（日本語）
@export var name_ja: String = ""
## 説明文（日本語）
@export var description_ja: String = ""
## 所属カテゴリ
@export var category: Category = Category.GLOBAL_QOL
## 解放に必要なAPコスト
@export var ap_cost: int = 5
## 効果の種類
@export var effect_type: EffectType = EffectType.HP_PERCENT_UP
## 効果の数値パラメータ（%値やフラグ用の1.0など）
@export var effect_value: float = 0.0

@export_group("前提条件")
## 解放に必要な前提ノードID（すべて解放済みである必要がある）
@export var prerequisites: Array[StringName] = []
