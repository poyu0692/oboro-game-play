@abstract
class_name OboroAbility
extends Resource

signal ended

## 0.0 でクールダウンなし
@export_range(0.0, 999.0, 0.1, "suffix:s") var cooldown := 0.0
@export var ability_name := &""
## 付与中に State へ追加されるタグ。revokes_abilities_by_tag での照合にも使われる
@export var active_tags: Array[String] = []
@export_group("Conditions")
## これらのクエリが全部マッチするときだけ発動可能（完全一致 or prefix一致）
@export var required_tags: Array[String] = []
## これらのクエリのどれかがマッチすれば発動不可
@export var blocking_tags: Array[String] = []
@export var attr_conditions: Array[OboroAbilityCondition] = []
@export_group("Override")
## クールダウン中につくタグ。空なら "CoolDown." + ability_name を使う
@export var cooldown_tag := &""


func _can_activate(ctx: OboroAbilityCtx) -> bool:
	for req in required_tags:
		if not ctx.state.has_tag(req):
			return false
	for block in blocking_tags:
		if ctx.state.has_tag(block):
			return false
	for cond: OboroAbilityCondition in attr_conditions:
		if not cond.check(ctx.state):
			return false
	var cd_tag := _cd_tag()
	if ctx.state.has_tag(cd_tag):
		return false
	return true


## override しない。cooldown 処理 → _pre_activate → _activate の順に呼ぶテンプレートメソッド
func invoke(ctx: OboroAbilityCtx) -> void:
	if cooldown > 0.0:
		var cd_effect := OboroEffect.new()
		cd_effect.duration_type = OboroEffect.Duration.DURATIONAL
		cd_effect.duration = cooldown
		cd_effect.provides_tags = [_cd_tag()]
		ctx.effects.apply(ctx.state, cd_effect)
	_pre_activate(ctx)
	_activate(ctx)


## _activate の直前に呼ばれる任意フック（リソース消費・演出など）
func _pre_activate(_ctx: OboroAbilityCtx) -> void:
	pass


## サブクラスが override する発動ロジック本体
func _activate(_ctx: OboroAbilityCtx) -> void:
	pass


## 外部から呼ぶ終了メソッド。_deactivate() 後に ended を emit する
func end() -> void:
	_on_deactivate()
	ended.emit()


## サブクラスが override する終了・クリーンアップ処理
func _on_deactivate() -> void:
	pass


# --- private ---
func _cd_tag() -> String:
	if cooldown_tag != &"":
		return cooldown_tag
	return "cooldown." + str(ability_name)
