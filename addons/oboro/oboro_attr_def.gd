class_name OboroAttrDef
extends Resource

@export var attr_name: StringName = &""
@export var base_value := 0.0
## "strength * 0.2" のような派生式。空なら無視
@export var derived: String = ""
@export var clamp_min: StringName = &""
@export var clamp_max: StringName = &""
