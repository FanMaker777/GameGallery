## 実績1件の定義データ（Inspector 編集可能な Custom Resource）
class_name AchievementDefinition
extends Resource

enum Category { COMBAT, FARMING, EXPLORATION, SOCIAL, SYSTEM }
enum Rank { BRONZE, SILVER, GOLD }
enum Type { ONE_SHOT, COUNTER, CHALLENGE }

@export var id: StringName = &""
@export var name_ja: String = ""
@export var description_ja: String = ""
@export var category: Category = Category.COMBAT
@export var rank: Rank = Rank.BRONZE
@export var ap: int = 1
@export var type: Type = Type.ONE_SHOT

@export_group("トリガー条件")
@export var trigger_action: StringName = &""
@export var target_count: int = 1
@export var reset_on: StringName = &""       # challenge のみ
@export var unique_instances: bool = false    # true → 同一 instance_id は重複カウントしない
