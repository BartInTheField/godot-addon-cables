extends "res://tests/test_case.gd"

func test_emits_node_destroyed_on_free() -> void:
	var lifetime := NodeWithLifetime.new()
	var rec := Recorder.new()
	lifetime.node_destroyed.connect(rec.record)
	lifetime.free()
	assert_eq(rec.count, 1)

func test_from_returns_lifetime_node_itself() -> void:
	var lifetime := NodeWithLifetime.new()
	assert_true(NodeWithLifetime.from(lifetime) == lifetime)
	assert_eq(lifetime.get_child_count(), 0)
	lifetime.free()

func test_from_returns_existing_child() -> void:
	var node := Node.new()
	node.add_child(Node.new())
	var child := NodeWithLifetime.new()
	node.add_child(child)
	assert_true(NodeWithLifetime.from(node) == child)
	assert_eq(node.get_child_count(), 2)
	node.free()

func test_from_creates_child_once() -> void:
	var node := Node.new()
	node.name = "Thing"
	var lifetime := NodeWithLifetime.from(node)
	assert_true(lifetime.get_parent() == node)
	assert_eq(String(lifetime.name), "Thing_LifetimeContext")
	assert_true(NodeWithLifetime.from(node) == lifetime, "second call reuses the child")
	assert_eq(node.get_child_count(), 1)
	node.free()

func test_created_child_is_destroyed_with_node() -> void:
	var node := Node.new()
	var rec := Recorder.new()
	NodeWithLifetime.from(node).node_destroyed.connect(rec.record)
	node.free()
	assert_eq(rec.count, 1)
