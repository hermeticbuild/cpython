"""Shared CPython test extensions required by Modules/Setup.stdlib.in."""

load("@rules_cc//cc:cc_binary.bzl", "cc_binary")

_TESTCAPI_3_13_SOURCES = [
    "Modules/_testcapimodule.c",
    "Modules/_testcapi/vectorcall.c",
    "Modules/_testcapi/heaptype.c",
    "Modules/_testcapi/abstract.c",
    "Modules/_testcapi/unicode.c",
    "Modules/_testcapi/dict.c",
    "Modules/_testcapi/set.c",
    "Modules/_testcapi/list.c",
    "Modules/_testcapi/tuple.c",
    "Modules/_testcapi/getargs.c",
    "Modules/_testcapi/datetime.c",
    "Modules/_testcapi/docstring.c",
    "Modules/_testcapi/mem.c",
    "Modules/_testcapi/watchers.c",
    "Modules/_testcapi/long.c",
    "Modules/_testcapi/float.c",
    "Modules/_testcapi/complex.c",
    "Modules/_testcapi/numbers.c",
    "Modules/_testcapi/structmember.c",
    "Modules/_testcapi/exceptions.c",
    "Modules/_testcapi/code.c",
    "Modules/_testcapi/buffer.c",
    "Modules/_testcapi/pyatomic.c",
    "Modules/_testcapi/run.c",
    "Modules/_testcapi/file.c",
    "Modules/_testcapi/codec.c",
    "Modules/_testcapi/immortal.c",
    "Modules/_testcapi/gc.c",
    "Modules/_testcapi/hash.c",
    "Modules/_testcapi/time.c",
    "Modules/_testcapi/bytes.c",
    "Modules/_testcapi/object.c",
    "Modules/_testcapi/monitoring.c",
]

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
        "_testcapi": {
            "core_module": True,
            "srcs": _TESTCAPI_3_13_SOURCES,
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
    """Defines Linux shared test extensions and returns their target labels.

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

        # The shared extension retains undefined Python API symbols. The
        # --export-dynamic Python interpreter resolves those symbols at dlopen.
        cc_binary(
            name = output,
            srcs = extension["srcs"],
            copts = [
                "-std=c11",
                "-fwrapv",
            ],
            deps = [headers],
            linkshared = True,
            local_defines = ["Py_BUILD_CORE_MODULE=1"] if extension["core_module"] else [],
            target_compatible_with = ["@platforms//os:linux"],
            visibility = ["//visibility:public"],
        )
        outputs.append(":" + output)

    return outputs
