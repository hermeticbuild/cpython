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

def native_test_programs(version, core, headers, frozen, linkopts = []):
    """Defines CPython native test programs and returns their target labels.

    Programs/test_frozenmain.h is the generated frozen-main helper checked into
    each pinned CPython release. The macro declares that header as a direct input
    instead of running Programs/freeze_test_frozenmain.py.

    Args:
      version: Supported CPython minor version.
      core: cc_library target containing the CPython core objects and required
        transitive linker inputs.
      headers: cc_library target containing CPython public and internal headers.
      frozen: cc_library target containing CPython frozen modules and getpath.
      linkopts: Platform link options required by the CPython core.

    Returns:
      Labels for the native test-program targets, suitable for runtime data.
    """
    if version not in _TEST_PROGRAMS:
        fail("native_test_programs does not support CPython %s" % version)

    outputs = []
    for output in sorted(_TEST_PROGRAMS[version]):
        cc_binary(
            name = output,
            srcs = _TEST_PROGRAMS[version][output],
            copts = [
                "-std=c11",
                "-fwrapv",
            ],
            deps = [
                core,
                headers,
                frozen,
            ],
            local_defines = [
                "Py_BUILD_CORE=1",
                "Py_BUILD_CORE_MODULE=1",
            ],
            linkopts = linkopts,
            visibility = ["//visibility:public"],
        )
        outputs.append(":" + output)

    return outputs
