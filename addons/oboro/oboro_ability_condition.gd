class_name OboroAbilityCondition
extends Resource

enum Op { LT, LTE, EQ, GTE, GT }

@export var lhs_attr: StringName
@export var op: Op = Op.GTE
## rhs_attrが空なら絶対値、指定すれば rhs_attr.value * rhs_value を右辺とする
@export var rhs_attr: StringName = &""
@export var rhs_value: float = 0.0


func check(states: OboroStates) -> bool:
	var lhs := states.get_attr(lhs_attr)
	if not lhs:
		return false
	var rhs: float
	if rhs_attr == &"":
		rhs = rhs_value
	else:
		var rhs_a := states.get_attr(rhs_attr)
		if not rhs_a:
			return false
		rhs = rhs_a.value * rhs_value
	match op:
		Op.LT:
			return lhs.value < rhs
		Op.LTE:
			return lhs.value <= rhs
		Op.EQ:
			return is_equal_approx(lhs.value, rhs)
		Op.GTE:
			return lhs.value >= rhs
		Op.GT:
			return lhs.value > rhs
	return false
