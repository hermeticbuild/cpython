#!/usr/bin/env bash
set -euo pipefail

workspace="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$workspace"

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
  darwin_arm64:macos_aarch64:@llvm//platforms:macos_aarch64
  darwin_x86_64:macos_x86_64:@llvm//platforms:macos_x86_64
  linux_arm64:linux_aarch64:@llvm//platforms:linux_aarch64
  linux_x86_64:linux_x86_64:@llvm//platforms:linux_x86_64
)
targets=()
for version in "${versions[@]}"; do
  targets+=("@python${version}//:pyconfig_h_posix")
done

for specification in "${platforms[@]}"; do
  IFS=: read -r _ _ target_platform <<<"$specification"
  bazel build \
    --config=remote \
    "--jobs=${BAZEL_JOBS:-64}" \
    "--platforms=$target_platform" \
    "--extra_execution_platforms=@cpython//:rbe_platform,$target_platform" \
    "${targets[@]}"
done

output_base="$(bazel info output_base)"
args=(
  --source "3.11=$output_base/external/+python+python3_11"
  --source "3.12=$output_base/external/+python+python3_12"
  --source "3.13=$output_base/external/+python+python3_13"
  --source "3.14=$output_base/external/+python+python3_14"
  --pyconfig python/private/pyconfig.bzl
  --dispositions tools/configure_check_dispositions.json
  --require-classified
  --output docs/configure-check-audit.md
)
for version in "${versions[@]}"; do
  for specification in "${platforms[@]}"; do
    IFS=: read -r platform output_config _ <<<"$specification"
    directory="bazel-out/${output_config}-fastbuild/bin/external/+python+python${version}"
    args+=(
      --generated
      "${version/_/.}:$platform=$directory/pyconfig.h=$directory/pyconfig_h_posix.manifest.json"
    )
  done
done

python3 tools/configure_checklist.py "${args[@]}" "${check_args[@]}"
