extends "res://tests/test_case.gd"

func test_with_lifetime_unlinks_all_on_destroy() -> void:
	var cable := Cable.new()
	var a := Recorder.new()
	var b := Recorder.new()
	var lifetime := NodeWithLifetime.new()
	CableLinkGroup.with_lifetime(lifetime).append([
		cable.link(a.record),
		cable.link(b.record),
	])
	cable.notify(1)
	lifetime.free()
	cable.notify(2)
	assert_eq(a.values, [1])
	assert_eq(b.values, [1])

func test_with_lifetime_of_plain_node() -> void:
	var cable := Cable.new()
	var rec := Recorder.new()
	var node := Node.new()
	CableLinkGroup.with_lifetime_of(node).append([cable.link(rec.record)])
	cable.notify(1)
	node.free()
	cable.notify(2)
	assert_eq(rec.values, [1])

func test_is_a_callable_sink() -> void:
	var lifetime := NodeWithLifetime.new()
	assert_true(CableLinkGroup.with_lifetime(lifetime) is CallableSink)
	lifetime.free()
