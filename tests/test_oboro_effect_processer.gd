extends GdUnitTestSuite


func _make_states_with_hp(base_hp: float = 50.0) -> OboroStates:
	var states := OboroStates.new()
	var hp_min := OboroAttrDef.new()
	hp_min.attr_name = &"hp_min"
	hp_min.base_value = 0.0
	var hp_max := OboroAttrDef.new()
	hp_max.attr_name = &"hp_max"
	hp_max.base_value = 100.0
	var hp := OboroAttrDef.new()
	hp.attr_name = &"hp"
	hp.base_value = base_hp
	hp.clamp_min = &"hp_min"
	hp.clamp_max = &"hp_max"
	states.init_attrs([hp_min, hp_max, hp])
	return states


# --- 条件チェック ---

func test_apply_fails_when_required_tag_missing() -> void:
	var states := OboroStates.new()
	var processer := OboroEffectProcesser.new()

	var effect := OboroEffect.new()
	effect.required_tags = ["enraged"]

	var result := processer.apply(states, effect)

	assert_bool(result).is_false()
	assert_int(states.effects.size()).is_equal(0)


func test_apply_succeeds_when_required_tag_present() -> void:
	var states := OboroStates.new()
	states.add_tag("enraged")
	var processer := OboroEffectProcesser.new()

	var effect := OboroEffect.new()
	effect.duration_type = OboroEffect.Duration.PERMANENT
	effect.required_tags = ["enraged"]

	var result := processer.apply(states, effect)

	assert_bool(result).is_true()


func test_apply_fails_when_blocking_tag_present() -> void:
	var states := OboroStates.new()
	states.add_tag("immune")
	var processer := OboroEffectProcesser.new()

	var effect := OboroEffect.new()
	effect.blocking_tags = ["immune"]

	var result := processer.apply(states, effect)

	assert_bool(result).is_false()


# --- INSTANT ---

func test_instant_applies_value_directly() -> void:
	var states := _make_states_with_hp()
	var processer := OboroEffectProcesser.new()

	var effect := OboroEffect.new()
	effect.duration_type = OboroEffect.Duration.INSTANT
	effect.modifiers.append(OboroModifier.create(&"hp", OboroModifier.Op.SUB, 20.0))
	processer.apply(states, effect)

	assert_float(states.get_attr(&"hp").value).is_equal(30.0)
	# INSTANT は effects リストに残らない
	assert_int(states.effects.size()).is_equal(0)


func test_instant_clamps_to_min() -> void:
	var states := _make_states_with_hp(50.0)
	var processer := OboroEffectProcesser.new()

	var effect := OboroEffect.new()
	effect.duration_type = OboroEffect.Duration.INSTANT
	effect.modifiers.append(OboroModifier.create(&"hp", OboroModifier.Op.SUB, 9999.0))
	processer.apply(states, effect)

	# hp_min = 0 なのでマイナスにならない
	assert_float(states.get_attr(&"hp").value).is_equal(0.0)


# --- DURATIONAL ---

func test_durational_added_to_effects_with_remaining() -> void:
	var states := OboroStates.new()
	var processer := OboroEffectProcesser.new()

	var effect := OboroEffect.new()
	effect.duration_type = OboroEffect.Duration.DURATIONAL
	effect.duration = 5.0
	processer.apply(states, effect)

	assert_int(states.effects.size()).is_equal(1)
	assert_float(states.effects[0].remaining).is_equal(5.0)


func test_durational_duplicates_resource() -> void:
	var states := OboroStates.new()
	var processer := OboroEffectProcesser.new()

	var effect := OboroEffect.new()
	effect.duration_type = OboroEffect.Duration.DURATIONAL
	effect.duration = 3.0
	processer.apply(states, effect)

	# 適用されたインスタンスは元の Resource とは別物
	assert_bool(states.effects[0] != effect).is_true()


func test_durational_expires_on_tick() -> void:
	var states := OboroStates.new()
	var processer := OboroEffectProcesser.new()

	var effect := OboroEffect.new()
	effect.duration_type = OboroEffect.Duration.DURATIONAL
	effect.duration = 1.0
	processer.apply(states, effect)
	assert_int(states.effects.size()).is_equal(1)

	states.tick(1.0)

	assert_int(states.effects.size()).is_equal(0)


func test_durational_not_expired_before_time() -> void:
	var states := OboroStates.new()
	var processer := OboroEffectProcesser.new()

	var effect := OboroEffect.new()
	effect.duration_type = OboroEffect.Duration.DURATIONAL
	effect.duration = 2.0
	processer.apply(states, effect)

	states.tick(1.0)

	assert_int(states.effects.size()).is_equal(1)


# --- PERMANENT ---

func test_permanent_persists_after_tick() -> void:
	var states := OboroStates.new()
	var processer := OboroEffectProcesser.new()

	var effect := OboroEffect.new()
	effect.duration_type = OboroEffect.Duration.PERMANENT
	processer.apply(states, effect)

	states.tick(9999.0)

	assert_int(states.effects.size()).is_equal(1)


# --- タグ付与・削除 ---

func test_apply_adds_provides_tags() -> void:
	var states := OboroStates.new()
	var processer := OboroEffectProcesser.new()

	var effect := OboroEffect.new()
	effect.duration_type = OboroEffect.Duration.PERMANENT
	effect.provides_tags = ["on_fire"]
	processer.apply(states, effect)

	assert_bool(states.has_tag("on_fire")).is_true()


func test_remove_effect_removes_its_tags() -> void:
	var states := OboroStates.new()
	var processer := OboroEffectProcesser.new()

	var effect := OboroEffect.new()
	effect.duration_type = OboroEffect.Duration.PERMANENT
	effect.provides_tags = ["on_fire"]
	processer.apply(states, effect)

	states.remove(states.effects[0])

	assert_bool(states.has_tag("on_fire")).is_false()
