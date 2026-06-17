#!/usr/bin/env bash

set -euo pipefail

readonly python="$1"
readonly generator="$2"
readonly output="$3"

exec "$python" "$generator" "$output"
