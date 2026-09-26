extends "res://tests/test_case.gd"

# Producer -> Cable -> Consumer wiring with nodes in the scene tree.

func _consumer(cable: Cable) -> CableValueConsumer:
	var consumer := CableValueConsumer.new()
	consumer.input = cable
	return consumer

func _producer(cable: Cable) -> CableValueProducer:
	var producer := CableValueProducer.new()
	producer.output = cable
	return producer

func _connections(cable: Cable) -> int:
	return cable.get_signal_connection_list("_value_updated").size()

func test_consumer_forwards_values_and_void_events() -> void:
	var cable := Cable.new()
	var producer: CableValueProducer = add(_producer(cable))
	var consumer: CableValueConsumer = add(_consumer(cable))
	var values := Recorder.new()
	var voids := Recorder.new()
	var any := Recorder.new()
	consumer.value_updated.connect(values.record)
	consumer.void_update.connect(voids.record)
	consumer.any_update.connect(any.record)

	producer.send_value_update(10)
	producer.send_void_update()
	producer.send_value_update("x")

	assert_eq(values.values, [10, "x"])
	assert_eq(voids.count, 1)
	assert_eq(any.count, 3)

func test_consumer_forwards_empty_dictionary_as_value() -> void:
	var cable := Cable.new()
	var consumer: CableValueConsumer = add(_consumer(cable))
	var values := Recorder.new()
	var voids := Recorder.new()
	consumer.value_updated.connect(values.record)
	consumer.void_update.connect(voids.record)

	cable.notify({})

	assert_eq(values.values, [{}])
	assert_eq(voids.count, 0)

func test_consumer_links_on_ready_only() -> void:
	var cable := Cable.new()
	var consumer := _consumer(cable)
	assert_eq(_connections(cable), 0, "not linked before entering the tree")
	add(consumer)
	assert_eq(_connections(cable), 1)

func test_consumer_unlinks_when_freed() -> void:
	var cable := Cable.new()
	var consumer: CableValueConsumer = add(_consumer(cable))
	assert_eq(_connections(cable), 1)
	consumer.queue_free()
	await wait_frames()
	assert_eq(_connections(cable), 0)
	cable.notify(1)

func test_consumer_survives_reparenting() -> void:
	var cable := Cable.new()
	var a: Node = add(Node.new())
	var b: Node = add(Node.new())
	var consumer := _consumer(cable)
	a.add_child(consumer)
	var values := Recorder.new()
	consumer.value_updated.connect(values.record)
	consumer.reparent(b)
	await wait_frames()
	cable.notify(1)
	assert_eq(values.values, [1])
	assert_eq(_connections(cable), 1)

func test_consumer_receives_replayed_value_when_ready() -> void:
	var cable := Cable.new()
	cable.replay_on_link = true
	cable.notify(42)
	var consumer := _consumer(cable)
	var values := Recorder.new()
	consumer.value_updated.connect(values.record)
	add(consumer)
	assert_eq(values.values, [42])

func test_consumer_receives_initial_value_when_ready() -> void:
	var cable := IntCable.new()
	cable.initial_value = 100
	cable.replay_on_link = true
	var consumer := _consumer(cable)
	var values := Recorder.new()
	consumer.value_updated.connect(values.record)
	add(consumer)
	assert_eq(values.values, [100])

func test_many_consumers_on_one_cable() -> void:
	var cable := Cable.new()
	var recorders: Array[Recorder] = []
	for i in 3:
		var consumer: CableValueConsumer = add(_consumer(cable))
		var rec := Recorder.new()
		consumer.value_updated.connect(rec.record)
		recorders.append(rec)
	add(_producer(cable)).send_value_update(7)
	for rec in recorders:
		assert_eq(rec.values, [7])

func test_link_group_with_lifetime_of_node_in_tree() -> void:
	var cable := Cable.new()
	var node: Node = add(Node.new())
	var rec := Recorder.new()
	CableLinkGroup.with_lifetime_of(node).append([cable.link(rec.record)])
	cable.notify(1)
	node.queue_free()
	await wait_frames()
	cable.notify(2)
	assert_eq(rec.values, [1])
	assert_eq(_connections(cable), 0)
