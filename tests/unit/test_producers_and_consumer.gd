extends "res://tests/test_case.gd"

# Producer and consumer behaviour that doesn't need the scene tree.

func test_producer_forwards_values() -> void:
	var cable := Cable.new()
	var rec := Recorder.new()
	cable.link(rec.record)
	var producer := CableValueProducer.new()
	producer.output = cable
	producer.send_value_update(4)
	producer.send_void_update()
	assert_eq(rec.count, 2)
	assert_eq(rec.values[0], 4)
	assert_true(Cable.is_void_event(rec.values[1]))
	producer.free()

func test_producer_without_output_does_nothing() -> void:
	var producer := CableValueProducer.new()
	producer.send_value_update(1)
	producer.send_void_update()
	producer.free()

func test_producer_warns_without_output() -> void:
	var producer := CableValueProducer.new()
	assert_eq(producer._get_configuration_warnings(), PackedStringArray(["Output cable not assigned"]))
	producer.output = Cable.new()
	assert_eq(producer._get_configuration_warnings(), PackedStringArray())
	producer.free()

func test_consumer_warns_without_input() -> void:
	var consumer := CableValueConsumer.new()
	assert_eq(consumer._get_configuration_warnings(), PackedStringArray(["Input cable not assigned"]))
	consumer.input = Cable.new()
	assert_eq(consumer._get_configuration_warnings(), PackedStringArray())
	consumer.free()

func test_button_producer_warns_without_button_parent() -> void:
	var parent := Node.new()
	var producer := CableButtonEventProducer.new()
	producer.output = Cable.new()
	parent.add_child(producer)
	assert_eq(producer._get_configuration_warnings(), PackedStringArray(["Parent node must be a Button"]))
	parent.free()

	var button := Button.new()
	producer = CableButtonEventProducer.new()
	producer.output = Cable.new()
	button.add_child(producer)
	assert_eq(producer._get_configuration_warnings(), PackedStringArray())
	button.free()

func test_node_value_producer_update_sets_node_value() -> void:
	var cable := Cable.new()
	var producer := CableNodeValueProducer.new()
	producer.output = cable
	var node := Node.new()
	producer.send_node_value_update(node)
	assert_true(producer.node_value == node)
	assert_true(cable.current_value == node)
	producer.send_node_value_clear()
	assert_null(producer.node_value)
	assert_null(cable.current_value)
	node.free()
	producer.free()
