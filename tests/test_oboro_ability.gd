extends GdUnitTestSuite


class ConcreteAbility extends OboroAbility:
	pass


func _make_ctx(states: OboroStates) -> OboroAbilityCtx:
	var ctx := OboroAbilityCtx.new()
	ctx.state = states
	ctx.effects = OboroEffectProcesser.new()
	return ctx


# --- 発動条件 ---

func test_can_activate_false_when_required_tag_missing() -> void:
	var states := OboroStates.new()
	var ability := ConcreteAbility.new()
	ability.required_tags = ["enraged"]

	assert_bool(ability._can_activate(_make_ctx(states))).is_false()


func test_can_activate_true_when_required_tag_present() -> void:
	var states := OboroStates.new()
	states.add_tag("enraged")
	var ability := ConcreteAbility.new()
	ability.required_tags = ["enraged"]

	assert_bool(ability._can_activate(_make_ctx(states))).is_true()


func test_can_activate_false_when_blocking_tag_present() -> void:
	var states := OboroStates.new()
	states.add_tag("stunned")
	var ability := ConcreteAbility.new()
	ability.blocking_tags = ["stunned"]

	assert_bool(ability._can_activate(_make_ctx(states))).is_false()


func test_can_activate_true_when_no_conditions() -> void:
	var states := OboroStates.new()
	var ability := ConcreteAbility.new()

	assert_bool(ability._can_activate(_make_ctx(states))).is_true()


# --- クールダウン ---

func test_cooldown_prevents_reactivation_after_invoke() -> void:
	var states := OboroStates.new()
	var ability := ConcreteAbility.new()
	ability.ability_name = &"test_ability"
	ability.cooldown = 1.0
	var ctx := _make_ctx(states)

	assert_bool(ability._can_activate(ctx)).is_true()
	ability.invoke(ctx)
	assert_bool(ability._can_activate(ctx)).is_false()


func test_cooldown_expires_after_tick() -> void:
	var states := OboroStates.new()
	var ability := ConcreteAbility.new()
	ability.ability_name = &"test_ability"
	ability.cooldown = 1.0
	var ctx := _make_ctx(states)

	ability.invoke(ctx)
	assert_bool(ability._can_activate(ctx)).is_false()

	states.tick(1.0)

	assert_bool(ability._can_activate(ctx)).is_true()


func test_no_cooldown_allows_consecutive_invokes() -> void:
	var states := OboroStates.new()
	var ability := ConcreteAbility.new()
	ability.ability_name = &"test_ability"
	ability.cooldown = 0.0
	var ctx := _make_ctx(states)

	ability.invoke(ctx)
	assert_bool(ability._can_activate(ctx)).is_true()
