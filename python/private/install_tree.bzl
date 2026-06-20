"""Installed CPython directory layout."""

load("@bazel_lib//lib:copy_to_directory.bzl", "copy_to_directory")
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("@rules_shell//shell:sh_test.bzl", "sh_test")

_INSTALL_ONLY_STDLIB_EXCLUDES = [
    "Lib/bsddb/test/**",
    "Lib/ctypes/test/**",
    "Lib/distutils/tests/**",
    "Lib/email/test/**",
    "Lib/idlelib/idle_test/**",
    "Lib/json/tests/**",
    "Lib/lib-tk/test/**",
    "Lib/lib2to3/tests/**",
    "Lib/sqlite3/test/**",
    "Lib/test/**",
    "Lib/tkinter/test/**",
    "Lib/unittest/test/**",
]

def _extension_labels(extensions):
    return [extension.label for extension in extensions]

def _extension_replacements(extensions, destination):
    return {
        extension.filename: "{}/{}".format(destination, extension.filename)
        for extension in extensions
    }

def _posix_replacements(version, extensions):
    stdlib = "lib/python{}".format(version)
    replacements = {
        "Include": "include/python{}".format(version),
        "LICENSE": stdlib + "/LICENSE.txt",
        "Lib": stdlib,
        "install_inputs/posix": "",
        "pyconfig.h": "include/python{}/pyconfig.h".format(version),
        "_sysconfig_vars": stdlib + "/_sysconfig_vars",
        "install_metadata/build-details.json": stdlib + "/build-details.json",
        "install_runtime/python": "bin/python{}".format(version),
    }
    replacements.update(_extension_replacements(extensions, stdlib + "/lib-dynload"))
    return replacements

def _windows_replacements(version, extensions):
    dll_basename = "python{}".format(version.replace(".", ""))
    replacements = {
        "Include": "include",
        "PC/pyconfig.h": "include/pyconfig.h",
        "install_metadata/windows/LICENSE.txt": "LICENSE.txt",
        "install_inputs/windows": "",
        "install_runtime/libs": "libs",
        "install_runtime/python.exe": "python.exe",
        "install_runtime/pythonw.exe": "pythonw.exe",
        "install_runtime/{}.dll".format(dll_basename): "{}.dll".format(dll_basename),
        "runtime/libs": "libs",
        "runtime/python3.dll": "python3.dll",
        "runtime_stdlib_inputs": "Lib",
        "vcruntime140.dll": "vcruntime140.dll",
        "vcruntime140_1.dll": "vcruntime140_1.dll",
    }
    replacements.update(_extension_replacements(extensions, "DLLs"))
    return replacements

def cpython_install_tree(
        version,
        extensions,
        install_metadata,
        python = ":install_runtime/python",
        pythonw = ":install_runtime/pythonw",
        pyconfig = ":pyconfig_h",
        sysconfig_data = ":sysconfig_data",
        windows_core_libraries = [
            ":python3_dll",
            ":python3_import_library",
            ":python_install_dll",
            ":python_install_import_library",
        ],
        windows_runtime_libraries = ["@msvc_runtime//:vcruntime_dlls"],
        windows_license = ":install_windows_license",
        windows_venv_launchers = []):
    """Defines the private staging tree for an install_only archive."""
    posix_marker = "install_inputs/posix/lib/python{}/lib-dynload/.empty".format(version)
    write_file(
        name = "_install_tree_posix_marker",
        out = posix_marker,
        content = [],
        visibility = ["//visibility:private"],
    )
    write_file(
        name = "_install_tree_windows_marker",
        out = "install_inputs/windows/Scripts/.empty",
        content = [],
        visibility = ["//visibility:private"],
    )

    common_sources = native.glob(
        [
            "Include/**/*.h",
            "Lib/**",
        ],
        exclude = _INSTALL_ONLY_STDLIB_EXCLUDES,
    ) + [pyconfig]
    posix_sources = [
        python,
        sysconfig_data,
        "LICENSE",
        ":_install_tree_posix_marker",
    ]
    windows_sources = [
        python,
        pythonw,
        windows_license,
        ":_install_tree_windows_marker",
    ] + (
        windows_core_libraries +
        windows_runtime_libraries +
        windows_venv_launchers +
        _extension_labels(extensions.install_only_windows)
    )

    copy_to_directory(
        name = "install_tree",
        srcs = common_sources + install_metadata + select({
            "@platforms//os:macos": posix_sources + _extension_labels(extensions.install_only_darwin),
            ":linux_arm64": posix_sources + _extension_labels(extensions.install_only_linux_arm64),
            ":linux_x86_64": posix_sources + _extension_labels(extensions.install_only_linux_x86_64),
            "@platforms//os:windows": windows_sources,
        }),
        out = "install",
        hardlink = "off",
        include_external_repositories = ["*msvc_runtime*"],
        replace_prefixes = select({
            "@platforms//os:macos": _posix_replacements(version, extensions.install_only_darwin),
            ":linux_arm64": _posix_replacements(version, extensions.install_only_linux_arm64),
            ":linux_x86_64": _posix_replacements(version, extensions.install_only_linux_x86_64),
            "@platforms//os:windows": _windows_replacements(version, extensions.install_only_windows),
        }),
        root_paths = [
            ".",
            "runtime/build/lib.*-*",
            "sysroot/Contents/VC/Redist/MSVC/*/*/Microsoft.VC*.CRT",
        ],
        visibility = ["//visibility:private"],
    )

    sh_test(
        name = "install_tree_test",
        srcs = ["@cpython//python/private:install_tree_test.sh"],
        args = [
            "$(rlocationpath :install_tree)",
            version,
        ],
        data = [
            ":install_tree",
            "@bazel_tools//tools/bash/runfiles",
        ],
        visibility = ["//visibility:private"],
    )
