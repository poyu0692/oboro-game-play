class_name OboroDmgCtx
extends RefCounted

## 入力
var source_oboro: OboroComponent
var target_oboro: OboroComponent
var damage: float
## Tags attached to this damage instance (e.g. "physical", "critical", "aoe").
var tags: Array[String] = []
## ゲーム側拡張用
var vars: Dictionary[Variant, Variant] = { }


## Adds a tag to this damage context if not already present.
func add_tag(tag: String) -> void:
	if not tag in tags:
		tags.append(tag)


## Removes a tag from this damage context.
func remove_tag(tag: String) -> void:
	tags.erase(tag)


## Returns true if the tag exists (full match or prefix match).
## Example: has_tag("damage.physical") matches "damage.physical.blunt".
func has_tag(query: String) -> bool:
	var prefix := query + "."
	for tag in tags:
		if tag == query or tag.begins_with(prefix):
			return true
	return false
