extends "res://tests/test_case.gd"

const ACTION := &"cables_test_action"

func _button_with_producer(cable: Cable, trigger: CableButtonEventProducer.TriggerType) -> Button:
	var button := Button.new()
	var producer := CableButtonEventProducer.new()
	producer.output = cable
	producer.trigger_type = trigger
	button.add_child(producer)
	return add(button)

func test_button_pressed() -> void:
	var cable := Cable.new()
	var rec := Recorder.new()
	cable.link(rec.record)
	var button := _button_with_producer(cable, CableButtonEventProducer.TriggerType.PRESSED)
	button.button_down.emit()
	assert_eq(rec.count, 0)
	button.pressed.emit()
	assert_eq(rec.count, 1)
	assert_true(Cable.is_void_event(rec.last))

func test_button_down() -> void:
	var cable := Cable.new()
	var rec := Recorder.new()
	cable.link(rec.record)
	var button := _button_with_producer(cable, CableButtonEventProducer.TriggerType.BUTTON_DOWN)
	button.button_down.emit()
	button.button_up.emit()
	assert_eq(rec.count, 1)

func test_button_up() -> void:
	var cable := Cable.new()
	var rec := Recorder.new()
	cable.link(rec.record)
	var button := _button_with_producer(cable, CableButtonEventProducer.TriggerType.BUTTON_UP)
	button.button_down.emit()
	assert_eq(rec.count, 0)
	button.button_up.emit()
	assert_eq(rec.count, 1)

func test_button_producer_outside_button_does_nothing() -> void:
	var producer := CableButtonEventProducer.new()
	producer.output = Cable.new()
	add(producer)
	assert_false(producer.output.did_notify_once)

func _input_producer(cable: Cable, trigger: CableInputEventProducer.TriggerType) -> CableInputEventProducer:
	if not InputMap.has_action(ACTION):
		InputMap.add_action(ACTION)
	var producer := CableInputEventProducer.new()
	producer.output = cable
	producer.action = ACTION
	producer.trigger_type = trigger
	return add(producer)

func _send_action(pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = ACTION
	event.pressed = pressed
	Input.parse_input_event(event)
	await wait_frames()

func test_input_just_pressed() -> void:
	var cable := Cable.new()
	var rec := Recorder.new()
	cable.link(rec.record)
	_input_producer(cable, CableInputEventProducer.TriggerType.JUST_PRESSED)
	await _send_action(true)
	await _send_action(false)
	assert_eq(rec.count, 1)
	assert_true(Cable.is_void_event(rec.last))

func test_input_just_released() -> void:
	var cable := Cable.new()
	var rec := Recorder.new()
	cable.link(rec.record)
	_input_producer(cable, CableInputEventProducer.TriggerType.JUST_RELEASED)
	await _send_action(true)
	assert_eq(rec.count, 0)
	await _send_action(false)
	assert_eq(rec.count, 1)

func test_input_held_down() -> void:
	var cable := Cable.new()
	var rec := Recorder.new()
	cable.link(rec.record)
	_input_producer(cable, CableInputEventProducer.TriggerType.HELD_DOWN)
	await _send_action(true)
	assert_eq(rec.count, 1)
	await _send_action(false)
	assert_eq(rec.count, 1, "releasing is not held down")
