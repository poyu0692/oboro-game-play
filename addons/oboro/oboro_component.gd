@icon("res://addons/oboro/volleyball.svg")
class_name OboroComponent
extends Node

## Resource defining the initial attributes for this component.
@export var attr_set: OboroAttrSet
## Damage calculator for processing damage context.
@export var dmg_calc: OboroDmgCalc

## Relayed from OboroStates.tag_added
signal tag_added(tag: String)
## Relayed from OboroStates.tag_removed
signal tag_removed(tag: String)
## Relayed from OboroStates.effect_applied
signal effect_applied(effect: OboroEffect)
## Relayed from OboroStates.effect_removed
signal effect_removed(effect: OboroEffect)
## Relayed from OboroStates.pre_damage_sent
signal pre_damage_sent(ctx: OboroDmgCtx)
## Relayed from OboroStates.pre_damage_received
signal pre_damage_received(ctx: OboroDmgCtx)
## Relayed from OboroStates.damage_received
signal damage_received(ctx: OboroDmgCtx)
## Emitted when an ability emits a game event (VFX, SFX, UI, etc).
signal event_emitted(event_name: StringName, payload: Variant)

## The current state of this component (attributes, effects, abilities, tags).
var state: OboroStates
var _processer: OboroEffectProcesser


func _ready() -> void:
	state = OboroStates.new()
	_processer = OboroEffectProcesser.new()
	_processer.setup(self )
	if attr_set:
		state.init_attrs(attr_set.defs)
	state.tag_added.connect(tag_added.emit)
	state.tag_removed.connect(tag_removed.emit)
	state.effect_applied.connect(effect_applied.emit)
	state.effect_removed.connect(effect_removed.emit)
	state.pre_damage_sent.connect(pre_damage_sent.emit)
	state.pre_damage_received.connect(pre_damage_received.emit)
	state.damage_received.connect(damage_received.emit)


func _process(delta: float) -> void:
	state.tick(delta)


## Gets an attribute by name. Returns null if not found.
func get_attr(attr_name: StringName) -> OboroAttr:
	return state.get_attr(attr_name)


## Applies an effect to this component's state. Returns true if successfully applied.
func apply_effect(effect: OboroEffect, source: OboroStates = null) -> bool:
	return _processer.apply(state, effect, source)


## Sends damage to a target. Called by the damage source. Emits pre_damage_sent before calling target.receive_damage.
func send_damage(ctx: OboroDmgCtx, target_oboro: OboroComponent) -> void:
	ctx.source_oboro = self
	state.pre_damage_sent.emit(ctx)
	target_oboro.receive_damage(ctx)


## Receives damage from a source. Emits pre_damage_received and applies damage effect if dmg_calc is set.
func receive_damage(ctx: OboroDmgCtx) -> void:
	ctx.target_oboro = self
	state.pre_damage_received.emit(ctx)
	if dmg_calc:
		var effect := dmg_calc.calc(ctx)
		_processer.apply(state, effect)
	state.receive_damage(ctx)


## Checks if an ability can be activated by name.
func can_activate(ability_name: StringName) -> bool:
	var ctx := create_ability_ctx()
	for ability: OboroAbility in state.abilities:
		if ability.ability_name == ability_name:
			return ability.can_activate(ctx)
	return false


## Activates an ability by name. Returns true if the ability was successfully activated.
func activate(ability_name: StringName) -> bool:
	var ctx := create_ability_ctx()
	for ability: OboroAbility in state.abilities:
		if ability.ability_name == ability_name:
			if ability.can_activate(ctx):
				ability.invoke(ctx)
				return true
	return false


func create_ability_ctx() -> OboroAbilityCtx:
	var ctx := OboroAbilityCtx.new()
	ctx.owner = owner
	ctx.oboro = self
	ctx.tree = get_tree()
	ctx.state = state
	ctx.effects = _processer
	return ctx
