class_name OboroAttr
extends RefCounted

signal value_changed(current: float, old: float)

var value: float:
	get:
		return _value
	set(v):
		if _value != v:
			var old := _value
			_value = v
			value_changed.emit(_value, old)
var base_value: float
var _value: float


static func create(p_base_value: float = 0.0) -> OboroAttr:
	var attr := new()
	attr.base_value = p_base_value
	attr._value = p_base_value
	return attr
