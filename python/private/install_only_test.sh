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

install_tree="$(rlocation "$1")"
archive="$(rlocation "$2")"
test_program="$(rlocation "$3")"
readonly install_tree archive test_program
readonly version="$4"

if [[ -x "$install_tree/bin/python$version" ]]; then
  python="$install_tree/bin/python$version"
elif [[ -f "$install_tree/python.exe" ]]; then
  python="$install_tree/python.exe"
else
  echo "Installed Python executable not found under $install_tree" >&2
  exit 2
fi

exec "$python" -I -S "$test_program" "$archive" "$version"
