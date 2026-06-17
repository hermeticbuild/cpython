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
python_basename="$(basename "$python_runfile")"
readonly python_basename
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

    python="$(resolve_file "$python_runfile")"
    short_test_tmp="$(mktemp -d /tmp/cpython-test.XXXXXX)"
    readonly python short_test_tmp
    trap 'rm -rf "$short_test_tmp"' EXIT
    export HOME="$short_test_tmp/home"
    export TMPDIR="$short_test_tmp/tmp"
    ;;
  CYGWIN* | MINGW* | MSYS*)
    python="$(cygpath -alw "$python_runfile")"
    readonly python
    windows_temp="${TEMP:-${TMP:-C:\\Windows\\Temp}}"
    windows_temp_base="$(cygpath -u "$windows_temp")"
    short_test_tmp_posix="$(mktemp -d "$windows_temp_base/cpy.XXXXXX")"
    readonly windows_temp windows_temp_base short_test_tmp_posix
    short_test_tmp="$(cygpath -aw "$short_test_tmp_posix")"
    readonly short_test_tmp
    trap 'rm -rf "$short_test_tmp_posix"' EXIT
    HOME="$(cygpath -aw "$short_test_tmp_posix/home")"
    USERPROFILE="$HOME"
    APPDATA="$(cygpath -aw "$short_test_tmp_posix/home/AppData/Roaming")"
    LOCALAPPDATA="$(cygpath -aw "$short_test_tmp_posix/home/AppData/Local")"
    TMPDIR="$(cygpath -aw "$short_test_tmp_posix/tmp")"
    TMP="$TMPDIR"
    TEMP="$TMPDIR"
    SystemDrive="${SystemDrive:-${SYSTEMDRIVE:-C:}}"
    SystemRoot="${SystemRoot:-${SYSTEMROOT:-$SystemDrive\\Windows}}"
    ProgramFiles="${ProgramFiles:-${PROGRAMFILES:-${ProgramW6432:-${PROGRAMW6432:-$SystemDrive\\Program Files}}}}"
    export APPDATA HOME LOCALAPPDATA ProgramFiles SystemDrive SystemRoot TEMP TMP TMPDIR USERPROFILE
    unset TZ
    ;;
  *)
    readonly python="$python_runfile"
    readonly short_test_tmp="$TEST_TMPDIR"
    export HOME="$TEST_TMPDIR/home"
    export TMPDIR="$TEST_TMPDIR/tmp"
    ;;
esac
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
mkdir -p "$HOME" "$TMPDIR"
if [[ -n "${APPDATA:-}" ]]; then
  mkdir -p "$APPDATA" "$LOCALAPPDATA"
fi

test_python="$python"
stage_runtime=false
if [[ "$test_name" == test_regrtest ]]; then
  stage_runtime=true
fi
case "$(uname -s):$test_name" in
  CYGWIN*:test_distutils | CYGWIN*:test_lib2to3 | MINGW*:test_distutils | MINGW*:test_lib2to3 | MSYS*:test_distutils | MSYS*:test_lib2to3)
    stage_runtime=true
    ;;
esac

if [[ "$stage_runtime" == true ]]; then
  case "$(uname -s)" in
    CYGWIN* | MINGW* | MSYS*)
      source_runtime="$(dirname "$python_runfile")"
      ;;
    *)
      source_runtime="$(dirname "$python")"
      ;;
  esac
  staged_runtime="$short_test_tmp/runtime"
  mkdir -p "$staged_runtime"
  case "$(uname -s)" in
    Darwin | Linux)
      for source in "$source_runtime"/*; do
        name="$(basename "$source")"
        if [[ "$name" != "$python_basename" && "$name" != build ]]; then
          ln -s "$source" "$staged_runtime/$name"
        fi
      done
      cp "$python" "$staged_runtime/$python_basename"
      mkdir "$staged_runtime/build"
      test_python="$staged_runtime/$python_basename"
      ;;
    CYGWIN* | MINGW* | MSYS*)
      cp -R "$source_runtime/." "$staged_runtime/"
      chmod -R u+w "$staged_runtime"
      mkdir -p "$staged_runtime/build"
      test_python="$(cygpath -alw "$staged_runtime/$python_basename")"
      ;;
  esac
fi
readonly test_python

python_options=(-I)
if [[ "$test_name" == test_pydoc ]]; then
  python_options+=(-X "pycache_prefix=$TMPDIR/pycache")
fi

test_path="$PATH"
regrtest_worker_option=
case "$(uname -s):$test_name" in
  CYGWIN*:test_dtrace | MINGW*:test_dtrace | MSYS*:test_dtrace)
    test_path="$(cygpath -u "${SystemRoot:-C:\\Windows}")/System32"
    ;;
  CYGWIN*:test__xxsubinterpreters | CYGWIN*:test_interpreters | MINGW*:test__xxsubinterpreters | MINGW*:test_interpreters | MSYS*:test__xxsubinterpreters | MSYS*:test_interpreters)
    # Keep WindowsLoadTracker in the regrtest controller process. These tests
    # inspect the main interpreter's thread count inside the worker process.
    regrtest_worker_option=-j1
    ;;
esac

set +e
if [[ -n "$regrtest_worker_option" ]]; then
  PATH="$test_path" "$test_python" "${python_options[@]}" -m test "$regrtest_worker_option" --tempdir "$short_test_tmp" --verbose3 "$test_name"
else
  PATH="$test_path" "$test_python" "${python_options[@]}" -m test --tempdir "$short_test_tmp" --verbose3 "$test_name"
fi
readonly status=$?
set -e

if [[ "$status" -eq 4 && "$no_tests_policy" == allow-no-tests ]]; then
  exit 0
fi
exit "$status"
