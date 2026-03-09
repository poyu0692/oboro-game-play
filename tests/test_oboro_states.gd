extends GdUnitTestSuite


func _make_states_with_hp(base_hp: float = 100.0) -> OboroStates:
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


# --- タグ管理 ---

func test_has_tag_exact_match() -> void:
	var states := OboroStates.new()
	states.add_tag("status.burning")
	assert_bool(states.has_tag("status.burning")).is_true()


func test_has_tag_prefix_match() -> void:
	var states := OboroStates.new()
	states.add_tag("status.burning")
	assert_bool(states.has_tag("status")).is_true()


func test_has_tag_no_false_positive() -> void:
	# "stat" は "status.burning" にマッチしてはいけない
	var states := OboroStates.new()
	states.add_tag("status.burning")
	assert_bool(states.has_tag("stat")).is_false()


func test_add_tag_emits_signal() -> void:
	var states := OboroStates.new()
	var emitted: Array[String] = []
	states.tag_added.connect(func(t: String) -> void: emitted.append(t))

	states.add_tag("test_tag")

	assert_int(emitted.size()).is_equal(1)
	assert_str(emitted[0]).is_equal("test_tag")


func test_remove_tag_emits_signal() -> void:
	var states := OboroStates.new()
	states.add_tag("test_tag")
	var emitted: Array[String] = []
	states.tag_removed.connect(func(t: String) -> void: emitted.append(t))

	states.remove_tag("test_tag")

	assert_int(emitted.size()).is_equal(1)
	assert_str(emitted[0]).is_equal("test_tag")


func test_add_tag_duplicate_ignored() -> void:
	var states := OboroStates.new()
	states.add_tag("buff")
	states.add_tag("buff")
	assert_int(states.tags.size()).is_equal(1)


# --- 属性再計算 ---

func test_durational_effect_modifier_reflected_in_attr() -> void:
	var states := _make_states_with_hp()
	var processer := OboroEffectProcesser.new()

	var effect := OboroEffect.new()
	effect.duration_type = OboroEffect.Duration.DURATIONAL
	effect.duration = 5.0
	effect.modifiers.append(OboroModifier.create(&"hp", OboroModifier.Op.SUB, 30.0))
	processer.apply(states, effect)

	assert_float(states.get_attr(&"hp").value).is_equal(70.0)


func test_clamp_max_prevents_overflow() -> void:
	var states := _make_states_with_hp()
	var processer := OboroEffectProcesser.new()

	var effect := OboroEffect.new()
	effect.duration_type = OboroEffect.Duration.DURATIONAL
	effect.duration = 5.0
	effect.modifiers.append(OboroModifier.create(&"hp", OboroModifier.Op.ADD, 50.0))
	processer.apply(states, effect)

	# hp_max = 100 なので 100 を超えない
	assert_float(states.get_attr(&"hp").value).is_equal(100.0)


func test_attr_recalculates_after_effect_removed() -> void:
	var states := _make_states_with_hp()
	var processer := OboroEffectProcesser.new()

	var effect := OboroEffect.new()
	effect.duration_type = OboroEffect.Duration.PERMANENT
	effect.modifiers.append(OboroModifier.create(&"hp", OboroModifier.Op.SUB, 40.0))
	processer.apply(states, effect)
	assert_float(states.get_attr(&"hp").value).is_equal(60.0)

	states.remove(states.effects[0])
	assert_float(states.get_attr(&"hp").value).is_equal(100.0)


# --- カスケード削除 ---

func test_ongoing_required_tag_removed_triggers_effect_removal() -> void:
	var states := OboroStates.new()
	var processer := OboroEffectProcesser.new()

	var effect := OboroEffect.new()
	effect.duration_type = OboroEffect.Duration.PERMANENT
	effect.ongoing_required_tags = ["buff"]
	processer.apply(states, effect)
	states.add_tag("buff")
	assert_int(states.effects.size()).is_equal(1)

	states.remove_tag("buff")
	assert_int(states.effects.size()).is_equal(0)


func test_ongoing_blocking_tag_added_triggers_effect_removal() -> void:
	var states := OboroStates.new()
	var processer := OboroEffectProcesser.new()

	var effect := OboroEffect.new()
	effect.duration_type = OboroEffect.Duration.PERMANENT
	effect.ongoing_blocking_tags = ["silenced"]
	processer.apply(states, effect)
	assert_int(states.effects.size()).is_equal(1)

	states.add_tag("silenced")
	assert_int(states.effects.size()).is_equal(0)


func test_cascade_remove_when_provides_tag_removed() -> void:
	# Effect B が "buff" タグを提供し、Effect A が "buff" を ongoing_required とする。
	# B を削除すると A も連鎖削除される。
	var states := OboroStates.new()
	var processer := OboroEffectProcesser.new()

	var effect_b := OboroEffect.new()
	effect_b.duration_type = OboroEffect.Duration.PERMANENT
	effect_b.provides_tags = ["buff"]
	processer.apply(states, effect_b)

	var effect_a := OboroEffect.new()
	effect_a.duration_type = OboroEffect.Duration.PERMANENT
	effect_a.ongoing_required_tags = ["buff"]
	processer.apply(states, effect_a)

	assert_int(states.effects.size()).is_equal(2)

	states.remove(states.effects[0])  # B を削除

	assert_int(states.effects.size()).is_equal(0)
