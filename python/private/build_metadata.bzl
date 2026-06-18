"""CPython 3.14 runtime build metadata generation."""

load("@bazel_lib//lib:copy_to_directory.bzl", "copy_to_directory")

def cpython_build_metadata(version):
    """Defines CPython 3.14 runtime build metadata targets."""
    if version != "3.14":
        return struct(install_data = [], runtime_data = [], test_data = [])

    posix_target_compatible_with = select({
        "@platforms//os:linux": [],
        "@platforms//os:macos": [],
        "//conditions:default": ["@platforms//:incompatible"],
    })

    native.filegroup(
        name = "install_build_details",
        srcs = [":generated_sysconfig"],
        output_group = "build_details",
        target_compatible_with = posix_target_compatible_with,
    )

    native.filegroup(
        name = "runtime_sysconfig_json",
        srcs = [":generated_sysconfig"],
        output_group = "sysconfig_json",
        target_compatible_with = posix_target_compatible_with,
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

    install_data = select({
        "@platforms//os:linux": [
            ":install_build_details",
            ":runtime_sysconfig_json",
        ],
        "@platforms//os:macos": [
            ":install_build_details",
            ":runtime_sysconfig_json",
        ],
        "//conditions:default": [],
    })

    return struct(
        install_data = install_data,
        runtime_data = select({
            "@platforms//os:linux": [
                ":runtime_sysconfig_json",
            ],
            "@platforms//os:macos": [
                ":runtime_sysconfig_json",
            ],
            "//conditions:default": [],
        }),
        test_data = select({
            "@platforms//os:linux": [
                ":runtime_test_tools",
            ],
            "@platforms//os:macos": [
                ":runtime_test_tools",
            ],
            "//conditions:default": [],
        }),
    )
