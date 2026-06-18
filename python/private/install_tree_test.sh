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
readonly version="$2"

case "$(uname -s)" in
  CYGWIN* | MINGW* | MSYS*)
    writable_install_tree="$TEST_TMPDIR/install"
    cp -R "$install_tree" "$writable_install_tree"
    chmod -R u+w "$writable_install_tree"
    install_tree="$writable_install_tree"
    ;;
esac
readonly install_tree

if [[ -x "$install_tree/bin/python$version" ]]; then
  python="$install_tree/bin/python$version"
elif [[ -f "$install_tree/python.exe" ]]; then
  python="$install_tree/python.exe"
else
  echo "Installed Python executable not found under $install_tree" >&2
  exit 2
fi
readonly python

exec "$python" -I -S -c '
import json
import importlib.util
import os
import pathlib
import ssl
import sqlite3
import subprocess
import sys
import sysconfig
import tempfile

version = sys.argv[1]
root = pathlib.Path(sys.base_prefix)
executable = pathlib.Path(sys.executable).resolve()
expected_root = executable.parent if os.name == "nt" else executable.parent.parent
stdlib = root / "Lib" if os.name == "nt" else root / "lib" / f"python{version}"
include = root / "include" if os.name == "nt" else root / "include" / f"python{version}"

assert os.path.samefile(root, expected_root), (root, expected_root)
assert os.path.samefile(sys.prefix, root), (sys.prefix, root)
assert os.path.samefile(sysconfig.get_path("stdlib"), stdlib)
assert os.path.samefile(sysconfig.get_path("include"), include)
assert (include / "pyconfig.h").is_file()
assert not (root / "Makefile").exists()
assert not (root / "Modules" / "Setup.local").exists()
assert not (root / "pybuilddir.txt").exists()
assert not (root / "pyconfig.h").exists()
for excluded_tests in (
    "ctypes/test",
    "email/test",
    "idlelib/idle_test",
    "json/tests",
    "sqlite3/test",
    "test",
    "tkinter/test",
    "unittest/test",
):
    assert not (stdlib / excluded_tests).exists(), excluded_tests
for test_module in ("_testbuffer", "_testinternalcapi", "_xxtestfuzz"):
    assert importlib.util.find_spec(test_module) is None, test_module

if os.name == "nt":
    import _ctypes

    assert sys.winver.startswith(version), sys.winver
    assert os.path.samefile(pathlib.Path(_ctypes.__file__).parent, root / "DLLs")
    assert (root / "LICENSE.txt").is_file()
    dll_basename = "python" + version.replace(".", "")
    assert (root / f"{dll_basename}.dll").is_file()
    assert (root / "python3.dll").is_file()
    assert (root / "vcruntime140.dll").is_file()
    assert (root / "vcruntime140_1.dll").is_file()
    assert (root / "libs" / f"{dll_basename}.lib").is_file()
    assert (root / "libs" / "python3.lib").is_file()
    assert (root / "Scripts" / ".empty").is_file()
else:
    if version == "3.14":
        import _asyncio

        assert os.path.samefile(pathlib.Path(_asyncio.__file__).parent, stdlib / "lib-dynload")
        assert _asyncio.__file__.endswith(sysconfig.get_config_var("EXT_SUFFIX"))
    assert not pathlib.Path(sysconfig.get_makefile_filename()).exists()
    assert (stdlib / "LICENSE.txt").is_file()
    if version == "3.14":
        build_details = stdlib / "build-details.json"
        assert build_details.is_file()
        assert len(list(stdlib.glob("_sysconfig_vars_*.json"))) == 1
        details = json.loads(build_details.read_text())
        assert details["schema_version"] == "1.0"
        assert details["base_prefix"] == "../.."
        assert details["base_interpreter"] == f"./bin/python{version}"
        assert details["platform"] == sysconfig.get_platform()
        assert details["abi"]["extension_suffix"] == sysconfig.get_config_var("EXT_SUFFIX")
        assert details["abi"]["stable_abi_suffix"] == ".abi3.so"
        assert details["c_api"]["headers"] == f"./include/python{version}"

assert ssl.OPENSSL_VERSION
assert sqlite3.sqlite_version
subprocess.run([sys.executable, "-I", "-S", "-c", "import encodings"], check=True)

with tempfile.TemporaryDirectory() as directory:
    environment = pathlib.Path(directory) / "venv"
    subprocess.run(
        [sys.executable, "-I", "-m", "venv", "--without-pip", str(environment)],
        check=True,
    )
    venv_python = environment / ("Scripts/python.exe" if os.name == "nt" else "bin/python")
    subprocess.run([venv_python, "-I", "-S", "-c", "import encodings"], check=True)
' "$version"
