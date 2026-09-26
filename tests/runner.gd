## Headless test runner; use tests/run.sh rather than running this directly.
##
## Runs every [code]test_*[/code] method of every [code]test_*.gd[/code] script in the given
## suite folders (all of [constant SUITES] by default) and exits non-zero if any fail.
extends SceneTree

const SUITES := ["unit", "integration"]

func _initialize() -> void:
	_run()

func _run() -> void:
	# Let the tree start processing so tests can await frames.
	await process_frame
	var suites := OS.get_cmdline_user_args()
	if suites.is_empty():
		suites = PackedStringArray(SUITES)

	var passed := 0
	var failed: PackedStringArray = []
	for suite in suites:
		var dir := "res://tests/%s" % suite
		if not DirAccess.dir_exists_absolute(dir):
			printerr("Unknown test suite: %s" % suite)
			quit(1)
			return
		for file in DirAccess.get_files_at(dir):
			if not (file.begins_with("test_") and file.ends_with(".gd")):
				continue
			var script: GDScript = load("%s/%s" % [dir, file])
			for method in _test_methods(script):
				var test: Node = script.new()
				test.name = method
				root.add_child(test)
				await Callable(test, method).call()
				var label := "%s/%s::%s" % [suite, file.get_basename(), method]
				if test.failures.is_empty():
					passed += 1
					print("  PASS %s" % label)
				else:
					failed.append(label)
					print("  FAIL %s" % label)
					for f in test.failures: print("       %s" % f)
				test.free()
				# Let anything the test queued (queue_free, call_deferred) settle before the next one.
				await process_frame

	print("\n%d passed, %d failed" % [passed, failed.size()])
	for label in failed: print("  FAIL %s" % label)
	quit(0 if failed.is_empty() else 1)

func _test_methods(script: GDScript) -> PackedStringArray:
	var names: PackedStringArray = []
	for m in script.get_script_method_list():
		var method_name: String = m.name
		if method_name.begins_with("test_") and not names.has(method_name):
			names.append(method_name)
	return names
