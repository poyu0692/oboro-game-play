class_name OboroStates
extends RefCounted

signal tag_added(tag: String)
signal tag_removed(tag: String)
signal effect_applied(effect: OboroEffect)
signal effect_removed(effect: OboroEffect)
signal pre_damage_sent(ctx: OboroDmgCtx)
signal pre_damage_received(ctx: OboroDmgCtx)
signal damage_received(ctx: OboroDmgCtx)

var tags: Array[String] = []
var attrs: Dictionary[StringName, OboroAttr] = { }
var attr_defs: Dictionary[StringName, OboroAttrDef] = { }
var effects: Array[OboroEffect] = []
var abilities: Array[OboroAbility] = []
var _evaluator: OboroAttrEvaluator


func init_attrs(defs: Array[OboroAttrDef]) -> void:
	_evaluator = OboroAttrEvaluator.new()
	_evaluator.setup(defs)
	for def in defs:
		attrs[def.attr_name] = OboroAttr.create(def.base_value)
		attr_defs[def.attr_name] = def
	## derived式の初期評価（依存順）
	for attr_name in _evaluator.eval_order:
		recalc_attr(attr_name)


## queryが完全一致、またはqueryをprefixとするタグが存在すればtrue
## 例: has_tag("status.debuff") は "status.debuff.burning" にもマッチする
func has_tag(query: String) -> bool:
	var prefix := query + "."
	for tag in tags:
		if tag == query or tag.begins_with(prefix):
			return true
	return false


func get_attr(attr_name: StringName) -> OboroAttr:
	return attrs.get(attr_name)


func grant_ability(ability: OboroAbility) -> void:
	if not ability in abilities:
		abilities.append(ability)
		for tag in ability.active_tags:
			add_tag(tag)
		ability._enter(self)


func revoke_ability(ability_name: StringName) -> void:
	var new_list: Array[OboroAbility] = []
	for a: OboroAbility in abilities:
		if a.ability_name == ability_name:
			for tag in a.active_tags:
				remove_tag(tag)
			a._exit(self)
		else:
			new_list.append(a)
	abilities = new_list


func add_tag(tag: String) -> void:
	if not has_tag(tag):
		tags.append(tag)
		tag_added.emit(tag)
		_check_ongoing_blocks(tag)


func remove_tag(tag: String) -> void:
	if not tag in tags:
		return
	tags.erase(tag)
	tag_removed.emit(tag)
	_check_ongoing_requires(tag)


## 特定Attrのvalueを、現在アクティブなeffectのmodifierから再計算する
func tick(delta: float) -> void:
	var to_remove: Array[OboroEffect] = []
	for effect in effects:
		if effect.duration_type == OboroEffect.Duration.DURATIONAL:
			effect.remaining -= delta
			if effect.remaining <= 0.0:
				to_remove.append(effect)
	for effect in to_remove:
		remove(effect)


## DmgCtxを受け取り、damage_receivedシグナルを発火する。OboroComponentから呼ぶ想定
func receive_damage(ctx: OboroDmgCtx) -> void:
	damage_received.emit(ctx)


func remove(effect: OboroEffect) -> void:
	if not effect in effects:
		return
	effects.erase(effect)
	_remove_tags(effect)
	_recalculate_affected(effect)
	effect_removed.emit(effect)


func recalc_attr(attr_name: StringName) -> void:
	var attr := get_attr(attr_name)
	if not attr:
		return
	var def: OboroAttrDef = attr_defs.get(attr_name)
	var result: float = _evaluator.get_base(def, attrs) if (_evaluator and def) else attr.base_value
	for effect in effects:
		for mod: OboroModifier in effect.modifiers:
			if mod.target_attr == attr_name:
				result = mod.apply(result)
	if def:
		if def.clamp_min != &"":
			var min_attr := get_attr(def.clamp_min)
			if min_attr:
				result = maxf(result, min_attr.value)
		if def.clamp_max != &"":
			var max_attr := get_attr(def.clamp_max)
			if max_attr:
				result = minf(result, max_attr.value)
	attr.value = result


func _check_ongoing_requires(removed_tag: String) -> void:
	var to_remove: Array[OboroEffect] = []
	for effect in effects:
		for req in effect.ongoing_required_tags:
			if not has_tag(req):
				to_remove.append(effect)
				break
	for effect in to_remove:
		remove(effect)


func _check_ongoing_blocks(added_tag: String) -> void:
	var to_remove: Array[OboroEffect] = []
	for effect in effects:
		for block in effect.ongoing_blocking_tags:
			if added_tag == block or added_tag.begins_with(block + "."):
				to_remove.append(effect)
				break
	for effect in to_remove:
		remove(effect)


func _remove_tags(effect: OboroEffect) -> void:
	for tag in effect.provides_tags:
		remove_tag(tag)


func _recalculate_affected(effect: OboroEffect) -> void:
	var dirty: Array[StringName] = []
	for mod: OboroModifier in effect.modifiers:
		if not mod.target_attr in dirty:
			dirty.append(mod.target_attr)
	if dirty.is_empty():
		return
	## eval_orderに従って再計算することでderivedの連鎖も正しく伝播する
	if _evaluator:
		for attr_name in _evaluator.eval_order:
			recalc_attr(attr_name)
	else:
		for attr_name in dirty:
			recalc_attr(attr_name)
