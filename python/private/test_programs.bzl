"""Native test programs required by the CPython standard-library tests."""

load("@rules_cc//cc:cc_binary.bzl", "cc_binary")

_TEST_PROGRAMS = {
    "3.11": {
        "Programs/_testembed": [
            "Programs/_testembed.c",
            "Programs/test_frozenmain.h",
        ],
    },
    "3.12": {
        "Programs/_testembed": [
            "Programs/_testembed.c",
            "Programs/test_frozenmain.h",
        ],
    },
    "3.13": {
        "Programs/_testembed": [
            "Programs/_testembed.c",
            "Programs/test_frozenmain.h",
        ],
    },
    "3.14": {
        "Programs/_testembed": [
            "Programs/_testembed.c",
            "Programs/test_frozenmain.h",
        ],
    },
}

def native_test_programs(version, deps, linkopts = [], local_defines = []):
    """Defines CPython native test programs and returns their target labels.

    Programs/test_frozenmain.h is the generated frozen-main helper checked into
    each pinned CPython release. The macro declares that header as a direct input
    instead of running Programs/freeze_test_frozenmain.py.

    Args:
      version: Supported CPython minor version.
      deps: C++ dependencies required by each native test program.
      linkopts: Platform link options required by the CPython core.
      local_defines: Preprocessor definitions for each native test program.

    Returns:
      Labels for the native test-program targets, suitable for runtime data.
    """
    if version not in _TEST_PROGRAMS:
        fail("native_test_programs does not support CPython %s" % version)

    posix_outputs = []
    windows_outputs = []
    for output in sorted(_TEST_PROGRAMS[version]):
        cc_binary(
            name = output,
            srcs = _TEST_PROGRAMS[version][output],
            copts = [
                "-std=c11",
                "-fwrapv",
            ],
            deps = deps,
            local_defines = local_defines,
            linkopts = linkopts,
            target_compatible_with = select({
                "@platforms//os:linux": [],
                "@platforms//os:macos": [],
                "//conditions:default": ["@platforms//:incompatible"],
            }),
            visibility = ["//visibility:public"],
        )
        posix_outputs.append(":" + output)

        windows_output = "runtime/" + output.split("/")[-1]
        cc_binary(
            name = windows_output,
            srcs = _TEST_PROGRAMS[version][output],
            copts = [
                "-std=c11",
                "-fwrapv",
            ],
            deps = deps,
            local_defines = local_defines,
            linkopts = linkopts,
            target_compatible_with = ["@platforms//os:windows"],
            visibility = ["//visibility:public"],
        )
        windows_outputs.append(":" + windows_output)

    return select({
        "@platforms//os:windows": windows_outputs,
        "//conditions:default": posix_outputs,
    })
