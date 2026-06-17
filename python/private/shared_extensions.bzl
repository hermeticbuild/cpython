"""Shared CPython test extensions required by Modules/Setup.stdlib.in."""

load("@rules_cc//cc:cc_binary.bzl", "cc_binary")

_COMMON_EXTENSIONS = {
    "_ctypes_test": {
        "core_module": False,
        "srcs": ["Modules/_ctypes/_ctypes_test.c"],
    },
    "_testimportmultiple": {
        "core_module": False,
        "srcs": ["Modules/_testimportmultiple.c"],
    },
    "_testmultiphase": {
        "core_module": True,
        "srcs": ["Modules/_testmultiphase.c"],
    },
    "xxlimited": {
        "core_module": False,
        "srcs": ["Modules/xxlimited.c"],
    },
    "xxlimited_35": {
        "core_module": False,
        "srcs": ["Modules/xxlimited_35.c"],
    },
}

_VERSION_EXTENSIONS = {
    "3.11": {},
    "3.12": {
        "_testsinglephase": {
            "core_module": True,
            "srcs": ["Modules/_testsinglephase.c"],
        },
    },
    "3.13": {
        "_testsinglephase": {
            "core_module": True,
            "srcs": ["Modules/_testsinglephase.c"],
        },
        "_testexternalinspection": {
            "core_module": True,
            "srcs": ["Modules/_testexternalinspection.c"],
        },
    },
    "3.14": {
        "_testsinglephase": {
            "core_module": True,
            "srcs": ["Modules/_testsinglephase.c"],
        },
    },
}

def shared_test_extensions(version, headers = ":headers"):
    """Defines POSIX shared test extensions and returns their target labels.

    The xxlimited sources define their own Py_LIMITED_API values. Python 3.13's
    _testimportmultiple.c also defines Py_LIMITED_API. The other public
    extension sources compile without Py_BUILD_CORE_MODULE.

    Args:
      version: Supported CPython minor version.
      headers: cc_library target containing Python.h, pyconfig.h, internal
        headers, and generated Clinic headers.

    Returns:
      Labels for the generated <module>.so targets, suitable for runtime data.
    """
    if version not in _VERSION_EXTENSIONS:
        fail("shared_test_extensions does not support CPython %s" % version)

    extensions = dict(_COMMON_EXTENSIONS)
    extensions.update(_VERSION_EXTENSIONS[version])

    outputs = []
    for module_name in sorted(extensions):
        extension = extensions[module_name]
        output = module_name + ".so"

        # The shared extension retains undefined Python API symbols. The Python
        # interpreter resolves those symbols when it loads the extension.
        cc_binary(
            name = output,
            srcs = extension["srcs"],
            copts = [
                "-std=c11",
                "-fwrapv",
            ],
            deps = [headers],
            linkshared = True,
            linkopts = select({
                "@platforms//os:macos": ["-Wl,-undefined,dynamic_lookup"],
                "//conditions:default": [],
            }),
            local_defines = ["Py_BUILD_CORE_MODULE=1"] if extension["core_module"] else [],
            target_compatible_with = select({
                "@platforms//os:linux": [],
                "@platforms//os:macos": [],
                "//conditions:default": ["@platforms//:incompatible"],
            }),
            visibility = ["//visibility:public"],
        )
        outputs.append(":" + output)

    return outputs
