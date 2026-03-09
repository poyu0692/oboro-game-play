class_name OboroModifier
extends Resource

enum Op {
	ADD,
	SUB,
	MUL,
	DIV,
}

## どのAttrに作用するか
@export var target_attr: StringName = &""
@export var op: Op = Op.ADD
@export var value := 0.0


static func create(p_target_attr: StringName, p_op: Op, p_value: float) -> OboroModifier:
	var mod := new()
	mod.target_attr = p_target_attr
	mod.op = p_op
	mod.value = p_value
	return mod


func apply(base: float) -> float:
	match op:
		Op.ADD:
			return base + value
		Op.SUB:
			return base - value
		Op.MUL:
			return base * value
		Op.DIV:
			return base / value if value != 0.0 else base
	return base
