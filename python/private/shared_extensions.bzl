"""Shared CPython extensions required by the POSIX test runtimes."""

load("@cpython//python/private:modules.bzl", "testcapi_sources")
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
        "_testcapi": {
            "core_module": True,
            "srcs": ["Modules/" + source for source in testcapi_sources("3.13")],
        },
        "_testexternalinspection": {
            "core_module": True,
            "srcs": ["Modules/_testexternalinspection.c"],
        },
        "_testsinglephase": {
            "core_module": True,
            "srcs": ["Modules/_testsinglephase.c"],
        },
    },
    "3.14": {
        "_testcapi": {
            "core_module": True,
            "srcs": ["Modules/" + source for source in testcapi_sources("3.14")],
        },
        "_testsinglephase": {
            "core_module": True,
            "srcs": ["Modules/_testsinglephase.c"],
        },
    },
}

_POSIX_COMPATIBILITY = select({
    "@platforms//os:linux": [],
    "@platforms//os:macos": [],
    "//conditions:default": ["@platforms//:incompatible"],
})

def _shared_extension(name, srcs, headers, core_module, target_compatible_with):
    # The shared extension retains undefined Python API symbols. The Python
    # interpreter resolves those symbols when it loads the extension.
    cc_binary(
        name = name,
        srcs = srcs,
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
        local_defines = ["Py_BUILD_CORE_MODULE=1"] if core_module else [],
        target_compatible_with = target_compatible_with,
        visibility = ["//visibility:public"],
    )

def shared_extensions(version, soabi, headers = ":headers"):
    """Defines POSIX shared extensions and returns their runtime labels."""
    if version not in _VERSION_EXTENSIONS:
        fail("shared_extensions does not support CPython %s" % version)

    extensions = dict(_COMMON_EXTENSIONS)
    extensions.update(_VERSION_EXTENSIONS[version])

    common_outputs = []
    for module_name in sorted(extensions):
        extension = extensions[module_name]
        output = module_name + ".so"
        _shared_extension(
            name = output,
            srcs = extension["srcs"],
            headers = headers,
            core_module = extension["core_module"],
            target_compatible_with = _POSIX_COMPATIBILITY,
        )
        common_outputs.append(":" + output)

    darwin_outputs = common_outputs
    linux_arm64_outputs = common_outputs
    linux_x86_64_outputs = common_outputs
    if version == "3.14":
        asyncio_darwin = "_asyncio.%s-darwin.so" % soabi
        asyncio_linux_arm64 = "_asyncio.%s-aarch64-linux-gnu.so" % soabi
        asyncio_linux_x86_64 = "_asyncio.%s-x86_64-linux-gnu.so" % soabi
        _shared_extension(
            name = asyncio_darwin,
            srcs = ["Modules/_asynciomodule.c"],
            headers = headers,
            core_module = True,
            target_compatible_with = ["@platforms//os:macos"],
        )
        _shared_extension(
            name = asyncio_linux_arm64,
            srcs = ["Modules/_asynciomodule.c"],
            headers = headers,
            core_module = True,
            target_compatible_with = [
                "@platforms//cpu:aarch64",
                "@platforms//os:linux",
            ],
        )
        _shared_extension(
            name = asyncio_linux_x86_64,
            srcs = ["Modules/_asynciomodule.c"],
            headers = headers,
            core_module = True,
            target_compatible_with = [
                "@platforms//cpu:x86_64",
                "@platforms//os:linux",
            ],
        )
        darwin_outputs = common_outputs + [":" + asyncio_darwin]
        linux_arm64_outputs = common_outputs + [":" + asyncio_linux_arm64]
        linux_x86_64_outputs = common_outputs + [":" + asyncio_linux_x86_64]

    return struct(
        darwin_arm64 = darwin_outputs,
        darwin_x86_64 = darwin_outputs,
        linux_arm64 = linux_arm64_outputs,
        linux_x86_64 = linux_x86_64_outputs,
    )
