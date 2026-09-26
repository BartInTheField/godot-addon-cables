extends "res://tests/test_case.gd"

func test_starts_without_a_value() -> void:
	var cable := Cable.new()
	assert_false(cable.did_notify_once)
	assert_null(cable.current_value)

func test_notify_stores_value() -> void:
	var cable := Cable.new()
	cable.notify(3)
	assert_true(cable.did_notify_once)
	assert_eq(cable.current_value, 3)

func test_setting_current_value_notifies() -> void:
	var cable := Cable.new()
	var rec := Recorder.new()
	cable.link(rec.record)
	cable.current_value = "hello"
	assert_eq(rec.values, ["hello"])
	assert_eq(cable.current_value, "hello")

func test_notify_calls_linked_callables() -> void:
	var cable := Cable.new()
	var a := Recorder.new()
	var b := Recorder.new()
	cable.link(a.record)
	cable.link(b.record)
	cable.notify(1)
	cable.notify(2)
	assert_eq(a.values, [1, 2])
	assert_eq(b.values, [1, 2])

func test_linked_callable_sees_previous_value_as_current() -> void:
	var cable := Cable.new()
	cable.notify(1)
	var seen := []
	cable.link(func(value): seen.append([cable.current_value, value]))
	cable.notify(2)
	assert_eq(seen, [[1, 2]])

func test_linking_twice_calls_once() -> void:
	var cable := Cable.new()
	var rec := Recorder.new()
	cable.link(rec.record)
	cable.link(rec.record)
	cable.notify(1)
	assert_eq(rec.count, 1)

func test_unlink_stops_updates() -> void:
	var cable := Cable.new()
	var rec := Recorder.new()
	cable.link(rec.record)
	cable.notify(1)
	cable.unlink(rec.record)
	cable.notify(2)
	assert_eq(rec.values, [1])

func test_link_returns_unlink_action() -> void:
	var cable := Cable.new()
	var rec := Recorder.new()
	var unlink_action := cable.link(rec.record)
	unlink_action.call()
	cable.notify(1)
	assert_eq(rec.count, 0)

func test_unlink_of_unlinked_callable_is_noop() -> void:
	var cable := Cable.new()
	var rec := Recorder.new()
	cable.unlink(rec.record)
	cable.link(rec.record)
	cable.notify(1)
	assert_eq(rec.count, 1)

func test_replay_on_link_calls_with_last_value() -> void:
	var cable := Cable.new()
	cable.replay_on_link = true
	cable.notify(1)
	cable.notify(2)
	var rec := Recorder.new()
	cable.link(rec.record)
	assert_eq(rec.values, [2])

func test_replay_on_link_waits_for_first_value() -> void:
	var cable := Cable.new()
	cable.replay_on_link = true
	var rec := Recorder.new()
	cable.link(rec.record)
	assert_eq(rec.count, 0)
	cable.notify(1)
	assert_eq(rec.values, [1])

func test_replays_null_value() -> void:
	var cable := Cable.new()
	cable.replay_on_link = true
	cable.notify(null)
	var rec := Recorder.new()
	cable.link(rec.record)
	assert_eq(rec.values, [null])

func test_no_replay_by_default() -> void:
	var cable := Cable.new()
	cable.notify(1)
	var rec := Recorder.new()
	cable.link(rec.record)
	assert_eq(rec.count, 0)

func test_void_notify_sends_void_event() -> void:
	var cable := Cable.new()
	var rec := Recorder.new()
	cable.link(rec.record)
	cable.void_notify()
	assert_eq(rec.count, 1)
	assert_true(Cable.is_void_event(rec.last))
	assert_true(cable.did_notify_once)

func test_is_void_event_rejects_other_values() -> void:
	assert_true(Cable.is_void_event(Cable.VOID_EVENT))
	assert_false(Cable.is_void_event(null))
	assert_false(Cable.is_void_event(0))
	assert_false(Cable.is_void_event({"a": 1}))
	assert_false(Cable.is_void_event({}), "an empty dictionary")
	assert_false(Cable.is_void_event(Cable.VOID_EVENT.duplicate()), "a copy of VOID_EVENT")

func test_empty_dictionary_is_a_value() -> void:
	var cable := Cable.new()
	cable.notify({})
	assert_eq(cable.get_value_or_default(5), {})

func test_void_event_survives_notify_and_replay() -> void:
	var cable := Cable.new()
	cable.replay_on_link = true
	var rec := Recorder.new()
	cable.link(rec.record)
	cable.void_notify()
	assert_true(Cable.is_void_event(rec.last), "through the signal")
	assert_true(Cable.is_void_event(cable.current_value), "in current_value")
	var replayed := Recorder.new()
	cable.link(replayed.record)
	assert_eq(replayed.count, 1)
	assert_true(Cable.is_void_event(replayed.last), "through replay_on_link")
	cable.notify(Cable.VOID_EVENT)
	assert_true(Cable.is_void_event(rec.last), "through notify(Cable.VOID_EVENT)")

func test_get_value_or_default() -> void:
	var cable := Cable.new()
	assert_eq(cable.get_value_or_default(5), 5, "before any value")
	cable.notify(7)
	assert_eq(cable.get_value_or_default(5), 7, "after a value")
	cable.void_notify()
	assert_eq(cable.get_value_or_default(5), 5, "after a void event")
	cable.notify(null)
	assert_null(cable.get_value_or_default(5), "after null")

func test_link_until_destroyed_unlinks_on_free() -> void:
	var cable := Cable.new()
	var rec := Recorder.new()
	var lifetime := NodeWithLifetime.new()
	cable.link_until_destroyed(lifetime, rec.record)
	cable.notify(1)
	lifetime.free()
	cable.notify(2)
	assert_eq(rec.values, [1])
