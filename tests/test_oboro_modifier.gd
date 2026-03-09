extends GdUnitTestSuite


func test_add() -> void:
	var mod := OboroModifier.create(&"hp", OboroModifier.Op.ADD, 10.0)
	assert_float(mod.apply(5.0)).is_equal(15.0)


func test_sub() -> void:
	var mod := OboroModifier.create(&"hp", OboroModifier.Op.SUB, 3.0)
	assert_float(mod.apply(10.0)).is_equal(7.0)


func test_mul() -> void:
	var mod := OboroModifier.create(&"hp", OboroModifier.Op.MUL, 2.0)
	assert_float(mod.apply(5.0)).is_equal(10.0)


func test_div() -> void:
	var mod := OboroModifier.create(&"hp", OboroModifier.Op.DIV, 4.0)
	assert_float(mod.apply(20.0)).is_equal(5.0)


func test_div_by_zero_returns_base() -> void:
	var mod := OboroModifier.create(&"hp", OboroModifier.Op.DIV, 0.0)
	assert_float(mod.apply(42.0)).is_equal(42.0)
