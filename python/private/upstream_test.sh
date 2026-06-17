#!/usr/bin/env bash

set -euo pipefail

readonly python_runfile="$TEST_SRCDIR/$1"
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

set +e
"$python" -I -m test --verbose3 "$test_name"
readonly status=$?
set -e

if [[ "$status" -eq 4 && "$no_tests_policy" == allow-no-tests ]]; then
  exit 0
fi
exit "$status"
