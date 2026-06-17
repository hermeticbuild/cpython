"""CPython 3.14 runtime build metadata generation."""

load("@bazel_lib//lib:copy_to_directory.bzl", "copy_to_directory")
load("@bazel_lib//lib:run_binary.bzl", "run_binary")
load("@rules_cc//cc:cc_binary.bzl", "cc_binary")

def cpython_build_metadata(version, runtime_data, runtime_deps, core_copts, linkopts):
    """Defines CPython 3.14 runtime build metadata targets."""
    if version != "3.14":
        return struct(runtime_data = [], test_data = [])

    posix_target_compatible_with = select({
        "@platforms//os:linux": [],
        "@platforms//os:macos": [],
        "//conditions:default": ["@platforms//:incompatible"],
    })

    cc_binary(
        name = "runtime/python_for_build_metadata",
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
            ":runtime/python_for_build_metadata",
            "Tools/build/generate-build-details.py",
        ] + runtime_data,
        outs = ["runtime/build-details.json"],
        args = [
            "$(execpath :runtime/python_for_build_metadata)",
            "$(execpath Tools/build/generate-build-details.py)",
            "$@",
        ],
        execution_requirements = {"no-remote-exec": "1"},
        target_compatible_with = posix_target_compatible_with,
        tool = "@cpython//python/private:run_target_python",
    )

    run_binary(
        name = "runtime_sysconfig_json",
        srcs = [
            ":runtime/python_for_build_metadata",
            "@cpython//python/private:generate_sysconfig_json.py",
        ] + runtime_data,
        out_dirs = ["runtime/build"],
        args = [
            "$(execpath :runtime/python_for_build_metadata)",
            "$(execpath @cpython//python/private:generate_sysconfig_json.py)",
            "$@",
        ],
        env = {
            "PYTHONHASHSEED": "0",
            "PYTHONNOUSERSITE": "1",
        },
        execution_requirements = {"no-remote-exec": "1"},
        target_compatible_with = posix_target_compatible_with,
        tool = "@cpython//python/private:run_target_python",
    )

    copy_to_directory(
        name = "runtime_test_tools",
        srcs = [
            "Tools/build/compute-changes.py",
            "Tools/build/generate-build-details.py",
        ],
        out = "runtime/Tools",
        root_paths = ["Tools"],
        target_compatible_with = posix_target_compatible_with,
    )

    return struct(
        runtime_data = select({
            "@platforms//os:linux": [
                ":runtime_build_details",
                ":runtime_sysconfig_json",
            ],
            "@platforms//os:macos": [
                ":runtime_build_details",
                ":runtime_sysconfig_json",
            ],
            "//conditions:default": [],
        }),
        test_data = select({
            "@platforms//os:linux": [":runtime_test_tools"],
            "@platforms//os:macos": [":runtime_test_tools"],
            "//conditions:default": [],
        }),
    )
