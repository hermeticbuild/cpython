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

python_runfile="$(rlocation "$1")"
readonly python_runfile
if [[ ! -f "$python_runfile" ]]; then
  echo "Python runfile not found: $1" >&2
  exit 2
fi
readonly test_name="$2"
readonly no_tests_policy="$3"

case "$no_tests_policy" in
  allow-no-tests | require-tests) ;;
  *)
    echo "invalid no-tests policy: $no_tests_policy" >&2
    exit 2
    ;;
esac

case "$(uname -s)" in
  Darwin | Linux)
    resolve_file() {
      local path="$1"
      local directory
      local target

      while [[ -L "$path" ]]; do
        directory="$(cd -P "$(dirname "$path")" && pwd)"
        target="$(readlink "$path")"
        if [[ "$target" = /* ]]; then
          path="$target"
        else
          path="$directory/$target"
        fi
      done
      directory="$(cd -P "$(dirname "$path")" && pwd)"
      printf '%s/%s\n' "$directory" "$(basename "$path")"
    }

    readonly python="$(resolve_file "$python_runfile")"
    readonly short_test_tmp="$(mktemp -d /tmp/cpython-test.XXXXXX)"
    trap 'rm -rf "$short_test_tmp"' EXIT
    export HOME="$short_test_tmp/home"
    export TMPDIR="$short_test_tmp/tmp"
    ;;
  *)
    readonly python="$python_runfile"
    export HOME="$TEST_TMPDIR/home"
    export TMPDIR="$TEST_TMPDIR/tmp"
    ;;
esac
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
mkdir -p "$HOME" "$TMPDIR"

python_options=(-I)
if [[ "$test_name" == test_pydoc ]]; then
  python_options+=(-X "pycache_prefix=$TMPDIR/pycache")
fi

set +e
"$python" "${python_options[@]}" -m test --verbose3 "$test_name"
readonly status=$?
set -e

if [[ "$status" -eq 4 && "$no_tests_policy" == allow-no-tests ]]; then
  exit 0
fi
exit "$status"
