# CPython for Bazel

This module builds selected CPython releases from source and exposes each
selected interpreter as a Bazel repository. The public API uses a CPython
minor version such as `3.13`; the generated repository name replaces the dot
with an underscore, such as `python3_13`.

## Select CPython versions

Add the module and select each required CPython version in `MODULE.bazel`:

```starlark
bazel_dep(name = "cpython", version = "<module version>")

python = use_extension("@cpython//python:extensions.bzl", "python")
python.version(version = "3.14")
python.version(version = "3.13")
python.version(version = "3.12")
python.version(version = "3.11")
use_repo(
    python,
    "python3_14",
    "python3_13",
    "python3_12",
    "python3_11",
)
```

The selected interpreters are addressed by their generated repository names:

```starlark
alias(
    name = "python_3_13",
    actual = "@python3_13//:python",
)

alias(
    name = "python_3_12",
    actual = "@python3_12//:python",
)
```

The supported CPython minor versions are 3.11, 3.12, 3.13, and 3.14. Each
`python.version` call selects one CPython minor version. A consumer must also
list the corresponding generated repository in `use_repo` before referring to
it from a label.

The LLVM toolchains build each selected CPython release for Linux, macOS, and
Windows on arm64 and x86_64. Windows targets use the MSVC ABI, the hermetic MSVC
runtime, and the hermetic Windows SDK supplied by `windows_support`.

## Integration fixture

[`tests/integration`](tests/integration) is a nested Bzlmod consumer. It selects
all four supported minor versions and defines smoke tests for the reported
Python version, standard-library and encoding imports, compiled-module imports,
and starting a child interpreter with `subprocess`.

## Configure check audit

[`tools/configure_checklist.py`](tools/configure_checklist.py) reads the pinned
`configure.ac` files, `pyconfig.h.in` files, generated `pyconfig.h` files, and
`rules_cc_autoconf` manifests. It does not execute `configure`. The generated
[`docs/configure-check-audit.md`](docs/configure-check-audit.md) records every
CPython 3.11, 3.12, 3.13, and 3.14 template symbol for Linux arm64, Linux
x86_64, Darwin arm64, and Darwin x86_64. A probe classification requires a
`rules_cc_autoconf` producer in every generated configuration where the symbol
exists. The classifications and configure decisions that do not emit template
symbols are stored in
[`tools/configure_check_dispositions.json`](tools/configure_check_dispositions.json).

Run `tools/configure_check_audit.sh` to rebuild all 16 generated configurations
and update the audit. CI runs `tools/configure_check_audit.sh --check`. The
`--require-classified` check requires the complete 16-configuration matrix,
validates reviewed expected values, and requires every new template symbol to
have a `rules_cc_autoconf` producer or an explicit reviewed disposition.
