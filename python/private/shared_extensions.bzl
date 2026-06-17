"""Shared CPython extensions required by the test runtimes."""

load("@cpython//python/private:modules.bzl", "ctypes_sources", "testcapi_sources")
load("@rules_cc//cc:cc_binary.bzl", "cc_binary")

_COMMON_EXTENSIONS = {
    # PC/dl_nt.c and Modules/_ctypes/callbacks.c both define DllMain.
    # CPython PCbuild places them in pythonXY.dll and _ctypes.pyd, respectively.
    "_ctypes": {
        "core_module": False,
        "deps": ["@cpython_libffi//:libffi"],
        "local_defines_by_version": {
            "3.11": [
                "HAVE_FFI_CLOSURE_ALLOC=1",
                "HAVE_FFI_PREP_CIF_VAR=1",
                "HAVE_FFI_PREP_CLOSURE_LOC=1",
            ],
        },
        "posix": False,
        "srcs": ["Modules/" + source for source in ctypes_sources()],
        "windows_linkopts": [
            "/EXPORT:DllGetClassObject,PRIVATE",
            "/EXPORT:DllCanUnloadNow,PRIVATE",
        ],
    },
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

_TESTCLINIC_LIMITED_EXTENSION = {
    # _testclinic_limited.c undefines Py_BUILD_CORE and links through
    # pythonXY.lib. CPython PCbuild therefore builds it as a .pyd.
    "core_module": False,
    "posix": False,
    "srcs": ["Modules/_testclinic_limited.c"],
}

_VERSION_EXTENSIONS = {
    "3.11": {
        "_testcapi": {
            "core_module": True,
            "srcs": ["Modules/" + source for source in testcapi_sources("3.11")],
        },
    },
    "3.12": {
        "_testcapi": {
            "core_module": True,
            "srcs": ["Modules/" + source for source in testcapi_sources("3.12")],
        },
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
            "windows": False,
        },
        "_testclinic_limited": _TESTCLINIC_LIMITED_EXTENSION,
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
        "_testclinic_limited": _TESTCLINIC_LIMITED_EXTENSION,
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

_WINDOWS_COMPATIBILITY = select({
    "@platforms//os:windows": [],
    "//conditions:default": ["@platforms//:incompatible"],
})

_WINDOWS_SYSTEM_LINKOPTS = [
    "advapi32.lib",
    "ole32.lib",
    "oleaut32.lib",
    "shell32.lib",
]

def _shared_extension(
        name,
        srcs,
        headers,
        core_module,
        target_compatible_with,
        deps = [],
        local_defines = []):
    # The shared extension retains undefined Python API symbols. The Python
    # interpreter resolves those symbols when it loads the extension.
    cc_binary(
        name = name,
        srcs = srcs,
        copts = [
            "-std=c11",
            "-fwrapv",
        ],
        deps = [headers] + deps,
        linkshared = True,
        linkopts = select({
            "@platforms//os:macos": ["-Wl,-undefined,dynamic_lookup"],
            "//conditions:default": [],
        }),
        local_defines = (["Py_BUILD_CORE_MODULE=1"] if core_module else []) + local_defines,
        target_compatible_with = target_compatible_with,
        visibility = ["//visibility:public"],
    )

def _windows_extension(
        name,
        srcs,
        headers,
        core_module,
        python_import,
        python_import_library,
        stable_abi,
        stable_import,
        version_abi,
        extra_deps = [],
        extra_linkopts = [],
        extra_local_defines = []):
    deps = [headers] + extra_deps
    linkopts = (
        ["/NODEFAULTLIB:" + python_import_library] +
        _WINDOWS_SYSTEM_LINKOPTS +
        extra_linkopts
    )
    if version_abi:
        deps.append(python_import)
    if stable_abi:
        deps.append(stable_import)
        linkopts.append("/NODEFAULTLIB:python3.lib")

    cc_binary(
        name = name,
        srcs = srcs,
        copts = [
            "/std:c11",
            "/O2",
            "-fwrapv",
        ],
        deps = deps,
        features = ["no_windows_export_all_symbols"],
        linkopts = linkopts,
        linkshared = True,
        local_defines = (["Py_BUILD_CORE_MODULE=1"] if core_module else []) + extra_local_defines,
        target_compatible_with = _WINDOWS_COMPATIBILITY,
        visibility = ["//visibility:public"],
    )

def shared_extensions(
        version,
        soabi,
        headers = ":headers",
        python_import = None,
        python_import_library = None,
        stable_import = None):
    """Defines shared extensions and returns their runtime labels.

    Args:
      version: The CPython minor version.
      soabi: The POSIX extension-module ABI tag.
      headers: The CPython header target.
      python_import: The versioned Windows CPython import-library target.
      python_import_library: The versioned Windows import-library filename.
      stable_import: The Windows stable-ABI import-library target.

    Returns:
      Platform-specific lists of shared-extension labels.
    """
    if version not in _VERSION_EXTENSIONS:
        fail("shared_extensions does not support CPython %s" % version)

    extensions = dict(_COMMON_EXTENSIONS)
    extensions.update(_VERSION_EXTENSIONS[version])

    common_outputs = []
    windows_outputs = []
    for module_name in sorted(extensions):
        extension = extensions[module_name]
        local_defines = extension.get("local_defines_by_version", {}).get(version, [])
        if extension.get("posix", True):
            output = module_name + ".so"
            _shared_extension(
                name = output,
                srcs = extension["srcs"],
                headers = headers,
                core_module = extension["core_module"],
                deps = extension.get("deps", []),
                local_defines = local_defines,
                target_compatible_with = _POSIX_COMPATIBILITY,
            )
            common_outputs.append(":" + output)

        if extension.get("windows", True):
            windows_output = module_name + ".pyd"
            stable_abi = module_name in ["xxlimited", "xxlimited_35"]
            version_abi = not stable_abi
            _windows_extension(
                name = windows_output,
                srcs = extension["srcs"],
                headers = headers,
                core_module = extension["core_module"],
                python_import = python_import,
                python_import_library = python_import_library,
                stable_abi = stable_abi,
                stable_import = stable_import,
                version_abi = version_abi,
                extra_deps = extension.get("deps", []),
                extra_linkopts = extension.get("windows_linkopts", []),
                extra_local_defines = local_defines,
            )
            windows_outputs.append(":" + windows_output)

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

        asyncio_windows = "_asyncio.pyd"
        _windows_extension(
            name = asyncio_windows,
            srcs = ["Modules/_asynciomodule.c"],
            headers = headers,
            core_module = True,
            python_import = python_import,
            python_import_library = python_import_library,
            stable_abi = False,
            stable_import = stable_import,
            version_abi = True,
        )
        windows_outputs.append(":" + asyncio_windows)

    testconsole = "_testconsole.pyd"
    _windows_extension(
        name = testconsole,
        srcs = ["PC/_testconsole.c"],
        headers = headers,
        core_module = False,
        python_import = python_import,
        python_import_library = python_import_library,
        stable_abi = False,
        stable_import = stable_import,
        version_abi = True,
    )
    windows_outputs.append(":" + testconsole)

    return struct(
        darwin_arm64 = darwin_outputs,
        darwin_x86_64 = darwin_outputs,
        linux_arm64 = linux_arm64_outputs,
        linux_x86_64 = linux_x86_64_outputs,
        windows = windows_outputs,
    )
