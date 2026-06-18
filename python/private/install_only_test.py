"""Validates and executes a relocatable install_only archive."""

from __future__ import annotations

import os
import pathlib
import shutil
import subprocess
import sys
import tarfile
import tempfile


_MTIME = 1704067200


def _is_executable(path: str) -> bool:
    return path.startswith("python/bin/") or path.endswith(
        (".dll", ".dylib", ".exe", ".pyd", ".so")
    )


def _validate_members(members: list[tarfile.TarInfo], version: str) -> bool:
    names = [member.name for member in members]
    assert names == sorted(names)
    assert len(names) == len(set(names))
    assert names

    windows = "python/python.exe" in names
    for member in members:
        path = pathlib.PurePosixPath(member.name)
        assert path.parts[0] == "python"
        assert not path.is_absolute()
        assert ".." not in path.parts
        assert not member.isdir()
        assert member.uid == 0
        assert member.gid == 0
        assert member.uname == "root"
        assert member.gname == "root"
        assert member.mtime == _MTIME
        if member.issym():
            assert member.mode == 0o777
            assert not pathlib.PurePosixPath(member.linkname).is_absolute()
        else:
            assert member.isfile()
            assert member.mode == (0o755 if _is_executable(member.name) else 0o644)

    if windows:
        assert "python/python3.dll" in names
        assert f"python/python{version.replace('.', '')}.dll" in names
        assert "python/vcruntime140.dll" in names
        assert "python/vcruntime140_1.dll" in names
        assert not any(member.issym() for member in members)
    else:
        links = {member.name: member.linkname for member in members if member.issym()}
        assert links == {
            "python/bin/python": f"python{version}",
            "python/bin/python3": f"python{version}",
        }
        assert f"python/bin/python{version}" in names
    return windows


def _execute_relocated(root: pathlib.Path, version: str, windows: bool) -> None:
    executable = root / ("python.exe" if windows else f"bin/python{version}")
    code = """
import importlib.util
import os
import pathlib
import ssl
import sqlite3
import subprocess
import sys
import sysconfig

root = pathlib.Path(sys.base_prefix)
expected = pathlib.Path(sys.argv[1])
assert os.path.samefile(root, expected), (root, expected)
assert os.path.samefile(sys.prefix, expected), (sys.prefix, expected)
assert pathlib.Path(sysconfig.get_path("stdlib")).is_relative_to(expected)
assert pathlib.Path(sysconfig.get_path("include")).is_relative_to(expected)
for name in ("_testbuffer", "_testinternalcapi", "_xxtestfuzz"):
    assert importlib.util.find_spec(name) is None, name
assert ssl.OPENSSL_VERSION
assert sqlite3.sqlite_version
subprocess.run([sys.executable, "-I", "-S", "-c", "import encodings"], check=True)
"""
    subprocess.run([executable, "-I", "-S", "-c", code, root], check=True)
    if not windows:
        for alias in ("python", "python3"):
            subprocess.run(
                [root / "bin" / alias, "-I", "-S", "-c", "import encodings"],
                check=True,
            )


def main() -> None:
    archive = pathlib.Path(sys.argv[1])
    version = sys.argv[2]
    with tarfile.open(archive, "r:gz") as tar:
        members = tar.getmembers()
        windows = _validate_members(members, version)
        with tempfile.TemporaryDirectory() as directory:
            extraction = pathlib.Path(directory) / "extraction"
            extraction.mkdir()
            tar.extractall(extraction)
            relocated = pathlib.Path(directory) / "relocated"
            shutil.move(extraction / "python", relocated)
            _execute_relocated(relocated, version, windows)


if __name__ == "__main__":
    main()
