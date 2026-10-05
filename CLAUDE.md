# CLAUDE.md

Godot 4.4+ addon (`addons/cables`): `Cable` resources used as signals shared across scenes, plus producer/consumer nodes.
Only `addons/cables` ships (see `.gitattributes`); `examples/` and `tests/` stay in the repository.

## Tests

Run all tests with `tests/run.sh`, or one suite with `tests/run.sh unit` / `tests/run.sh integration`.
It uses `godot` from the PATH (override with `GODOT=/path/to/godot`), runs headless, and exits non-zero on failure.
CI (`.github/workflows/test.yml`) runs both suites on every pull request and push to `main`, and before each release.
The minimum pin is Godot 4.4.1 (the engine declared in `project.godot`); Godot 4.7.2 is required as well. A 4.8
pre-release job does not block merges. Keep tests compatible with 4.4.1, not only your local engine.

Behaviour expected when changing code:

- Every behaviour change or bug fix comes with a test that fails without the change. Run `tests/run.sh` before
  calling work done, and report failures instead of skipping, weakening, or deleting tests to get green.
- **Unit tests** (`tests/unit/`) test one class in isolation, without the scene tree: create objects with `.new()`
  and call methods directly. Free any `Node` you create, since nodes outside the tree aren't freed automatically.
- **Integration tests** (`tests/integration/`) cover classes working together in the scene tree: producers,
  Cables and consumers wired up, node lifetimes (`queue_free`, reparenting), input and button events, and the
  example scenes. Add nodes with `add(node)` so they're freed with the test, and `await wait_frames()` after
  `queue_free()` or other deferred work.
- A test file is `tests/<suite>/test_<subject>.gd`, extends `"res://tests/test_case.gd"` (no `class_name`), and
  each `test_*` method is one test, run on a fresh instance. Methods may `await`.
- Assert with `assert_eq`, `assert_true`, `assert_false`, `assert_null`, `assert_not_null` or `fail`. `assert_eq`
  also compares types, so `1` is not `1.0`. Don't use GDScript's built-in `assert`.
- Use `Recorder` to capture what a Cable or signal sends: `cable.link(rec.record)`, then check `rec.values`,
  `rec.count` or `rec.last`.
- A runtime script error anywhere in the run fails it, even if every assertion passed, so fix errors rather than
  ignoring them.
- Give each test its own `Cable.new()`. The example `.tres` Cables are shared and keep their value between tests,
  so example tests compare against the value from before the test.
