#!/usr/bin/env bash

set -euo pipefail

readonly bootstrap="$1"
readonly stdlib_file="$2"
readonly setup_local="$3"
readonly deepfreeze="$4"
readonly output="$5"
shift 5

absolute_path() {
  case "$1" in
    /*) printf '%s\n' "$1" ;;
    *) printf '%s/%s\n' "$PWD" "$1" ;;
  esac
}

absolute_bootstrap="$(absolute_path "$bootstrap")"
absolute_stdlib_file="$(absolute_path "$stdlib_file")"
absolute_setup_local="$(absolute_path "$setup_local")"
absolute_deepfreeze="$(absolute_path "$deepfreeze")"
absolute_output="$(absolute_path "$output")"
readonly absolute_bootstrap
readonly absolute_stdlib_file
readonly absolute_setup_local
readonly absolute_deepfreeze
readonly absolute_output
readonly stdlib="${absolute_stdlib_file%/os.py}"
stage="$(mktemp -d "${TMPDIR:-/tmp}/cpython-deepfreeze.XXXXXX")"
readonly stage
trap 'rm -rf "$stage"' EXIT

mkdir -p "$stage/Modules"
cp "$absolute_bootstrap" "$stage/_bootstrap_python"
cp "$absolute_setup_local" "$stage/Modules/Setup.local"
ln -s "$stdlib" "$stage/Lib"

"$stage/_bootstrap_python" -B "$absolute_deepfreeze" "$@" -o "$absolute_output"
