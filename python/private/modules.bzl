"""Static CPython module manifests for the pinned supported releases."""

load("@rules_cc//cc:cc_library.bzl", "cc_library")

_SUPPORTED_VERSIONS = ["3.11", "3.12", "3.13", "3.14"]
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
        sources,
        category,
        init_symbol = None,
        copts = [],
        includes = [],
        deps = [],
        linkopts = [],
        platform = "all",
        source_root = "Modules"):
    return struct(
        category = category,
        copts = copts,
        deps = deps,
        includes = includes,
        init_symbol = init_symbol or "PyInit_{}".format(name),
        linkopts = linkopts,
        name = name,
        platform = platform,
        sources = ["{}/{}".format(source_root, source) for source in sources],
    )

_BOOTSTRAP_PREFIX = [
    _module("atexit", ["atexitmodule.c"], "bootstrap"),
    _module("faulthandler", ["faulthandler.c"], "bootstrap"),
    _module("posix", ["posixmodule.c"], "bootstrap", platform = "posix"),
    _module("nt", ["posixmodule.c"], "bootstrap", init_symbol = "PyInit_nt", platform = "windows"),
    _module("_signal", ["signalmodule.c"], "bootstrap"),
    _module("_tracemalloc", ["_tracemalloc.c"], "bootstrap"),
]

_BOOTSTRAP_IMPORT = [
    _module("_codecs", ["_codecsmodule.c"], "bootstrap"),
    _module("_collections", ["_collectionsmodule.c"], "bootstrap"),
    _module("errno", ["errnomodule.c"], "bootstrap"),
    _module("_io", [
        "_io/_iomodule.c",
        "_io/iobase.c",
        "_io/fileio.c",
        "_io/bytesio.c",
        "_io/bufferedio.c",
        "_io/textio.c",
        "_io/stringio.c",
    ], "bootstrap"),
    _module("itertools", ["itertoolsmodule.c"], "bootstrap"),
    _module("_sre", ["_sre/sre.c"], "bootstrap"),
]

_BOOTSTRAP_SUFFIX = [
    _module("_thread", ["_threadmodule.c"], "bootstrap"),
    _module("time", ["timemodule.c"], "bootstrap"),
    _module("_typing", ["_typingmodule.c"], "bootstrap"),
    _module("_weakref", ["_weakref.c"], "bootstrap"),
    _module("_abc", ["_abc.c"], "bootstrap"),
    _module("_functools", ["_functoolsmodule.c"], "bootstrap"),
    _module("_locale", ["_localemodule.c"], "bootstrap"),
    _module("_operator", ["_operator.c"], "bootstrap"),
    _module("_stat", ["_stat.c"], "bootstrap"),
    _module("_symtable", ["symtablemodule.c"], "bootstrap"),
    _module("pwd", ["pwdmodule.c"], "bootstrap", platform = "posix"),
]

_STDLIB_COMMON = [
    _module("array", ["arraymodule.c"], "stdlib"),
    _module(
        "_bz2",
        ["_bz2module.c"],
        "stdlib",
        deps = ["@bzip2//:bz2"],
    ),
    _module("_asyncio", ["_asynciomodule.c"], "stdlib"),
    _module("_bisect", ["_bisectmodule.c"], "stdlib"),
    _module("_csv", ["_csv.c"], "stdlib"),
    _module(
        "_ctypes",
        [
            "_ctypes/_ctypes.c",
            "_ctypes/callbacks.c",
            "_ctypes/callproc.c",
            "_ctypes/stgdict.c",
            "_ctypes/cfield.c",
        ],
        "stdlib",
        deps = ["@cpython_libffi//:libffi"],
    ),
    _module("_heapq", ["_heapqmodule.c"], "stdlib"),
    _module("_json", ["_json.c"], "stdlib"),
    _module(
        "_hashlib",
        ["_hashopenssl.c"],
        "stdlib",
        deps = ["@openssl//:crypto"],
    ),
    _module(
        "_lzma",
        ["_lzmamodule.c"],
        "stdlib",
        deps = ["@xz//:lzma"],
    ),
    _module("_lsprof", ["_lsprof.c", "rotatingtree.c"], "stdlib"),
    _module("_pickle", ["_pickle.c"], "stdlib"),
    _module("_queue", ["_queuemodule.c"], "stdlib"),
    _module("_random", ["_randommodule.c"], "stdlib"),
    _module("_struct", ["_struct.c"], "stdlib"),
    _module(
        "_ssl",
        ["_ssl.c"],
        "stdlib",
        deps = ["@openssl//:ssl"],
    ),
    _module(
        "_sqlite3",
        [
            "_sqlite/blob.c",
            "_sqlite/connection.c",
            "_sqlite/cursor.c",
            "_sqlite/microprotocols.c",
            "_sqlite/module.c",
            "_sqlite/prepare_protocol.c",
            "_sqlite/row.c",
            "_sqlite/statement.c",
            "_sqlite/util.c",
        ],
        "stdlib",
        deps = [":hermetic_sqlite3"],
    ),
    _module("_zoneinfo", ["_zoneinfo.c"], "stdlib"),
    _module("math", ["mathmodule.c"], "stdlib"),
    _module("cmath", ["cmathmodule.c"], "stdlib"),
    _module("_statistics", ["_statisticsmodule.c"], "stdlib"),
    _module(
        "zlib",
        ["zlibmodule.c"],
        "stdlib",
        deps = ["@zlib//:zlib"],
    ),
]

_STDLIB_BEFORE_3_14 = [
    _module("_contextvars", ["_contextvarsmodule.c"], "stdlib"),
    _module("_opcode", ["_opcode.c"], "stdlib"),
    _module("_datetime", ["_datetimemodule.c"], "stdlib"),
]

_STDLIB_3_12 = [
    _module("_xxsubinterpreters", ["_xxsubinterpretersmodule.c"], "stdlib"),
    _module("_xxinterpchannels", ["_xxinterpchannelsmodule.c"], "stdlib"),
    _module("audioop", ["audioop.c"], "stdlib"),
]

_STDLIB_3_11 = [
    _module("_xxsubinterpreters", ["_xxsubinterpretersmodule.c"], "stdlib"),
    _module("audioop", ["audioop.c"], "stdlib"),
]

_STDLIB_3_13 = [
    _module("_interpreters", ["_interpretersmodule.c"], "stdlib"),
    _module("_interpchannels", ["_interpchannelsmodule.c"], "stdlib"),
    _module("_interpqueues", ["_interpqueuesmodule.c"], "stdlib"),
]

_STDLIB_3_14 = [
    _module("_contextvars", ["_contextvars.c"], "stdlib", source_root = "Python"),
    _module("_interpreters", ["_interpretersmodule.c"], "stdlib"),
    _module("_interpchannels", ["_interpchannelsmodule.c"], "stdlib"),
    _module("_interpqueues", ["_interpqueuesmodule.c"], "stdlib"),
]

_BUNDLED_BASE = [
    _module(
        "_decimal",
        ["_decimal/_decimal.c"],
        "bundled",
        deps = [":bundled_libmpdec"],
    ),
    _module(
        "binascii",
        ["binascii.c"],
        "bundled",
        copts = ["-DUSE_ZLIB_CRC32=1"],
        deps = ["@zlib//:zlib"],
    ),
    _module(
        "pyexpat",
        ["pyexpat.c"],
        "bundled",
        deps = [":bundled_expat"],
    ),
    _module(
        "_elementtree",
        ["_elementtree.c"],
        "bundled",
        deps = ["pyexpat", ":bundled_expat"],
    ),
    _module("_multibytecodec", ["cjkcodecs/multibytecodec.c"], "bundled"),
    _module(
        "_codecs_cn",
        ["cjkcodecs/_codecs_cn.c"],
        "bundled",
        deps = ["_multibytecodec"],
    ),
    _module(
        "_codecs_hk",
        ["cjkcodecs/_codecs_hk.c"],
        "bundled",
        deps = ["_multibytecodec"],
    ),
    _module(
        "_codecs_iso2022",
        ["cjkcodecs/_codecs_iso2022.c"],
        "bundled",
        deps = ["_multibytecodec"],
    ),
    _module(
        "_codecs_jp",
        ["cjkcodecs/_codecs_jp.c"],
        "bundled",
        deps = ["_multibytecodec"],
    ),
    _module(
        "_codecs_kr",
        ["cjkcodecs/_codecs_kr.c"],
        "bundled",
        deps = ["_multibytecodec"],
    ),
    _module(
        "_codecs_tw",
        ["cjkcodecs/_codecs_tw.c"],
        "bundled",
        deps = ["_multibytecodec"],
    ),
    _module("unicodedata", ["unicodedata.c"], "bundled"),
]

_BUNDLED_3_11 = [
    _module("_md5", ["md5module.c"], "bundled"),
    _module("_sha1", ["sha1module.c"], "bundled"),
    _module("_sha256", ["sha256module.c"], "bundled"),
    _module("_sha512", ["sha512module.c"], "bundled"),
    _module("_sha3", ["_sha3/sha3module.c"], "bundled"),
    _module(
        "_blake2",
        [
            "_blake2/blake2module.c",
            "_blake2/blake2b_impl.c",
            "_blake2/blake2s_impl.c",
        ],
        "bundled",
        deps = [":bundled_blake2"],
    ),
]

_BUNDLED_3_12_13 = [
    _module("_md5", ["md5module.c"], "bundled", deps = [":bundled_hacl_md5"]),
    _module("_sha1", ["sha1module.c"], "bundled", deps = [":bundled_hacl_sha1"]),
    _module("_sha2", ["sha2module.c"], "bundled", deps = [":bundled_hacl_sha2"]),
    _module("_sha3", ["sha3module.c"], "bundled", deps = [":bundled_hacl_sha3"]),
    _module(
        "_blake2",
        [
            "_blake2/blake2module.c",
            "_blake2/blake2b_impl.c",
            "_blake2/blake2s_impl.c",
        ],
        "bundled",
        deps = [":bundled_blake2"],
    ),
]

_BUNDLED_3_14 = [
    _module("_md5", ["md5module.c"], "bundled", deps = [":bundled_hacl_md5"]),
    _module("_sha1", ["sha1module.c"], "bundled", deps = [":bundled_hacl_sha1"]),
    _module("_sha2", ["sha2module.c"], "bundled", deps = [":bundled_hacl_sha2"]),
    _module("_sha3", ["sha3module.c"], "bundled", deps = [":bundled_hacl_sha3"]),
    _module("_blake2", ["blake2module.c"], "bundled", deps = [":bundled_hacl_blake2"]),
    _module("_hmac", ["hmacmodule.c"], "bundled", deps = [":bundled_hacl_hmac"]),
]

_POSIX_COMMON = [
    _module("fcntl", ["fcntlmodule.c"], "posix", platform = "posix"),
    _module("grp", ["grpmodule.c"], "posix", platform = "posix"),
    _module("mmap", ["mmapmodule.c"], "posix"),
    _module("_posixsubprocess", ["_posixsubprocess.c"], "posix", platform = "posix"),
    _module("resource", ["resource.c"], "posix", platform = "posix"),
    _module("select", ["selectmodule.c"], "posix"),
    _module("_socket", ["socketmodule.c"], "posix"),
    _module("syslog", ["syslogmodule.c"], "posix", platform = "posix"),
    _module("termios", ["termios.c"], "posix", platform = "posix"),
    _module("_posixshmem", ["_multiprocessing/posixshmem.c"], "posix", platform = "posix"),
    _module("_multiprocessing", [
        "_multiprocessing/multiprocessing.c",
        "_multiprocessing/semaphore.c",
    ], "posix"),
    _module(
        "_scproxy",
        ["_scproxy.c"],
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
    _module("_winapi", ["_winapi.c"], "posix", platform = "windows"),
    _module("_overlapped", ["overlapped.c"], "posix", platform = "windows"),
    _module("msvcrt", ["msvcrtmodule.c"], "posix", platform = "windows", source_root = "PC"),
    _module("winreg", ["winreg.c"], "posix", platform = "windows", source_root = "PC"),
    _module(
        "winsound",
        ["winsound.c"],
        "posix",
        linkopts = ["winmm.lib"],
        platform = "windows",
        source_root = "PC",
    ),
]

_POSIX_3_12 = [
    _module("ossaudiodev", ["ossaudiodev.c"], "posix", platform = "linux"),
    _module("spwd", ["spwdmodule.c"], "posix", platform = "linux"),
]

_TEST_3_12 = [
    _module("xxsubtype", ["xxsubtype.c"], "test"),
    _module("_xxtestfuzz", [
        "_xxtestfuzz/_xxtestfuzz.c",
        "_xxtestfuzz/fuzzer.c",
    ], "test"),
    _module("_testbuffer", ["_testbuffer.c"], "test"),
    _module("_testinternalcapi", ["_testinternalcapi.c"], "test"),
    _module("_testcapi", [
        "_testcapimodule.c",
        "_testcapi/vectorcall.c",
        "_testcapi/vectorcall_limited.c",
        "_testcapi/heaptype.c",
        "_testcapi/abstract.c",
        "_testcapi/bytearray.c",
        "_testcapi/bytes.c",
        "_testcapi/unicode.c",
        "_testcapi/dict.c",
        "_testcapi/set.c",
        "_testcapi/list.c",
        "_testcapi/tuple.c",
        "_testcapi/getargs.c",
        "_testcapi/pytime.c",
        "_testcapi/datetime.c",
        "_testcapi/docstring.c",
        "_testcapi/mem.c",
        "_testcapi/watchers.c",
        "_testcapi/long.c",
        "_testcapi/float.c",
        "_testcapi/complex.c",
        "_testcapi/numbers.c",
        "_testcapi/structmember.c",
        "_testcapi/exceptions.c",
        "_testcapi/code.c",
        "_testcapi/buffer.c",
        "_testcapi/pyos.c",
        "_testcapi/run.c",
        "_testcapi/file.c",
        "_testcapi/codec.c",
        "_testcapi/immortal.c",
        "_testcapi/heaptype_relative.c",
        "_testcapi/gc.c",
        "_testcapi/sys.c",
        "_testcapi/import.c",
        "_testcapi/eval.c",
    ], "test"),
    _module("_testclinic", ["_testclinic.c"], "test"),
]

_TEST_3_11 = [
    _module("_xxtestfuzz", [
        "_xxtestfuzz/_xxtestfuzz.c",
        "_xxtestfuzz/fuzzer.c",
    ], "test"),
    _module("_testbuffer", ["_testbuffer.c"], "test"),
    _module("_testinternalcapi", ["_testinternalcapi.c"], "test"),
    _module("_testcapi", ["_testcapimodule.c"], "test"),
    _module("_testclinic", ["_testclinic.c"], "test"),
]

def _test_3_13_14(version):
    return [
        _module("xxsubtype", ["xxsubtype.c"], "test"),
        _module("_xxtestfuzz", [
            "_xxtestfuzz/_xxtestfuzz.c",
            "_xxtestfuzz/fuzzer.c",
        ], "test"),
        _module("_testbuffer", ["_testbuffer.c"], "test"),
        _module("_testinternalcapi", [
            "_testinternalcapi.c",
            "_testinternalcapi/test_lock.c",
            "_testinternalcapi/pytime.c",
            "_testinternalcapi/set.c",
            "_testinternalcapi/test_critical_sections.c",
        ] + (["_testinternalcapi/complex.c"] if version == "3.14" else []), "test"),
        _module("_testlimitedcapi", [
            "_testlimitedcapi.c",
            "_testlimitedcapi/abstract.c",
            "_testlimitedcapi/bytearray.c",
            "_testlimitedcapi/bytes.c",
            "_testlimitedcapi/complex.c",
            "_testlimitedcapi/dict.c",
            "_testlimitedcapi/eval.c",
            "_testlimitedcapi/float.c",
            "_testlimitedcapi/heaptype_relative.c",
            "_testlimitedcapi/import.c",
            "_testlimitedcapi/list.c",
            "_testlimitedcapi/long.c",
            "_testlimitedcapi/object.c",
            "_testlimitedcapi/pyos.c",
            "_testlimitedcapi/set.c",
            "_testlimitedcapi/sys.c",
            "_testlimitedcapi/tuple.c",
            "_testlimitedcapi/unicode.c",
            "_testlimitedcapi/vectorcall_limited.c",
            "_testlimitedcapi/file.c",
        ] + ([
            "_testlimitedcapi/codec.c",
            "_testlimitedcapi/version.c",
        ] if version == "3.14" else []), "test"),
        _module("_testclinic", ["_testclinic.c"], "test"),
        _module("_testclinic_limited", ["_testclinic_limited.c"], "test"),
    ]

def _bootstrap_modules(version):
    modules = _BOOTSTRAP_PREFIX
    if version in ["3.13", "3.14"]:
        modules = modules + [_module("_suggestions", ["_suggestions.c"], "bootstrap")]
    if version == "3.14":
        modules = modules + [_module("_datetime", ["_datetimemodule.c"], "bootstrap")]
    modules = modules + _BOOTSTRAP_IMPORT
    if version in ["3.13", "3.14"]:
        modules = modules + [_module("_sysconfig", ["_sysconfig.c"], "bootstrap")]
    if version == "3.14":
        modules = modules + [
            _module("_types", ["_typesmodule.c"], "bootstrap"),
            _module("_opcode", ["_opcode.c"], "bootstrap"),
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
            _test_3_13_14(version)
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
            _test_3_13_14(version)
        )
    fail("Unsupported CPython version {}; expected one of {}".format(
        repr(version),
        ", ".join(_SUPPORTED_VERSIONS),
    ))

def cpython_static_module_manifest(version):
    """Returns the static-module records for one pinned CPython minor version.

    Args:
        version: Supported CPython minor version.

    Returns:
        Static-module records for version.
    """
    result = []
    names = {}
    for module in _version_modules(version):
        if module.name in names:
            fail("Duplicate CPython {} module {}".format(version, repr(module.name)))
        names[module.name] = True
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
            sources = module.sources,
            version = version,
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
        for module in cpython_static_module_manifest(version)
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
            srcs = module.sources,
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
