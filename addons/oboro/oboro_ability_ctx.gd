class_name OboroAbilityCtx
extends RefCounted

var owner: Node
var oboro: OboroComponent
var tree: SceneTree
var state: OboroStates
var effects: OboroEffectProcesser
## ゲーム側拡張用（VFX, サウンド, イベントバスなど）
var vars: Dictionary[StringName, Variant] = {}


## `await ctx.wait(1.0)` で使う
func wait(duration: float) -> Signal:
	return tree.create_timer(duration).timeout


## `await ctx.wait_damage()` で使う
func wait_damage() -> OboroDmgCtx:
	return await state.damage_received


## `await ctx.wait_pre_damage_sent()` で使う
func wait_pre_damage_sent() -> OboroDmgCtx:
	return await state.pre_damage_sent


## `await ctx.wait_pre_damage_received()` で使う
func wait_pre_damage_received() -> OboroDmgCtx:
	return await state.pre_damage_received


## `await ctx.wait_tag("stunned")` で使う
## 指定したtagがstateに追加されるまで待機する
func wait_tag(tag: String) -> String:
	while true:
		var t: String = await state.tag_added
		if t == tag:
			return t
	return ""
