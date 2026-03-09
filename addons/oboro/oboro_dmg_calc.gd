class_name OboroDmgCalc
extends Resource

@export var target_attr: StringName = &"hp"


func calc(ctx: OboroDmgCtx) -> OboroEffect:
	var dmg_value := _from_dmg_ctx(ctx)
	var dmg_effect := _to_dmg_effect(dmg_value)
	return dmg_effect


## override推奨。ctxからダメージ量（float）を導出する
func _from_dmg_ctx(ctx: OboroDmgCtx) -> float:
	return ctx.damage


## override推奨。ダメージ量からEffectを生成する
func _to_dmg_effect(value: float) -> OboroEffect:
	var effect := OboroEffect.new()
	var mod := OboroModifier.create(target_attr, OboroModifier.Op.SUB, value)
	effect.modifiers.append(mod)
	return effect
