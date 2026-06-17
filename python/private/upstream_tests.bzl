"""Bazel targets for CPython's top-level regression tests."""

load("@rules_shell//shell:sh_test.bzl", "sh_test")

_FILE_PREFIX = "Lib/test/"
_FILE_SUFFIX = ".py"
_PACKAGE_SUFFIX = "/__init__.py"
_TEST_RUNNER = "@cpython//python/private:upstream_test.sh"
_TEST_ENV_INHERIT = select({
    "@platforms//os:windows": [
        "PROGRAMFILES",
        "PROGRAMFILES(X86)",
        "PROGRAMW6432",
        "SYSTEMDRIVE",
        "SYSTEMROOT",
        "ProgramFiles",
        "ProgramFiles(x86)",
        "ProgramW6432",
        "SystemDrive",
        "SystemRoot",
    ],
    "//conditions:default": [],
})
_MODULE_DATA_GLOBS = {
    "test_clinic": ["Tools/clinic/**"],
    "test_generated_cases": ["Tools/cases_generator/**"],
}
_RESOURCE_ONLY_MODULES = {
    "3.11": [
        "test_curses",
        "test_ossaudiodev",
        "test_smtpnet",
        "test_socketserver",
        "test_urllib2net",
        "test_urllibnet",
        "test_winsound",
        "test_xmlrpc_net",
        "test_zipfile64",
    ],
    "3.12": [
        "test_curses",
        "test_ossaudiodev",
        "test_smtpnet",
        "test_socketserver",
        "test_urllib2net",
        "test_urllibnet",
        "test_winsound",
        "test_xmlrpc_net",
        "test_zipfile64",
    ],
    "3.13": [
        "test_curses",
        "test_peg_generator",
        "test_pyrepl",
        "test_smtpnet",
        "test_socketserver",
        "test_urllib2net",
        "test_urllibnet",
        "test_winsound",
        "test_xpickle",
        "test_zipfile64",
    ],
    "3.14": [
        "test_curses",
        "test_peg_generator",
        "test_pyrepl",
        "test_smtpnet",
        "test_socketserver",
        "test_urllib2net",
        "test_urllibnet",
        "test_winsound",
        "test_xpickle",
        "test_zipfile64",
    ],
}

def _test_module_for_source(source):
    """Returns the regrtest module name for a top-level Lib/test source."""
    if source.endswith(_PACKAGE_SUFFIX):
        return source[:-len(_PACKAGE_SUFFIX)].split("/")[-1]
    if source.startswith(_FILE_PREFIX) and source.endswith(_FILE_SUFFIX):
        return source[len(_FILE_PREFIX):-len(_FILE_SUFFIX)]
    fail("unsupported CPython regression test source: {}".format(source))

def upstream_regrtests(
        name,
        python,
        version,
        tags = [],
        test_data = [],
        timeout = "long",
        visibility = None):
    """Declares one sh_test per top-level CPython regrtest module.

    The macro must be called in the root package of an unpacked CPython source
    repository. `python` must be an executable target whose runfiles contain
    the CPython standard library, extension modules, and regression-test data.

    Args:
        name: Name of the aggregate test_suite.
        python: Label of the CPython executable/runtime target.
        version: CPython minor version used to select resource-only tests.
        tags: Tags added to every generated sh_test and the test_suite.
        test_data: Additional source-build files required only by regrtests.
        timeout: Bazel timeout added to every generated sh_test.
        visibility: Optional visibility for the generated targets.
    """
    file_tests = native.glob(
        ["Lib/test/test_*.py"],
        allow_empty = True,
    )
    package_tests = native.glob(
        ["Lib/test/test_*/__init__.py"],
        allow_empty = True,
    )
    discovered_sources = sorted(file_tests + package_tests)
    if not discovered_sources:
        fail("{} discovered no top-level CPython regression tests".format(name))

    if version not in _RESOURCE_ONLY_MODULES:
        fail(
            "{} does not have a resource-only test allowlist for CPython {}".format(
                name,
                version,
            ),
        )

    source_by_module = {}
    for source in discovered_sources:
        module = _test_module_for_source(source)
        if module in source_by_module:
            fail(
                (
                    "CPython regression test module {module} is provided by " +
                    "both {first} and {second}"
                ).format(
                    first = source_by_module[module],
                    module = module,
                    second = source,
                ),
            )
        source_by_module[module] = source

    resource_only_modules = sorted(_RESOURCE_ONLY_MODULES[version])
    missing_resource_only_modules = [
        module
        for module in resource_only_modules
        if module not in source_by_module
    ]
    if missing_resource_only_modules:
        fail(
            (
                "{name} resource-only tests are absent from CPython {version}: " +
                "{modules}"
            ).format(
                modules = missing_resource_only_modules,
                name = name,
                version = version,
            ),
        )

    test_labels = []
    generated_modules = []
    generated_resource_only_modules = []
    common_kwargs = {
        "size": "large",
        "tags": list(tags),
        "timeout": timeout,
    }
    if visibility != None:
        common_kwargs["visibility"] = visibility

    for index, module in enumerate(sorted(source_by_module.keys())):
        ordinal = str(index + 1)
        target_name = "{}_regrtest_{}{}".format(
            name,
            "0" * (5 - len(ordinal)),
            ordinal,
        )
        allow_no_tests = module in resource_only_modules
        module_data = (
            native.glob(_MODULE_DATA_GLOBS[module], allow_empty = False) if module in _MODULE_DATA_GLOBS else []
        )
        sh_test(
            name = target_name,
            srcs = [_TEST_RUNNER],
            args = [
                "$(rlocationpath {})".format(python),
                module,
                "allow-no-tests" if allow_no_tests else "require-tests",
            ],
            data = [
                "@bazel_tools//tools/bash/runfiles",
                python,
                source_by_module[module],
            ] + module_data + list(test_data),
            env_inherit = _TEST_ENV_INHERIT,
            **common_kwargs
        )
        generated_modules.append(module)
        if allow_no_tests:
            generated_resource_only_modules.append(module)
        test_labels.append(":" + target_name)

    # Every discovered source reaches exactly one sh_test above. Keep this
    # check separate from target creation so a future filter cannot silently
    # remove a top-level Lib/test test module.
    expected_modules = sorted(source_by_module.keys())
    if generated_modules != expected_modules:
        fail(
            "generated CPython regression tests do not cover discovered " +
            "modules: expected {expected}, generated {generated}".format(
                expected = expected_modules,
                generated = generated_modules,
            ),
        )

    if generated_resource_only_modules != resource_only_modules:
        fail(
            (
                "generated CPython {version} resource-only tests differ from " +
                "the allowlist: expected {expected}, generated {generated}"
            ).format(
                expected = resource_only_modules,
                generated = generated_resource_only_modules,
                version = version,
            ),
        )

    suite_kwargs = {
        "tags": list(tags),
    }
    if visibility != None:
        suite_kwargs["visibility"] = visibility
    native.test_suite(
        name = name,
        tests = test_labels,
        **suite_kwargs
    )
