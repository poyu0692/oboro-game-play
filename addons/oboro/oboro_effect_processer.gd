class_name OboroEffectProcesser
extends RefCounted


## 条件チェックを通過したらeffectを適用してtrueを返す
func apply(states: OboroStates, effect: OboroEffect) -> bool:
	for req in effect.required_tags:
		if not states.has_tag(req):
			return false
	for block in effect.blocking_tags:
		if states.has_tag(block):
			return false

	var applied := effect
	match effect.duration_type:
		OboroEffect.Duration.INSTANT:
			_apply_modifiers_once(states, effect)
			# タグ変化・永続化なし
		OboroEffect.Duration.DURATIONAL:
			var inst := effect.duplicate() as OboroEffect
			inst.remaining = effect.duration
			states.effects.append(inst)
			_apply_tags(states, inst)
			states._recalculate_affected(inst)
			applied = inst
		OboroEffect.Duration.PERMANENT:
			var inst := effect.duplicate() as OboroEffect
			states.effects.append(inst)
			_apply_tags(states, inst)
			states._recalculate_affected(inst)
			applied = inst

	states.effect_applied.emit(applied)
	return true


# --- private ---
func _apply_tags(states: OboroStates, effect: OboroEffect) -> void:
	for tag in effect.removes_tags:
		states.remove_tag(tag)
	for tag in effect.provides_tags:
		states.add_tag(tag)


## INSTANTのとき用。baseに直接一度だけ加算する（永続化しない）
func _apply_modifiers_once(states: OboroStates, effect: OboroEffect) -> void:
	for mod: OboroModifier in effect.modifiers:
		var attr := states.get_attr(mod.target_attr)
		if not attr:
			continue
		var result := mod.apply(attr.value)
		var def: OboroAttrDef = states.attr_defs.get(mod.target_attr)
		if def:
			if def.clamp_min != &"":
				var min_attr := states.get_attr(def.clamp_min)
				if min_attr:
					result = maxf(result, min_attr.value)
			if def.clamp_max != &"":
				var max_attr := states.get_attr(def.clamp_max)
				if max_attr:
					result = minf(result, max_attr.value)
		attr.value = result
