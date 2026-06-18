#!/usr/bin/env bash
set -euo pipefail

workspace="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$workspace"

run_bazel_capture() {
  local stderr_path
  local output
  local status
  stderr_path="$(mktemp "${TMPDIR:-/tmp}/cpython-bazel-stderr.XXXXXX")"
  if output="$(bazel "$@" 2>"$stderr_path")"; then
    rm -f "$stderr_path"
    printf '%s' "$output"
    return 0
  else
    status=$?
    cat "$stderr_path" >&2
    rm -f "$stderr_path"
    return "$status"
  fi
}

case "${1:-}" in
  "")
    check_args=()
    ;;
  --check)
    check_args=(--check)
    ;;
  *)
    echo "usage: $0 [--check]" >&2
    exit 2
    ;;
esac

versions=(3_11 3_12 3_13 3_14)
platforms=(
  darwin_arm64:@llvm//platforms:macos_aarch64
  darwin_x86_64:@llvm//platforms:macos_x86_64
  linux_arm64:@llvm//platforms:linux_aarch64
  linux_x86_64:@llvm//platforms:linux_x86_64
)
targets=()
for version in "${versions[@]}"; do
  targets+=("@python${version}//:pyconfig_h_posix_audit_outputs")
done

source_args=()
generated_args=()
execution_root="$(run_bazel_capture info execution_root)"
for specification in "${platforms[@]}"; do
  IFS=: read -r platform target_platform <<<"$specification"
  platform_args=(
    --config=remote
    "--platforms=$target_platform"
    "--extra_execution_platforms=@cpython//:rbe_platform,$target_platform"
  )
  bazel build \
    "${platform_args[@]}" \
    "--jobs=${BAZEL_JOBS:-64}" \
    "${targets[@]}"
  for version in "${versions[@]}"; do
    generated_files="$(run_bazel_capture cquery \
      "${platform_args[@]}" \
      "@python${version}//:pyconfig_h_posix_audit_outputs" \
      --output=files)"
    header=
    header_count=0
    manifest=
    manifest_count=0
    while IFS= read -r generated_file; do
      if [[ "$generated_file" != /* ]]; then
        generated_file="$execution_root/$generated_file"
      fi
      case "$generated_file" in
        */pyconfig.h)
          header="$generated_file"
          header_count=$((header_count + 1))
          ;;
        */pyconfig_h_posix.manifest.json)
          manifest="$generated_file"
          manifest_count=$((manifest_count + 1))
          ;;
        *)
          echo "unexpected pyconfig audit output: $generated_file" >&2
          exit 1
          ;;
      esac
    done <<<"$generated_files"
    if [[ "$header_count" -ne 1 || "$manifest_count" -ne 1 ]]; then
      echo "expected one header and one manifest for @python${version} on $platform" >&2
      exit 1
    fi
    if [[ ! -f "$header" || ! -f "$manifest" ]]; then
      echo "missing pyconfig audit output for @python${version} on $platform" >&2
      exit 1
    fi
    generated_args+=(
      --generated
      "${version/_/.}:$platform=$header=$manifest"
    )
  done
done

for version in "${versions[@]}"; do
  source_files="$(run_bazel_capture cquery \
    "@python${version}//:pyconfig_h_configure_audit_sources" \
    --output=files)"
  configure=
  configure_count=0
  template=
  template_count=0
  patchlevel=
  patchlevel_count=0
  while IFS= read -r source_file; do
    case "$source_file" in
      */configure.ac)
        configure="$source_file"
        configure_count=$((configure_count + 1))
        ;;
      */pyconfig.h.in)
        template="$source_file"
        template_count=$((template_count + 1))
        ;;
      */Include/patchlevel.h)
        patchlevel="$source_file"
        patchlevel_count=$((patchlevel_count + 1))
        ;;
      *)
        echo "unexpected configure audit source: $source_file" >&2
        exit 1
        ;;
    esac
  done <<<"$source_files"
  if [[ "$configure_count" -ne 1 || "$template_count" -ne 1 || "$patchlevel_count" -ne 1 ]]; then
    echo "expected one configure.ac, pyconfig.h.in, and patchlevel.h for @python${version}" >&2
    exit 1
  fi
  if [[ "$configure" != /* ]]; then
    configure="$execution_root/$configure"
  fi
  if [[ "$template" != /* ]]; then
    template="$execution_root/$template"
  fi
  if [[ "$patchlevel" != /* ]]; then
    patchlevel="$execution_root/$patchlevel"
  fi
  for source_file in "$configure" "$template" "$patchlevel"; do
    if [[ -z "$source_file" || ! -f "$source_file" ]]; then
      echo "missing configure audit source for @python${version}" >&2
      exit 1
    fi
  done
  source_args+=(
    --source
    "${version/_/.}=$configure=$template=$patchlevel"
  )
done

args=(
  --dispositions tools/configure_check_dispositions.json
  --require-classified
  --output docs/configure-check-audit.md
)
args+=("${source_args[@]}" "${generated_args[@]}")

python3 tools/configure_checklist.py "${args[@]}" "${check_args[@]}"
