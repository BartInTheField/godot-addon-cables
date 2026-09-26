extends "res://tests/test_case.gd"

func _producer(cable: Cable, node: Node) -> CableNodeValueProducer:
	var producer := CableNodeValueProducer.new()
	producer.output = cable
	producer.node_value = node
	return producer

func test_sends_node_when_it_becomes_ready() -> void:
	var cable := Cable.new()
	var target := Node.new()
	# As a child, the producer is ready before its parent target.
	var producer := _producer(cable, target)
	target.add_child(producer)
	var rec := Recorder.new()
	cable.link(rec.record)
	add(target)
	assert_eq(rec.count, 1)
	assert_true(rec.last == target)

func test_sends_already_ready_node() -> void:
	var cable := Cable.new()
	var target: Node = add(Node.new())
	add(_producer(cable, target))
	assert_true(cable.current_value == target)

func test_notify_on_node_value_ready_false() -> void:
	var cable := Cable.new()
	var producer := _producer(cable, add(Node.new()))
	producer.notify_on_node_value_ready = false
	add(producer)
	assert_false(cable.did_notify_once)

func test_clears_value_when_destroyed() -> void:
	var cable := Cable.new()
	var target: Node = add(Node.new())
	target.add_child(_producer(cable, target))
	assert_true(cable.current_value == target)
	target.queue_free()
	await wait_frames()
	assert_true(cable.did_notify_once)
	assert_null(cable.current_value)

func test_keeps_value_when_clear_on_destroy_false() -> void:
	var cable := Cable.new()
	var target: Node = add(Node.new())
	var producer := _producer(cable, target)
	producer.clear_on_destroy = false
	add(producer)
	producer.queue_free()
	await wait_frames()
	assert_true(cable.current_value == target)
