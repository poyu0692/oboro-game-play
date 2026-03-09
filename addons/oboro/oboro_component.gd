class_name OboroComponent
extends Node

@export var attr_set: OboroAttrSet
@export var dmg_calc: OboroDmgCalc

## ノードがアクティブになったときに自動で適用されるEffect群
var activate_effects: Array[OboroEffect] = []
var state: OboroStates
var _processer: OboroEffectProcesser


func _ready() -> void:
	state = OboroStates.new()
	_processer = OboroEffectProcesser.new()
	if attr_set:
		state.init_attrs(attr_set.defs)
	state.effect_applied.connect(_on_effect_applied)
	state.effect_removed.connect(_on_effect_removed)
	for effect in activate_effects:
		_processer.apply(state, effect)


func _process(delta: float) -> void:
	state.tick(delta)


func get_attr(attr_name: StringName) -> OboroAttr:
	return state.get_attr(attr_name)


func apply_effect(effect: OboroEffect) -> bool:
	return _processer.apply(state, effect)


## ダメージを与える側が呼ぶ。pre_damage_sentフック後にtarget.receive_damageを呼ぶ
func send_damage(ctx: OboroDmgCtx, target_oboro: OboroComponent) -> void:
	ctx.source_oboro = self
	state.pre_damage_sent.emit(ctx)
	target_oboro.receive_damage(ctx)


func receive_damage(ctx: OboroDmgCtx) -> void:
	ctx.target_oboro = self
	state.pre_damage_received.emit(ctx)
	if dmg_calc:
		var effect := dmg_calc.calc(ctx)
		_processer.apply(state, effect)
	state.receive_damage(ctx)


func activate(ability_name: StringName) -> bool:
	var ctx := _create_ability_ctx()
	for ability: OboroAbility in state.abilities:
		if ability.ability_name == ability_name:
			if ability._can_activate(ctx):
				ability.invoke(ctx)
				return true
	return false


# --- private ---
func _create_ability_ctx() -> OboroAbilityCtx:
	var ctx := OboroAbilityCtx.new()
	ctx.owner = owner
	ctx.oboro = self
	ctx.tree = get_tree()
	ctx.state = state
	ctx.effects = _processer
	return ctx


func _on_effect_applied(effect: OboroEffect) -> void:
	for ability: OboroAbility in effect.grants_abilities:
		state.grant_ability(ability)
	for ability_name: StringName in effect.revokes_abilities:
		state.revoke_ability(ability_name)
	if not effect.revokes_abilities_by_tag.is_empty():
		var to_revoke: Array[OboroAbility] = []
		for a: OboroAbility in state.abilities:
			var matched := false
			for t in a.active_tags:
				for q in effect.revokes_abilities_by_tag:
					if t == q or t.begins_with(q + "."):
						matched = true
						break
				if matched:
					break
			if matched:
				to_revoke.append(a)
		for a in to_revoke:
			state.revoke_ability(a.ability_name)


func _on_effect_removed(effect: OboroEffect) -> void:
	for ability: OboroAbility in effect.grants_abilities:
		state.revoke_ability(ability.ability_name)
