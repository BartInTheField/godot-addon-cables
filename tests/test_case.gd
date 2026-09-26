## Base class for tests; the runner calls each [code]test_*[/code] method on a fresh instance.
##
## The instance is added to the scene tree before the test runs and freed after it,
## so nodes added as its children are cleaned up with it. Test methods may [code]await[/code].
extends Node

## Records every call it receives, for linking to Cables or connecting to signals.
class Recorder:
	var values: Array = []

	var count: int:
		get: return values.size()

	var last: Variant:
		get: return values.back() if not values.is_empty() else null

	func record(value: Variant = null) -> void:
		values.append(value)

var failures: PackedStringArray = []

func fail(message: String) -> void:
	failures.append(message)

func assert_true(condition: bool, message := "") -> void:
	if not condition: fail(_describe("expected true", message))

func assert_false(condition: bool, message := "") -> void:
	if condition: fail(_describe("expected false", message))

func assert_eq(actual: Variant, expected: Variant, message := "") -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		fail(_describe("expected %s, got %s" % [var_to_str(expected), var_to_str(actual)], message))

func assert_null(value: Variant, message := "") -> void:
	if value != null: fail(_describe("expected null, got %s" % var_to_str(value), message))

func assert_not_null(value: Variant, message := "") -> void:
	if value == null: fail(_describe("expected a value, got null", message))

## Adds [param node] as a child of this test, so it enters the tree and is freed with the test.
func add(node: Node) -> Node:
	add_child(node)
	return node

func wait_frames(count := 1) -> void:
	for i in count:
		await get_tree().process_frame

func _describe(problem: String, message: String) -> String:
	return problem if message.is_empty() else "%s: %s" % [message, problem]
