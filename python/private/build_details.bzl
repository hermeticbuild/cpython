"""CPython 3.14 build-details.json generation."""

load("@bazel_lib//lib:copy_to_directory.bzl", "copy_to_directory")
load("@bazel_lib//lib:run_binary.bzl", "run_binary")
load("@rules_cc//cc:cc_binary.bzl", "cc_binary")

def cpython_build_details(version, runtime_data, runtime_deps, core_copts, linkopts):
    """Defines CPython 3.14 build-details.json targets.

    Args:
      version: Supported CPython minor version.
      runtime_data: Runtime files required by the bootstrap interpreter.
      runtime_deps: Libraries linked into the bootstrap interpreter.
      core_copts: Compiler options used by the main interpreter.
      linkopts: Linker options used by the main interpreter.

    Returns:
      A struct containing runtime_data and test_data label lists.
    """
    if version != "3.14":
        return struct(runtime_data = [], test_data = [])

    posix_target_compatible_with = select({
        "@platforms//os:linux": [],
        "@platforms//os:macos": [],
        "//conditions:default": ["@platforms//:incompatible"],
    })

    cc_binary(
        name = "runtime/python_for_build_details",
        srcs = ["Programs/python.c"],
        copts = core_copts,
        data = runtime_data,
        deps = runtime_deps,
        linkopts = linkopts,
        target_compatible_with = posix_target_compatible_with,
    )

    run_binary(
        name = "runtime_build_details",
        srcs = [
            ":runtime/python_for_build_details",
            "Tools/build/generate-build-details.py",
        ] + runtime_data,
        outs = ["runtime/build-details.json"],
        args = [
            "$(execpath :runtime/python_for_build_details)",
            "$(execpath Tools/build/generate-build-details.py)",
            "$(execpath runtime/build-details.json)",
        ],
        execution_requirements = {"no-remote-exec": "1"},
        target_compatible_with = posix_target_compatible_with,
        tool = "@cpython//python/private:generate_build_details",
    )

    copy_to_directory(
        name = "runtime_test_tools",
        srcs = ["Tools/build/generate-build-details.py"],
        out = "runtime/Tools",
        root_paths = ["Tools"],
        target_compatible_with = posix_target_compatible_with,
    )

    return struct(
        runtime_data = select({
            "@platforms//os:linux": [":runtime_build_details"],
            "@platforms//os:macos": [":runtime_build_details"],
            "//conditions:default": [],
        }),
        test_data = select({
            "@platforms//os:linux": [":runtime_test_tools"],
            "@platforms//os:macos": [":runtime_test_tools"],
            "//conditions:default": [],
        }),
    )
