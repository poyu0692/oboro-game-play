class_name OboroEffect
extends Resource

enum Duration {
	INSTANT,
	DURATIONAL,
	PERMANENT,
}

@export var duration_type := Duration.INSTANT
## DURATIONAL のときだけ有効。秒数
@export_range(0.0, 999.0, 0.1, "suffix:s") var duration := 0.0
@export var modifiers: Array[OboroModifier] = []
@export_group("Abilities")
## 適用時にStatesへ付与するAbility群
@export var grants_abilities: Array[OboroAbility] = []
## 適用時にStatesから削除するAbilityのname群
@export var revokes_abilities: Array[String] = []
## 適用時にこのtagカテゴリを持つAbilityを全部削除
@export var revokes_abilities_by_tag: Array[String] = []
@export_group("Condition Tags")
## これらのクエリが全部マッチするときだけ適用可能（完全一致 or prefix一致）
@export var required_tags: Array[String] = []
## これらのクエリのどれかがマッチすれば適用不可
@export var blocking_tags: Array[String] = []
## 適用後も継続的に評価。クエリが一つでもマッチしなくなるとeffectが消える
@export var ongoing_required_tags: Array[String] = []
## 適用後も継続的に評価。クエリのどれかがマッチしたらeffectが消える
@export var ongoing_blocking_tags: Array[String] = []
@export_group("Output Tags")
## 適用時に追加するタグ
@export var provides_tags: Array[String] = []
## 適用時に削除するタグ
@export var removes_tags: Array[String] = []

## ランタイム用。Resourceなのでインスタンスを複製して使うこと
var remaining: float = -1.0
