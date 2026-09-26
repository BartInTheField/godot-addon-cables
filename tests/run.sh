#!/bin/sh
# Runs the tests headless: all suites, or the ones named ("unit", "integration").
# Uses $GODOT, or godot on the PATH. Also fails on script errors outside assertions,
# since a runtime error only aborts the test function instead of failing it.
set -u
cd "$(dirname "$0")/.."
godot="${GODOT:-godot}"

# Import first so class_names added since the last import are registered.
"$godot" --headless --import >/dev/null 2>&1

log=$(mktemp)
trap 'rm -f "$log"' EXIT
"$godot" --headless -s res://tests/runner.gd -- "$@" >"$log" 2>&1
status=$?
cat "$log"

if grep -q "SCRIPT ERROR" "$log"; then
  echo "Script errors were logged during the run (see above)." >&2
  status=1
fi
exit $status
