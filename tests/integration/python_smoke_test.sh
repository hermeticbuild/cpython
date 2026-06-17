#!/usr/bin/env bash

set -euo pipefail

# --- begin runfiles.bash initialization v3 ---
set +e
runfiles_library=bazel_tools/tools/bash/runfiles/runfiles.bash
# shellcheck disable=SC1090
source "${RUNFILES_DIR:-/dev/null}/$runfiles_library" 2>/dev/null || \
  source "$(grep -sm1 "^$runfiles_library " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$runfiles_library" 2>/dev/null || \
  source "$(grep -sm1 "^$runfiles_library " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  source "$(grep -sm1 "^$runfiles_library " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  { echo "cannot find $runfiles_library" >&2; exit 1; }
unset runfiles_library
set -e
# --- end runfiles.bash initialization v3 ---

python="$(rlocation "$1")"
readonly python
if [[ ! -f "$python" ]]; then
  echo "Python runfile not found: $1" >&2
  exit 2
fi
readonly expected_version="$2"
readonly mode="$3"

case "$mode" in
  version)
    exec "$python" -I -c '
import sys

expected = tuple(map(int, sys.argv[1].split(".")))
actual = sys.version_info[:2]
if actual != expected:
    raise SystemExit(f"expected Python {expected}, got {actual}")
' "$expected_version"
    ;;
  stdlib)
    exec "$python" -I -c '
import codecs
import encodings
import json
import pathlib
import sysconfig

assert codecs.lookup("utf-8").name == "utf-8"
assert json.loads("{\"value\": 1}") == {"value": 1}
assert pathlib.PurePosixPath("stdlib") / "import" == pathlib.PurePosixPath("stdlib/import")
assert sysconfig.get_config_var("CC") == "clang"
'
    ;;
  extension)
    exec "$python" -I -c '
import _struct
import _testmultiphase
import _testsinglephase
import math
import xxlimited

assert _struct.calcsize("I") > 0
assert math.isclose(math.sqrt(81), 9)
assert not (math.__spec__.origin or "").endswith(".py")
assert (_testmultiphase.__spec__.origin or "").endswith(".so")
assert (_testsinglephase.__spec__.origin or "").endswith(".so")
assert (xxlimited.__spec__.origin or "").endswith(".so")
'
    ;;
  subprocess)
    exec "$python" -I -c '
import subprocess
import sys

result = subprocess.run(
    [sys.executable, "-I", "-c", "import encodings; print(42)"],
    check=True,
    stdout=subprocess.PIPE,
    text=True,
)
assert result.stdout.strip() == "42"
'
    ;;
  *)
    echo "unknown smoke-test mode: $mode" >&2
    exit 2
    ;;
esac
