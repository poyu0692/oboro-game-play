extends GdUnitTestSuite


func test_calc_returns_sub_effect_on_target_attr() -> void:
	var calc := OboroDmgCalc.new()
	calc.target_attr = &"hp"
	var ctx := OboroDmgCtx.new()
	ctx.damage = 50.0

	var effect := calc.calc(ctx)

	assert_int(effect.modifiers.size()).is_equal(1)
	var mod: OboroModifier = effect.modifiers[0]
	assert_bool(mod.target_attr == &"hp").is_true()
	assert_int(mod.op).is_equal(OboroModifier.Op.SUB)
	assert_float(mod.value).is_equal(50.0)


func test_from_dmg_ctx_returns_ctx_damage() -> void:
	var calc := OboroDmgCalc.new()
	var ctx := OboroDmgCtx.new()
	ctx.damage = 77.0

	assert_float(calc._from_dmg_ctx(ctx)).is_equal(77.0)


func test_zero_damage_produces_zero_modifier() -> void:
	var calc := OboroDmgCalc.new()
	var ctx := OboroDmgCtx.new()
	ctx.damage = 0.0

	var effect := calc.calc(ctx)

	assert_float(effect.modifiers[0].value).is_equal(0.0)


func test_custom_target_attr_used_in_modifier() -> void:
	var calc := OboroDmgCalc.new()
	calc.target_attr = &"shield"
	var ctx := OboroDmgCtx.new()
	ctx.damage = 10.0

	var effect := calc.calc(ctx)

	assert_bool(effect.modifiers[0].target_attr == &"shield").is_true()
