#!/usr/bin/env bash

set -euo pipefail

readonly python="$1"
readonly script="$2"
readonly output="$3"

exec "$python" "$script" "$output"
