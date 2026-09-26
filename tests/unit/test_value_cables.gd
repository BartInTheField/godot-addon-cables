extends "res://tests/test_case.gd"

# The typed Cables (IntCable, FloatCable, ...) and their initial value.

const SAVE_PATH := "user://test_value_cable.tres"

func test_starts_with_initial_value() -> void:
	var cable := IntCable.new()
	cable.initial_value = 100
	assert_true(cable.has_value)
	assert_false(cable.did_notify_once, "an initial value isn't an emitted one")
	assert_eq(cable.current_value, 100)

func test_notify_replaces_initial_value() -> void:
	var cable := IntCable.new()
	cable.initial_value = 100
	cable.notify(75)
	assert_eq(cable.current_value, 75)
	assert_eq(cable.initial_value, 100, "initial value is left alone")

func test_linked_callable_sees_initial_value_as_previous() -> void:
	var cable := IntCable.new()
	cable.initial_value = 100
	var seen := []
	cable.link(func(value): seen.append([cable.current_value, value]))
	cable.notify(75)
	assert_eq(seen, [[100, 75]])

func test_replay_on_link_replays_initial_value() -> void:
	var cable := IntCable.new()
	cable.initial_value = 100
	cable.replay_on_link = true
	var rec := Recorder.new()
	cable.link(rec.record)
	assert_eq(rec.values, [100])

func test_no_replay_without_replay_on_link() -> void:
	var cable := IntCable.new()
	cable.initial_value = 100
	var rec := Recorder.new()
	cable.link(rec.record)
	assert_eq(rec.count, 0)

func test_get_value_or_default_returns_initial_value() -> void:
	var cable := IntCable.new()
	cable.initial_value = 3
	assert_eq(cable.get_value_or_default(0), 3)

func test_reset_emits_initial_value() -> void:
	var cable := IntCable.new()
	cable.initial_value = 100
	cable.notify(0)
	var rec := Recorder.new()
	cable.link(rec.record)
	cable.reset()
	assert_eq(rec.values, [100])
	assert_eq(cable.current_value, 100)

func test_reset_on_plain_cable_does_nothing() -> void:
	var cable := Cable.new()
	var rec := Recorder.new()
	cable.link(rec.record)
	cable.reset()
	assert_eq(rec.count, 0)
	assert_false(cable.has_value)
	assert_null(cable.current_value)

func test_plain_cable_has_value_once_notified() -> void:
	var cable := Cable.new()
	assert_false(cable.has_value)
	cable.notify(null)
	assert_true(cable.has_value)

func test_each_type_defaults_to_its_zero_value() -> void:
	assert_eq(BoolCable.new().current_value, false)
	assert_eq(IntCable.new().current_value, 0)
	assert_eq(FloatCable.new().current_value, 0.0)
	assert_eq(StringCable.new().current_value, "")
	assert_eq(Vector2Cable.new().current_value, Vector2.ZERO)
	assert_eq(Vector3Cable.new().current_value, Vector3.ZERO)
	assert_eq(ColorCable.new().current_value, Color.WHITE)

func test_initial_value_is_loaded_from_resource_file() -> void:
	var saved := FloatCable.new()
	saved.initial_value = 12.5
	assert_eq(ResourceSaver.save(saved, SAVE_PATH), OK)
	var loaded: FloatCable = ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	assert_eq(loaded.current_value, 12.5)
	DirAccess.remove_absolute(SAVE_PATH)

func test_emitted_value_is_not_saved_to_resource_file() -> void:
	var cable := IntCable.new()
	cable.initial_value = 100
	cable.notify(5)
	assert_eq(ResourceSaver.save(cable, SAVE_PATH), OK)
	var loaded: IntCable = ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	assert_false(loaded.did_notify_once)
	assert_eq(loaded.current_value, 100)
	DirAccess.remove_absolute(SAVE_PATH)
