"""Static CPython module manifests for the pinned supported releases."""

load("@cpython//python/private:versions.bzl", "SUPPORTED_PYTHON_VERSIONS")
load("@rules_cc//cc:cc_library.bzl", "cc_library")

_SUPPORTED_CATEGORIES = [
    "bootstrap",
    "bundled",
    "posix",
    "stdlib",
    "test",
]

_CORE_INITTAB = [
    ("marshal", "PyMarshal_Init"),
    ("_imp", "PyInit__imp"),
    ("_ast", "PyInit__ast"),
    ("_tokenize", "PyInit__tokenize"),
    ("builtins", None),
    ("sys", None),
    ("gc", "PyInit_gc"),
    ("_warnings", "_PyWarnings_Init"),
    ("_string", "PyInit__string"),
]

def _module(
        name,
        category,
        init_symbol = None,
        copts = [],
        includes = [],
        deps = [],
        excluded_sources = [],
        linkopts = [],
        platform = "all",
        source_variables_by_version = {},
        source_name = None):
    return struct(
        category = category,
        copts = copts,
        deps = deps,
        excluded_sources = excluded_sources,
        includes = includes,
        init_symbol = init_symbol or "PyInit_{}".format(name),
        linkopts = linkopts,
        name = name,
        platform = platform,
        source_variables_by_version = source_variables_by_version,
        source_name = source_name or name,
    )

_BOOTSTRAP_PREFIX = [
    _module("atexit", "bootstrap"),
    _module("faulthandler", "bootstrap"),
    _module("posix", "bootstrap", platform = "posix"),
    _module("nt", "bootstrap", init_symbol = "PyInit_nt", platform = "windows", source_name = "posix"),
    _module("_winapi", "bootstrap", platform = "windows"),
    _module("winreg", "bootstrap", platform = "windows"),
    _module("_signal", "bootstrap"),
    _module("_tracemalloc", "bootstrap"),
]

_BOOTSTRAP_IMPORT = [
    _module("_codecs", "bootstrap"),
    _module("_collections", "bootstrap"),
    _module("errno", "bootstrap"),
    _module("_io", "bootstrap"),
    _module("itertools", "bootstrap"),
    _module("_sre", "bootstrap"),
]

_BOOTSTRAP_SUFFIX = [
    _module("_thread", "bootstrap"),
    _module("time", "bootstrap"),
    _module("_typing", "bootstrap"),
    _module("_weakref", "bootstrap"),
    _module("_abc", "bootstrap"),
    _module("_functools", "bootstrap"),
    _module("_locale", "bootstrap"),
    _module("_operator", "bootstrap"),
    _module("_stat", "bootstrap"),
    _module("_symtable", "bootstrap"),
    _module("pwd", "bootstrap", platform = "posix"),
]

_STDLIB_COMMON = [
    _module("array", "stdlib"),
    _module(
        "_bz2",
        "stdlib",
        deps = ["@bzip2//:bz2"],
    ),
    _module("_bisect", "stdlib"),
    _module("_csv", "stdlib"),
    _module(
        "_ctypes",
        "stdlib",
        deps = ["@cpython_libffi//:libffi"],
        platform = "posix",
        source_variables_by_version = {
            "3.12": ["MODULE__CTYPES_MALLOC_CLOSURE"],
            "3.13": ["MODULE__CTYPES_MALLOC_CLOSURE"],
            "3.14": ["MODULE__CTYPES_MALLOC_CLOSURE"],
        },
    ),
    _module("_heapq", "stdlib"),
    _module("_json", "stdlib"),
    _module(
        "_hashlib",
        "stdlib",
        deps = ["@openssl//:crypto"],
    ),
    _module(
        "_lzma",
        "stdlib",
        deps = ["@xz//:lzma"],
    ),
    _module("_lsprof", "stdlib"),
    _module("_pickle", "stdlib"),
    _module("_queue", "stdlib"),
    _module("_random", "stdlib"),
    _module("_struct", "stdlib"),
    _module(
        "_ssl",
        "stdlib",
        deps = ["@openssl//:ssl"],
    ),
    _module(
        "_sqlite3",
        "stdlib",
        deps = [":hermetic_sqlite3"],
        platform = "posix",
    ),
    _module("_zoneinfo", "stdlib"),
    _module("math", "stdlib"),
    _module("cmath", "stdlib"),
    _module("_statistics", "stdlib"),
    _module(
        "zlib",
        "stdlib",
        deps = ["@zlib//:zlib"],
    ),
]

_STDLIB_BEFORE_3_14 = [
    _module("_asyncio", "stdlib"),
    _module("_contextvars", "stdlib"),
    _module("_opcode", "stdlib"),
    _module("_datetime", "stdlib"),
]

_STDLIB_3_12 = [
    _module("_xxsubinterpreters", "stdlib"),
    _module("_xxinterpchannels", "stdlib"),
    _module("audioop", "stdlib"),
]

_STDLIB_3_11 = [
    _module("_xxsubinterpreters", "stdlib"),
    _module("audioop", "stdlib"),
]

_STDLIB_3_13 = [
    _module("_interpreters", "stdlib"),
    _module("_interpchannels", "stdlib"),
    _module("_interpqueues", "stdlib"),
]

_STDLIB_3_14 = [
    _module("_asyncio", "stdlib", platform = "windows"),
    _module("_contextvars", "stdlib"),
    _module("_interpreters", "stdlib"),
    _module("_interpchannels", "stdlib"),
    _module("_interpqueues", "stdlib"),
    _module("_remote_debugging", "stdlib"),
]

_BUNDLED_BASE = [
    _module(
        "_decimal",
        "bundled",
        deps = [":bundled_libmpdec"],
    ),
    _module(
        "binascii",
        "bundled",
        copts = ["-DUSE_ZLIB_CRC32=1"],
        deps = ["@zlib//:zlib"],
    ),
    _module(
        "pyexpat",
        "bundled",
        deps = [":bundled_expat"],
    ),
    _module(
        "_elementtree",
        "bundled",
        deps = ["pyexpat", ":bundled_expat"],
    ),
    _module("_multibytecodec", "bundled"),
    _module(
        "_codecs_cn",
        "bundled",
        deps = ["_multibytecodec"],
    ),
    _module(
        "_codecs_hk",
        "bundled",
        deps = ["_multibytecodec"],
    ),
    _module(
        "_codecs_iso2022",
        "bundled",
        deps = ["_multibytecodec"],
    ),
    _module(
        "_codecs_jp",
        "bundled",
        deps = ["_multibytecodec"],
    ),
    _module(
        "_codecs_kr",
        "bundled",
        deps = ["_multibytecodec"],
    ),
    _module(
        "_codecs_tw",
        "bundled",
        deps = ["_multibytecodec"],
    ),
    _module("unicodedata", "bundled"),
]

_BUNDLED_3_11 = [
    _module("_md5", "bundled"),
    _module("_sha1", "bundled"),
    _module("_sha256", "bundled"),
    _module("_sha512", "bundled"),
    _module("_sha3", "bundled"),
    _module(
        "_blake2",
        "bundled",
        deps = [":bundled_blake2"],
    ),
]

_BUNDLED_3_12_13 = [
    _module(
        "_md5",
        "bundled",
        deps = [":bundled_hacl_md5"],
        excluded_sources = ["Modules/_hacl/Hacl_Hash_MD5.c"],
    ),
    _module(
        "_sha1",
        "bundled",
        deps = [":bundled_hacl_sha1"],
        excluded_sources = ["Modules/_hacl/Hacl_Hash_SHA1.c"],
    ),
    _module("_sha2", "bundled", deps = [":bundled_hacl_sha2"]),
    _module(
        "_sha3",
        "bundled",
        deps = [":bundled_hacl_sha3"],
        excluded_sources = ["Modules/_hacl/Hacl_Hash_SHA3.c"],
    ),
    _module(
        "_blake2",
        "bundled",
        deps = [":bundled_blake2"],
    ),
]

_BUNDLED_3_14 = [
    _module("_md5", "bundled", deps = [":bundled_hacl_md5"]),
    _module("_sha1", "bundled", deps = [":bundled_hacl_sha1"]),
    _module("_sha2", "bundled", deps = [":bundled_hacl_sha2"]),
    _module("_sha3", "bundled", deps = [":bundled_hacl_sha3"]),
    _module("_blake2", "bundled", deps = [":bundled_hacl_blake2"]),
    _module("_hmac", "bundled", deps = [":bundled_hacl_hmac"]),
]

_POSIX_COMMON = [
    _module("fcntl", "posix", platform = "posix"),
    _module("grp", "posix", platform = "posix"),
    _module("mmap", "posix"),
    _module("_posixsubprocess", "posix", platform = "posix"),
    _module("resource", "posix", platform = "posix"),
    _module("select", "posix"),
    _module("_socket", "posix"),
    _module("syslog", "posix", platform = "posix"),
    _module("termios", "posix", platform = "posix"),
    _module("_posixshmem", "posix", platform = "posix"),
    _module("_multiprocessing", "posix"),
    _module(
        "_scproxy",
        "posix",
        linkopts = [
            "-framework",
            "SystemConfiguration",
            "-framework",
            "CoreFoundation",
        ],
        platform = "darwin",
    ),
]

_WINDOWS_COMMON = [
    _module("_overlapped", "posix", platform = "windows"),
    _module("msvcrt", "posix", platform = "windows"),
    _module(
        "winsound",
        "posix",
        platform = "windows",
    ),
]

_POSIX_3_12 = [
    _module("ossaudiodev", "posix", platform = "linux"),
    _module("spwd", "posix", platform = "linux"),
]

_TEST_3_12 = [
    _module("xxsubtype", "test"),
    _module("_xxtestfuzz", "test"),
    _module("_testbuffer", "test"),
    _module("_testinternalcapi", "test"),
    _module("_testcapi", "test"),
    _module("_testclinic", "test"),
]

_TEST_3_11 = [
    _module("xxsubtype", "test"),
    _module("_xxtestfuzz", "test"),
    _module("_testbuffer", "test"),
    _module("_testinternalcapi", "test"),
    _module("_testcapi", "test"),
    _module("_testclinic", "test"),
]

def _test_3_13_14():
    return [
        _module("xxsubtype", "test"),
        _module("_xxtestfuzz", "test"),
        _module("_testbuffer", "test"),
        _module("_testinternalcapi", "test"),
        _module("_testcapi", "test", platform = "windows"),
        _module("_testlimitedcapi", "test"),
        _module("_testclinic", "test"),
        _module(
            "_testclinic_limited",
            "test",
            platform = "posix",
        ),
    ]

def _bootstrap_modules(version):
    modules = _BOOTSTRAP_PREFIX
    if version in ["3.13", "3.14"]:
        modules = modules + [_module("_suggestions", "bootstrap")]
    if version == "3.14":
        modules = modules + [_module("_datetime", "bootstrap")]
    modules = modules + _BOOTSTRAP_IMPORT
    if version in ["3.13", "3.14"]:
        modules = modules + [_module("_sysconfig", "bootstrap")]
    if version == "3.14":
        modules = modules + [
            _module("_types", "bootstrap"),
            _module("_opcode", "bootstrap"),
        ]
    return modules + _BOOTSTRAP_SUFFIX

def _version_modules(version):
    if version == "3.11":
        return (
            _bootstrap_modules(version) +
            _STDLIB_COMMON +
            _STDLIB_3_11 +
            _STDLIB_BEFORE_3_14 +
            _BUNDLED_BASE +
            _BUNDLED_3_11 +
            _POSIX_COMMON +
            _WINDOWS_COMMON +
            _POSIX_3_12 +
            _TEST_3_11
        )
    if version == "3.12":
        return (
            _bootstrap_modules(version) +
            _STDLIB_COMMON +
            _STDLIB_3_12 +
            _STDLIB_BEFORE_3_14 +
            _BUNDLED_BASE +
            _BUNDLED_3_12_13 +
            _POSIX_COMMON +
            _WINDOWS_COMMON +
            _POSIX_3_12 +
            _TEST_3_12
        )
    if version == "3.13":
        return (
            _bootstrap_modules(version) +
            _STDLIB_COMMON +
            _STDLIB_3_13 +
            _STDLIB_BEFORE_3_14 +
            _BUNDLED_BASE +
            _BUNDLED_3_12_13 +
            _POSIX_COMMON +
            _WINDOWS_COMMON +
            _test_3_13_14()
        )
    if version == "3.14":
        return (
            _bootstrap_modules(version) +
            _STDLIB_COMMON +
            _STDLIB_3_14 +
            _BUNDLED_BASE +
            _BUNDLED_3_14 +
            _POSIX_COMMON +
            _WINDOWS_COMMON +
            _test_3_13_14()
        )
    fail("Unsupported CPython version {}; expected one of {}".format(
        repr(version),
        ", ".join(SUPPORTED_PYTHON_VERSIONS),
    ))

def _resolved_module_sources(module, module_sources, version):
    if module.source_name not in module_sources:
        fail("CPython module {} has no generated source membership".format(repr(module.source_name)))
    generated = module_sources[module.source_name]
    expected_source_variables = module.source_variables_by_version.get(version, [])
    if generated.source_variables != expected_source_variables:
        fail("CPython module {} has source variables {}; expected {} for CPython {}".format(
            repr(module.name),
            repr(generated.source_variables),
            repr(expected_source_variables),
            version,
        ))
    for source in module.excluded_sources:
        if source not in generated.sources:
            fail("CPython module {} cannot exclude absent source {}".format(
                repr(module.name),
                repr(source),
            ))
    return struct(
        sources = [
            source
            for source in generated.sources
            if source not in module.excluded_sources
        ],
        windows_sources = generated.windows_sources,
    )

def cpython_static_module_manifest(version, module_sources):
    """Returns the static-module records for one pinned CPython minor version.

    Args:
        version: Supported CPython minor version.
        module_sources: Generated source membership for the pinned release.

    Returns:
        Static-module records for version.
    """
    result = []
    names = {}
    for module in _version_modules(version):
        if module.name in names:
            fail("Duplicate CPython {} module {}".format(version, repr(module.name)))
        names[module.name] = True
        resolved_sources = _resolved_module_sources(module, module_sources, version)
        version_copts = []
        if version == "3.11" and module.name == "_ctypes":
            version_copts = [
                "-DHAVE_FFI_CLOSURE_ALLOC=1",
                "-DHAVE_FFI_PREP_CIF_VAR=1",
                "-DHAVE_FFI_PREP_CLOSURE_LOC=1",
            ]
        result.append(struct(
            category = module.category,
            copts = ["-DPy_BUILD_CORE_BUILTIN=1"] + version_copts + module.copts,
            deps = module.deps,
            includes = module.includes,
            init_symbol = module.init_symbol,
            linkopts = module.linkopts,
            name = module.name,
            platform = module.platform,
            sources = resolved_sources.sources,
            windows_sources = resolved_sources.windows_sources,
        ))
    return result

def _platform_guard(platform):
    if platform == "linux":
        return "defined(__linux__)"
    if platform == "darwin":
        return "defined(__APPLE__)"
    if platform == "posix":
        return "!defined(MS_WINDOWS)"
    if platform == "windows":
        return "defined(MS_WINDOWS)"
    return None

def _inittab_source_impl(ctx):
    modules = []
    for encoded in ctx.attr.modules:
        fields = encoded.split("\t")
        if len(fields) != 3:
            fail("Invalid CPython module entry {}".format(repr(encoded)))
        modules.append(struct(
            init_symbol = fields[1],
            name = fields[0],
            platform = fields[2],
        ))

    lines = [
        "/* Generated from python/private/modules.bzl. */",
        "#include \"Python.h\"",
        "",
        "#ifdef __cplusplus",
        "extern \"C\" {",
        "#endif",
        "",
    ]
    for module in modules:
        guard = _platform_guard(module.platform)
        if guard:
            lines.append("#if {}".format(guard))
        lines.append("extern PyObject *{}(void);".format(module.init_symbol))
        if guard:
            lines.append("#endif")

    lines.extend([
        "extern PyObject *PyMarshal_Init(void);",
        "extern PyObject *PyInit__imp(void);",
        "extern PyObject *PyInit_gc(void);",
        "extern PyObject *PyInit__ast(void);",
        "extern PyObject *PyInit__tokenize(void);",
        "extern PyObject *_PyWarnings_Init(void);",
        "extern PyObject *PyInit__string(void);",
        "",
        "struct _inittab _PyImport_Inittab[] = {",
    ])

    for module in modules:
        guard = _platform_guard(module.platform)
        if guard:
            lines.append("#if {}".format(guard))
        lines.append("    {\"%s\", %s}," % (module.name, module.init_symbol))
        if guard:
            lines.append("#endif")

    for module_name, init_symbol in _CORE_INITTAB:
        lines.append("    {\"%s\", %s}," % (module_name, init_symbol or "NULL"))

    lines.extend([
        "    {0, 0}",
        "};",
        "",
        "#ifdef __cplusplus",
        "}",
        "#endif",
        "",
    ])
    ctx.actions.write(ctx.outputs.out, "\n".join(lines))

_inittab_source = rule(
    implementation = _inittab_source_impl,
    attrs = {
        "modules": attr.string_list(mandatory = True),
        "out": attr.output(mandatory = True),
    },
)

def _target_name(prefix, module_name):
    return "{}_{}".format(prefix, module_name.replace(".", "_"))

def _module_dep_label(dep, module_libraries):
    if dep in module_libraries:
        return module_libraries[dep]
    if dep.startswith(":") or dep.startswith("//") or dep.startswith("@"):
        return dep
    fail("Unknown CPython static-module dependency {}".format(repr(dep)))

def declare_cpython_static_modules(
        name,
        version,
        module_sources,
        deps = [],
        copts = [],
        categories = None,
        exclude_modules = [],
        module_libraries = {},
        visibility = None,
        tags = []):
    """Declares static module libraries and the matching _PyImport_Inittab.

    Args:
        name: Name of the aggregate cc_library.
        version: Supported CPython minor version.
        module_sources: Generated source membership for the pinned release.
        deps: Dependencies required by every module, including the Python headers.
        copts: C options required by every module. Do not define Py_BUILD_CORE.
        categories: Optional subset of bootstrap, bundled, posix, stdlib, and test.
        exclude_modules: Module names intentionally omitted by the caller.
        module_libraries: Existing module-name-to-label mappings to reuse.
        visibility: Visibility for the aggregate and individual module libraries.
        tags: Tags for every generated target.

    Returns:
        A struct containing library, module_libraries, and registry_source labels.
    """
    selected_categories = _SUPPORTED_CATEGORIES if categories == None else categories
    for category in selected_categories:
        if category not in _SUPPORTED_CATEGORIES:
            fail("Unknown CPython static-module category {!r}".format(category))

    excluded = {module_name: True for module_name in exclude_modules}
    modules = [
        module
        for module in cpython_static_module_manifest(version, module_sources)
        if module.category in selected_categories and module.name not in excluded
    ]
    target_names = {
        module.name: _target_name(name, module.name)
        for module in modules
    }
    selected_names = {module.name: True for module in modules}
    for module_name in module_libraries:
        if module_name not in selected_names:
            fail("Cannot override unselected CPython module {!r}".format(module_name))
    selected_libraries = {
        module.name: module_libraries.get(
            module.name,
            ":{}".format(target_names[module.name]),
        )
        for module in modules
    }

    common_labels = []
    posix_labels = []
    linux_labels = []
    darwin_labels = []
    windows_labels = []
    generated_module_libraries = {}
    target_kwargs = {
        "tags": tags,
    }
    if visibility != None:
        target_kwargs["visibility"] = visibility

    linux_setting = "{}_linux".format(name)
    darwin_setting = "{}_darwin".format(name)
    windows_setting = "{}_windows".format(name)
    native.config_setting(
        name = linux_setting,
        constraint_values = ["@platforms//os:linux"],
        visibility = ["//visibility:private"],
    )
    native.config_setting(
        name = darwin_setting,
        constraint_values = ["@platforms//os:macos"],
        visibility = ["//visibility:private"],
    )
    native.config_setting(
        name = windows_setting,
        constraint_values = ["@platforms//os:windows"],
        visibility = ["//visibility:private"],
    )

    for module in modules:
        label = selected_libraries[module.name]
        generated_module_libraries[module.name] = label
        if module.name in module_libraries:
            if module.platform == "linux":
                linux_labels.append(label)
            elif module.platform == "darwin":
                darwin_labels.append(label)
            elif module.platform == "posix":
                posix_labels.append(label)
            elif module.platform == "windows":
                windows_labels.append(label)
            else:
                common_labels.append(label)
            continue

        module_deps = deps + [
            _module_dep_label(dep, selected_libraries)
            for dep in module.deps
        ]
        target_compatible_with = []
        if module.platform == "linux":
            target_compatible_with = ["@platforms//os:linux"]
        elif module.platform == "darwin":
            target_compatible_with = ["@platforms//os:macos"]
        elif module.platform == "posix":
            target_compatible_with = select({
                ":{}".format(linux_setting): [],
                ":{}".format(darwin_setting): [],
                "//conditions:default": ["@platforms//:incompatible"],
            })
        elif module.platform == "windows":
            target_compatible_with = ["@platforms//os:windows"]

        cc_library(
            name = target_names[module.name],
            srcs = module.sources + select({
                ":{}".format(windows_setting): module.windows_sources,
                "//conditions:default": [],
            }),
            alwayslink = True,
            copts = module.copts + copts,
            deps = module_deps,
            includes = module.includes,
            linkopts = module.linkopts,
            target_compatible_with = target_compatible_with,
            **target_kwargs
        )
        if module.platform == "linux":
            linux_labels.append(label)
        elif module.platform == "darwin":
            darwin_labels.append(label)
        elif module.platform == "posix":
            posix_labels.append(label)
        elif module.platform == "windows":
            windows_labels.append(label)
        else:
            common_labels.append(label)

    registry_source_target = "{}_inittab_source".format(name)
    registry_source_file = "{}_inittab.c".format(name)
    _inittab_source(
        name = registry_source_target,
        modules = [
            "{}\t{}\t{}".format(module.name, module.init_symbol, module.platform)
            for module in modules
        ],
        out = registry_source_file,
        tags = tags,
    )

    registry_library = "{}_inittab".format(name)
    cc_library(
        name = registry_library,
        srcs = [":{}".format(registry_source_target)],
        copts = ["-DPy_BUILD_CORE=1"] + copts,
        deps = deps,
        tags = tags,
        visibility = ["//visibility:private"],
    )

    cc_library(
        name = name,
        deps = [":{}".format(registry_library)] + common_labels + select({
            ":{}".format(linux_setting): posix_labels + linux_labels,
            ":{}".format(darwin_setting): posix_labels + darwin_labels,
            ":{}".format(windows_setting): windows_labels,
            "//conditions:default": [],
        }),
        target_compatible_with = select({
            ":{}".format(linux_setting): [],
            ":{}".format(darwin_setting): [],
            ":{}".format(windows_setting): [],
            "//conditions:default": ["@platforms//:incompatible"],
        }),
        **target_kwargs
    )

    return struct(
        library = ":{}".format(name),
        module_libraries = generated_module_libraries,
        registry_source = ":{}".format(registry_source_target),
    )
