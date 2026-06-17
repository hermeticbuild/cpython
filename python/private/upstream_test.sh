#!/usr/bin/env bash

set -euo pipefail

readonly python="$TEST_SRCDIR/$1"
readonly test_name="$2"
readonly no_tests_policy="$3"

case "$no_tests_policy" in
  allow-no-tests | require-tests) ;;
  *)
    echo "invalid no-tests policy: $no_tests_policy" >&2
    exit 2
    ;;
esac

export HOME="$TEST_TMPDIR/home"
export TMPDIR="$TEST_TMPDIR/tmp"
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
