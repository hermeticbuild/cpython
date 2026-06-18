"""Shared CPython extensions required by the test runtimes."""

load("@rules_cc//cc:cc_binary.bzl", "cc_binary")

_VERSIONED_WINDOWS_IMPORT = "versioned"
_STABLE_WINDOWS_IMPORT = "stable"

_INSTALL_ONLY_EXCLUDED_EXTENSIONS = [
    "_ctypes_test",
    "_testbuffer",
    "_testcapi",
    "_testclinic",
    "_testclinic_limited",
    "_testconsole",
    "_testembed",
    "_testexternalinspection",
    "_testimportmultiple",
    "_testinternalcapi",
    "_testlimitedcapi",
    "_testmultiphase",
    "_testsinglephase",
    "xxlimited",
    "xxlimited_35",
]

def _install_only_extension(label, filename):
    return struct(
        filename = filename,
        label = label,
    )

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
        "source_variables_by_version": {
            "3.12": ["MODULE__CTYPES_MALLOC_CLOSURE"],
            "3.13": ["MODULE__CTYPES_MALLOC_CLOSURE"],
            "3.14": ["MODULE__CTYPES_MALLOC_CLOSURE"],
        },
        "windows_linkopts": [
            "/EXPORT:DllGetClassObject,PRIVATE",
            "/EXPORT:DllCanUnloadNow,PRIVATE",
        ],
    },
    "_ctypes_test": {
        "core_module": False,
    },
    "_sqlite3": {
        "core_module": True,
        "deps": [":sqlite3_dll_import"],
        "local_defines": [
            "PY_SQLITE_ENABLE_LOAD_EXTENSION=1",
            "PY_SQLITE_HAVE_SERIALIZE=1",
        ],
        "posix": False,
    },
    "_testimportmultiple": {
        "core_module": False,
    },
    "_testmultiphase": {
        "core_module": True,
    },
    "xxlimited": {
        "core_module": False,
        "windows_imports": [_STABLE_WINDOWS_IMPORT],
    },
    "xxlimited_35": {
        "core_module": False,
        "windows_imports": [_STABLE_WINDOWS_IMPORT],
    },
}

_TESTCLINIC_LIMITED_EXTENSION = {
    # _testclinic_limited.c undefines Py_BUILD_CORE and links through
    # pythonXY.lib. CPython PCbuild therefore builds it as a .pyd.
    "core_module": False,
    "posix": False,
}

_WMI_EXTENSION = {
    "core_module": False,
    "posix": False,
    "windows_copts": [
        "/std:c++20",
        "/O2",
        "-fwrapv",
    ],
    "windows_linkopts": [
        "propsys.lib",
        "wbemuuid.lib",
    ],
}

_VERSION_EXTENSIONS = {
    "3.11": {
        "_testcapi": {
            "core_module": True,
        },
    },
    "3.12": {
        "_testcapi": {
            "core_module": True,
            "windows_imports": [
                _VERSIONED_WINDOWS_IMPORT,
                _STABLE_WINDOWS_IMPORT,
            ],
        },
        "_testsinglephase": {
            "core_module": True,
        },
        "_wmi": _WMI_EXTENSION,
    },
    "3.13": {
        "_testcapi": {
            "core_module": True,
        },
        "_testexternalinspection": {
            "core_module": True,
            "windows": False,
        },
        "_testclinic_limited": _TESTCLINIC_LIMITED_EXTENSION,
        "_testsinglephase": {
            "core_module": True,
        },
        "_wmi": _WMI_EXTENSION,
    },
    "3.14": {
        "_testcapi": {
            "core_module": True,
        },
        "_testclinic_limited": _TESTCLINIC_LIMITED_EXTENSION,
        "_testsinglephase": {
            "core_module": True,
        },
        "_wmi": _WMI_EXTENSION,
    },
}

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

_WINDOWS_COPTS = [
    "/std:c11",
    "/O2",
    "-fwrapv",
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
        stable_import,
        windows_imports,
        copts = _WINDOWS_COPTS,
        extra_deps = [],
        extra_linkopts = [],
        extra_local_defines = []):
    deps = [headers] + extra_deps
    linkopts = (
        ["/NODEFAULTLIB:" + python_import_library] +
        _WINDOWS_SYSTEM_LINKOPTS +
        extra_linkopts
    )
    for windows_import in windows_imports:
        if windows_import == _VERSIONED_WINDOWS_IMPORT:
            deps.append(python_import)
        elif windows_import == _STABLE_WINDOWS_IMPORT:
            deps.append(stable_import)
            linkopts.append("/NODEFAULTLIB:python3.lib")
        else:
            fail("Unsupported Windows import: %s" % windows_import)

    cc_binary(
        name = name,
        srcs = srcs,
        copts = copts,
        deps = deps,
        features = ["no_windows_export_all_symbols"],
        linkopts = linkopts,
        linkshared = True,
        local_defines = (["Py_BUILD_CORE_MODULE=1"] if core_module else []) + extra_local_defines,
        target_compatible_with = _WINDOWS_COMPATIBILITY,
        visibility = ["//visibility:public"],
    )

def _extension_sources(module_name, extension, module_sources, version):
    if module_name not in module_sources:
        fail("CPython shared extension {} has no generated source membership".format(
            repr(module_name),
        ))
    generated = module_sources[module_name]
    expected_source_variables = extension.get("source_variables_by_version", {}).get(version, [])
    if generated.source_variables != expected_source_variables:
        fail("CPython shared extension {} has source variables {}; expected {} for CPython {}".format(
            repr(module_name),
            repr(generated.source_variables),
            repr(expected_source_variables),
            version,
        ))
    return struct(
        posix = generated.sources,
        windows = generated.sources + generated.windows_sources,
    )

def shared_extensions(
        version,
        soabi,
        module_sources,
        headers = ":headers",
        python_import = None,
        python_import_library = None,
        stable_import = None):
    """Defines shared extensions and returns their runtime labels.

    Args:
      version: The CPython minor version.
      soabi: The POSIX extension-module ABI tag.
      module_sources: Generated source membership for the pinned release.
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
    if version == "3.14":
        extensions["_asyncio"] = {
            "core_module": True,
        }

    posix_targets = [
        struct(
            compatibility = ["@platforms//os:macos"],
            name = "darwin",
            suffix = ".{}-darwin.so".format(soabi),
        ),
        struct(
            compatibility = [
                "@platforms//cpu:aarch64",
                "@platforms//os:linux",
            ],
            name = "linux_arm64",
            suffix = ".{}-aarch64-linux-gnu.so".format(soabi),
        ),
        struct(
            compatibility = [
                "@platforms//cpu:x86_64",
                "@platforms//os:linux",
            ],
            name = "linux_x86_64",
            suffix = ".{}-x86_64-linux-gnu.so".format(soabi),
        ),
    ]
    posix_outputs = {target.name: [] for target in posix_targets}
    install_only_posix_outputs = {target.name: [] for target in posix_targets}
    windows_outputs = [":sqlite3_dll"]
    install_only_windows_outputs = [_install_only_extension(":sqlite3_dll", "sqlite3.dll")]
    for module_name in sorted(extensions):
        extension = extensions[module_name]
        extension_sources = _extension_sources(module_name, extension, module_sources, version)
        local_defines = (
            extension.get("local_defines", []) +
            extension.get("local_defines_by_version", {}).get(version, [])
        )
        if extension.get("posix", True):
            for posix_target in posix_targets:
                output = module_name + posix_target.suffix
                _shared_extension(
                    name = output,
                    srcs = extension_sources.posix,
                    headers = headers,
                    core_module = extension["core_module"],
                    deps = extension.get("deps", []),
                    local_defines = local_defines,
                    target_compatible_with = posix_target.compatibility,
                )
                posix_outputs[posix_target.name].append(":" + output)
                if module_name not in _INSTALL_ONLY_EXCLUDED_EXTENSIONS:
                    install_only_posix_outputs[posix_target.name].append(_install_only_extension(":" + output, output))

        if extension.get("windows", True):
            windows_output = module_name + ".pyd"
            _windows_extension(
                name = windows_output,
                srcs = extension_sources.windows,
                headers = headers,
                core_module = extension["core_module"],
                python_import = python_import,
                python_import_library = python_import_library,
                stable_import = stable_import,
                windows_imports = extension.get("windows_imports", [_VERSIONED_WINDOWS_IMPORT]),
                copts = extension.get("windows_copts", _WINDOWS_COPTS),
                extra_deps = extension.get("deps", []),
                extra_linkopts = extension.get("windows_linkopts", []),
                extra_local_defines = local_defines,
            )
            windows_outputs.append(":" + windows_output)
            if module_name not in _INSTALL_ONLY_EXCLUDED_EXTENSIONS:
                install_only_windows_outputs.append(_install_only_extension(":" + windows_output, windows_output))

    testconsole = "_testconsole.pyd"
    testconsole_sources = _extension_sources("_testconsole", {}, module_sources, version)
    _windows_extension(
        name = testconsole,
        srcs = testconsole_sources.windows,
        headers = headers,
        core_module = False,
        python_import = python_import,
        python_import_library = python_import_library,
        stable_import = stable_import,
        windows_imports = [_VERSIONED_WINDOWS_IMPORT],
    )
    windows_outputs.append(":" + testconsole)

    return struct(
        darwin_arm64 = posix_outputs["darwin"],
        darwin_x86_64 = posix_outputs["darwin"],
        install_only_darwin_arm64 = install_only_posix_outputs["darwin"],
        install_only_darwin_x86_64 = install_only_posix_outputs["darwin"],
        install_only_linux_arm64 = install_only_posix_outputs["linux_arm64"],
        install_only_linux_x86_64 = install_only_posix_outputs["linux_x86_64"],
        install_only_windows = install_only_windows_outputs,
        linux_arm64 = posix_outputs["linux_arm64"],
        linux_x86_64 = posix_outputs["linux_x86_64"],
        windows = windows_outputs,
    )
