class_name TestAbility
extends OboroAbility


func _activate(ctx: OboroAbilityCtx) -> void:
	var dmg_ctx := await ctx.wait_pre_damage_received()
	var effect := OboroEffect.new()
	var mod := OboroModifier.create(&"hp", OboroModifier.Operator.ADD, 20.0)
	effect.modifiers.append(mod)
