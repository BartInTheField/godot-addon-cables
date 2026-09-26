extends "res://tests/test_case.gd"

func test_call_each_keeps_callables() -> void:
	var rec := Recorder.new()
	var sink := CallableSink.new()
	sink.append([rec.record.bind("a"), rec.record.bind("b")])
	sink.call_each()
	sink.call_each()
	assert_eq(rec.values, ["a", "b", "a", "b"])

func test_append_keeps_existing_and_chains() -> void:
	var rec := Recorder.new()
	var sink := CallableSink.new()
	var returned := sink.append([rec.record.bind("a")]).append([rec.record.bind("b")])
	assert_true(returned == sink)
	sink.call_each()
	assert_eq(rec.values, ["a", "b"])

func test_call_each_and_clear() -> void:
	var rec := Recorder.new()
	var sink := CallableSink.new()
	sink.append([rec.record])
	sink.call_each_and_clear()
	sink.call_each_and_clear()
	assert_eq(rec.count, 1)

func test_aggregate_returns_call_each_and_clear() -> void:
	var rec := Recorder.new()
	var sink := CallableSink.new()
	sink.append([rec.record.bind("a")])
	var run_all := sink.aggregate([rec.record.bind("b")])
	assert_eq(rec.count, 0)
	run_all.call()
	run_all.call()
	assert_eq(rec.values, ["a", "b"])

func test_collect_replaces_existing() -> void:
	var rec := Recorder.new()
	var sink := CallableSink.new()
	sink.append([rec.record.bind("old")])
	var run_all := sink.collect([rec.record.bind("new")])
	assert_eq(rec.values, ["old"], "collect runs the existing callables")
	run_all.call()
	assert_eq(rec.values, ["old", "new"])

func test_nested_sinks() -> void:
	var rec := Recorder.new()
	var run_all := CallableSink.new().aggregate([
		CallableSink.new().aggregate([rec.record.bind(1)]),
		CallableSink.new().aggregate([rec.record.bind(2), rec.record.bind(3)]),
	])
	run_all.call()
	assert_eq(rec.values, [1, 2, 3])

func test_collect_on_temporary_sink() -> void:
	var rec := Recorder.new()
	var run_all := CallableSink.new().collect([rec.record.bind("a")])
	assert_true(run_all.is_valid(), "the returned Callable keeps the sink alive")
	run_all.call()
	assert_eq(rec.values, ["a"])
