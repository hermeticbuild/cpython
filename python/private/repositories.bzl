"""Repository rule for an official CPython source release."""

_RUNTIME_TZDATA_SHA256 = "9173fde7d80d9018e02a662e168e5a2d04f87c41ea174b139fbef642eda62d10"
_RUNTIME_TZDATA_STRIP_PREFIX = "tzdata-2026.2/src"
_RUNTIME_TZDATA_URL = "https://files.pythonhosted.org/packages/source/t/tzdata/tzdata-2026.2.tar.gz"

_RELEASE_LEVEL_DEFINES = {
    "alpha": "PY_RELEASE_LEVEL_ALPHA",
    "beta": "PY_RELEASE_LEVEL_BETA",
    "candidate": "PY_RELEASE_LEVEL_GAMMA",
    "final": "PY_RELEASE_LEVEL_FINAL",
}

def _patchlevel_define(patchlevel_h, name):
    prefix = "#define {} ".format(name)
    for line in patchlevel_h.splitlines():
        if line.startswith(prefix):
            return line[len(prefix):].strip()
    fail("Include/patchlevel.h does not define {}".format(name))

def _validate_release(repository_ctx):
    patchlevel_h = repository_ctx.read("Include/patchlevel.h")
    expected_defines = {
        "PY_MAJOR_VERSION": str(repository_ctx.attr.major),
        "PY_MICRO_VERSION": str(repository_ctx.attr.micro),
        "PY_MINOR_VERSION": str(repository_ctx.attr.minor),
        "PY_RELEASE_LEVEL": _RELEASE_LEVEL_DEFINES[repository_ctx.attr.release_level],
        "PY_RELEASE_SERIAL": str(repository_ctx.attr.serial),
        "PY_VERSION": repr(repository_ctx.attr.release),
    }
    for name, expected in expected_defines.items():
        actual = _patchlevel_define(patchlevel_h, name)
        if actual != expected:
            fail(
                "Include/patchlevel.h defines {} as {}, expected {}".format(
                    name,
                    actual,
                    expected,
                ),
            )

    frozen_c = repository_ctx.read("Python/frozen.c")
    actual_needs_deepfreeze = "#define GET_CODE(name)" in frozen_c
    if actual_needs_deepfreeze != repository_ctx.attr.needs_deepfreeze:
        fail(
            "Python/frozen.c deepfreeze requirement is {}, expected {}".format(
                actual_needs_deepfreeze,
                repository_ctx.attr.needs_deepfreeze,
            ),
        )

    has_build_details_script = repository_ctx.path("Tools/build/generate-build-details.py").exists
    if has_build_details_script != bool(repository_ctx.attr.build_details_schema):
        fail(
            "Tools/build/generate-build-details.py presence is {}, build_details_schema is {}".format(
                has_build_details_script,
                repr(repository_ctx.attr.build_details_schema),
            ),
        )

    has_windows_pyconfig = repository_ctx.path("PC/pyconfig.h").exists
    has_windows_pyconfig_template = repository_ctx.path("PC/pyconfig.h.in").exists
    if has_windows_pyconfig == has_windows_pyconfig_template:
        fail("CPython release must provide exactly one of PC/pyconfig.h and PC/pyconfig.h.in")
    if has_windows_pyconfig_template != repository_ctx.attr.windows_pyconfig_template:
        fail(
            "PC/pyconfig.h.in presence is {}, expected {}".format(
                has_windows_pyconfig_template,
                repository_ctx.attr.windows_pyconfig_template,
            ),
        )

    venv_launcher = repository_ctx.read(repository_ctx.attr.venv_launcher_source)
    if repository_ctx.attr.venv_launcher_kind == "redirect":
        if "VENV_REDIRECT" not in venv_launcher:
            fail("redirect venv launcher source does not contain VENV_REDIRECT")
    elif "#ifndef EXENAME" not in venv_launcher or "<pathcch.h>" not in venv_launcher:
        fail("dedicated venv launcher source does not define EXENAME and use pathcch.h")

def _cpython_source_repository_impl(repository_ctx):
    repository_ctx.download_and_extract(
        url = repository_ctx.attr.urls,
        sha256 = repository_ctx.attr.sha256,
        stripPrefix = repository_ctx.attr.strip_prefix,
    )
    repository_ctx.download_and_extract(
        url = _RUNTIME_TZDATA_URL,
        output = "Lib",
        sha256 = _RUNTIME_TZDATA_SHA256,
        stripPrefix = _RUNTIME_TZDATA_STRIP_PREFIX,
    )

    # The bundled tzdata package is runtime data, not an installed distribution.
    repository_ctx.delete("Lib/tzdata.egg-info")
    for patch in repository_ctx.attr.patches:
        repository_ctx.patch(patch, strip = 1)
    _validate_release(repository_ctx)
    repository_ctx.symlink(repository_ctx.attr.build_file, "BUILD.bazel")
    repository_ctx.file("Modules/Setup.local", "")
    repository_ctx.file("pybuilddir.txt", ".")
    repository_ctx.file(
        "bazel/release.bzl",
        (
            "CPYTHON_RELEASE = struct(\n" +
            "    build_details_schema = {build_details_schema},\n" +
            "    cache_tag = {cache_tag},\n" +
            "    hexversion = {hexversion},\n" +
            "    major = {major},\n" +
            "    micro = {micro},\n" +
            "    minor = {minor},\n" +
            "    minor_version = {minor_version},\n" +
            "    needs_deepfreeze = {needs_deepfreeze},\n" +
            "    release = {release},\n" +
            "    release_level = {release_level},\n" +
            "    resource_field3 = {resource_field3},\n" +
            "    serial = {serial},\n" +
            "    soabi = {soabi},\n" +
            "    venv_launcher_kind = {venv_launcher_kind},\n" +
            "    venv_launcher_runtime_name = {venv_launcher_runtime_name},\n" +
            "    venv_launcher_source = {venv_launcher_source},\n" +
            "    venvw_launcher_runtime_name = {venvw_launcher_runtime_name},\n" +
            "    windows_pyconfig_template = {windows_pyconfig_template},\n" +
            ")\n" +
            "PYTHON_NEEDS_DEEPFREEZE = {needs_deepfreeze}\n" +
            "PYTHON_RESOURCE_FIELD3 = {resource_field3}\n" +
            "PYTHON_VERSION = {minor_version}\n" +
            "PYTHON_SOABI = {soabi}\n"
        ).format(
            build_details_schema = repr(repository_ctx.attr.build_details_schema or None),
            cache_tag = repr(repository_ctx.attr.cache_tag),
            hexversion = repository_ctx.attr.hexversion,
            major = repository_ctx.attr.major,
            micro = repository_ctx.attr.micro,
            minor = repository_ctx.attr.minor,
            minor_version = repr(repository_ctx.attr.minor_version),
            needs_deepfreeze = repr(repository_ctx.attr.needs_deepfreeze),
            release = repr(repository_ctx.attr.release),
            release_level = repr(repository_ctx.attr.release_level),
            resource_field3 = repository_ctx.attr.resource_field3,
            serial = repository_ctx.attr.serial,
            soabi = repr(repository_ctx.attr.soabi),
            venv_launcher_kind = repr(repository_ctx.attr.venv_launcher_kind),
            venv_launcher_runtime_name = repr(repository_ctx.attr.venv_launcher_runtime_name),
            venv_launcher_source = repr(repository_ctx.attr.venv_launcher_source),
            venvw_launcher_runtime_name = repr(repository_ctx.attr.venvw_launcher_runtime_name),
            windows_pyconfig_template = repr(repository_ctx.attr.windows_pyconfig_template),
        ),
    )
    repository_ctx.file(
        "bazel/BUILD.bazel",
        "exports_files([\"release.bzl\"])\n",
    )

cpython_source_repository = repository_rule(
    implementation = _cpython_source_repository_impl,
    attrs = {
        "build_details_schema": attr.string(),
        "build_file": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "cache_tag": attr.string(mandatory = True),
        "hexversion": attr.int(mandatory = True),
        "major": attr.int(mandatory = True),
        "micro": attr.int(mandatory = True),
        "minor": attr.int(mandatory = True),
        "minor_version": attr.string(mandatory = True),
        "needs_deepfreeze": attr.bool(mandatory = True),
        "patches": attr.label_list(
            allow_files = True,
        ),
        "release": attr.string(mandatory = True),
        "release_level": attr.string(mandatory = True),
        "resource_field3": attr.int(mandatory = True),
        "serial": attr.int(mandatory = True),
        "sha256": attr.string(mandatory = True),
        "soabi": attr.string(mandatory = True),
        "strip_prefix": attr.string(mandatory = True),
        "urls": attr.string_list(mandatory = True),
        "venv_launcher_kind": attr.string(
            mandatory = True,
            values = ["dedicated", "redirect"],
        ),
        "venv_launcher_runtime_name": attr.string(mandatory = True),
        "venv_launcher_source": attr.string(mandatory = True),
        "venvw_launcher_runtime_name": attr.string(mandatory = True),
        "windows_pyconfig_template": attr.bool(mandatory = True),
    },
)
