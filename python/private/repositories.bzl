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

_SETUP_SOURCE_SUFFIXES = [
    ".c",
    ".C",
    ".c++",
    ".cc",
    ".cpp",
    ".cxx",
    ".m",
]

_PCBUILD_SOURCE_SUFFIXES = [
    ".c",
    ".C",
    ".cc",
    ".cpp",
    ".cxx",
]

_PCBUILD_MODULE_PROJECTS = {
    "_overlapped": "PCbuild/_overlapped.vcxproj",
    "_testconsole": "PCbuild/_testconsole.vcxproj",
    "_wmi": "PCbuild/_wmi.vcxproj",
    "winsound": "PCbuild/winsound.vcxproj",
}

_PYTHONCORE_MODULE_SOURCES = {
    "_contextvars": "Python/_contextvars.c",
    "_winapi": "Modules/_winapi.c",
    "msvcrt": "PC/msvcrtmodule.c",
    "winreg": "PC/winreg.c",
    "xxsubtype": "Modules/xxsubtype.c",
}

_PYTHONCORE_WINDOWS_SOURCES = {
    "_io": ["Modules/_io/winconsoleio.c"],
}

_SETUP_SOURCE_VARIABLES = ["MODULE__CTYPES_MALLOC_CLOSURE"]

_SETUP_HACL_DEPENDENCY_TOKENS = [
    "-D_BSD_SOURCE",
    "-D_DEFAULT_SOURCE",
    "-I$(srcdir)/Modules/_hacl/include",
    "Modules/_hacl/libHacl_Hash_SHA2.a",
]

def _patchlevel_define(patchlevel_h, name):
    prefix = "#define {} ".format(name)
    for line in patchlevel_h.splitlines():
        if line.startswith(prefix):
            return line[len(prefix):].strip()
    fail("Include/patchlevel.h does not define {}".format(name))

def _has_source_suffix(value, suffixes):
    for suffix in suffixes:
        if value.endswith(suffix):
            return True
    return False

def _validate_source(repository_ctx, source, owner):
    if source.startswith("/") or ".." in source.split("/"):
        fail("{} names non-hermetic source {}".format(owner, repr(source)))
    if not repository_ctx.path(source).exists:
        fail("{} names missing source {}".format(owner, repr(source)))

def _template_module_name(token, owner):
    if not token.startswith("@"):
        return token
    fields = token.split("@")
    if len(fields) != 3 or fields[0] or not fields[1] or not fields[2]:
        fail("{} has malformed module condition {}".format(owner, repr(token)))
    if not fields[1].startswith("MODULE_") or not fields[1].endswith("_TRUE"):
        fail("{} has unsupported module condition {}".format(owner, repr(fields[1])))
    return fields[2]

def _setup_source_path(token):
    token = token.replace("\\", "/")
    if token.startswith("$(srcdir)/"):
        token = token[len("$(srcdir)/"):]
    if token.endswith(".o"):
        token = token[:-2] + ".c"
    elif not _has_source_suffix(token, _SETUP_SOURCE_SUFFIXES):
        return None
    if token.startswith("Modules/"):
        return token
    return "Modules/" + token

def _setup_modules(repository_ctx):
    modules = {}
    for setup_path in [
        "Modules/Setup.bootstrap.in",
        "Modules/Setup.stdlib.in",
    ]:
        for line_number, raw_line in enumerate(repository_ctx.read(setup_path).splitlines(), 1):
            if raw_line.rstrip().endswith("\\"):
                fail("{}:{} uses an unsupported line continuation".format(setup_path, line_number))
            stripped = raw_line.strip()
            if stripped.startswith("#@MODULE_"):
                stripped = stripped[1:]
            elif "#" in stripped:
                stripped = stripped.split("#", 1)[0].strip()
            if not stripped:
                continue
            owner = "{}:{}".format(setup_path, line_number)
            if stripped.startswith("*"):
                if stripped not in ["*static*", "*shared*", "*@MODULE_BUILDTYPE@*"]:
                    fail("{} has unsupported build marker {}".format(owner, repr(stripped)))
                continue

            tokens = [
                token
                for token in stripped.replace("\t", " ").split(" ")
                if token
            ]
            module_name = _template_module_name(tokens[0], owner)
            sources = []
            source_variables = []
            for token in tokens[1:]:
                if token in _SETUP_HACL_DEPENDENCY_TOKENS:
                    continue
                if token.startswith("@") and token.endswith("@"):
                    source_variable = token[1:-1]
                    if source_variable not in _SETUP_SOURCE_VARIABLES:
                        fail("{} has unsupported source variable {}".format(owner, repr(source_variable)))
                    if source_variable in source_variables:
                        fail("{} duplicates source variable {}".format(owner, repr(source_variable)))
                    source_variables.append(source_variable)
                    continue
                source = _setup_source_path(token)
                if source != None:
                    _validate_source(repository_ctx, source, owner)
                    if source in sources:
                        fail("{} duplicates source {}".format(owner, repr(source)))
                    sources.append(source)
                    continue
                fail("{} has unsupported module token {}".format(owner, repr(token)))
            if not sources:
                fail("{} module {} has no source".format(owner, repr(module_name)))
            if module_name in modules:
                fail("{} duplicates module {}".format(owner, repr(module_name)))
            modules[module_name] = struct(
                sources = sources,
                source_variables = source_variables,
                windows_sources = [],
            )
    return modules

def _pcbuild_source_path(value, owner):
    value = value.replace("\\", "/")
    if "$(" in value or value.startswith("/"):
        fail("{} has unsupported ClCompile path {}".format(owner, repr(value)))
    if not value.startswith("../"):
        fail("{} has non-rooted ClCompile path {}".format(owner, repr(value)))
    value = value[3:]
    if value.startswith("../") or not (
        value.startswith("Modules/") or
        value.startswith("PC/") or
        value.startswith("Python/")
    ):
        fail("{} has unsupported ClCompile source {}".format(owner, repr(value)))
    if not _has_source_suffix(value, _PCBUILD_SOURCE_SUFFIXES):
        fail("{} has unsupported ClCompile extension {}".format(owner, repr(value)))
    return value

def _xml_attribute(tag, name, owner):
    marker = ' {}="'.format(name)
    start = tag.find(marker)
    if start < 0:
        fail("{} ClCompile has no {} attribute".format(owner, name))
    start += len(marker)
    end = tag.find('"', start)
    if end < 0:
        fail("{} has unterminated {} attribute".format(owner, name))
    return tag[start:end]

def _pcbuild_project_sources(repository_ctx, project_path):
    sources = []
    for line_number, line in enumerate(repository_ctx.read(project_path).splitlines(), 1):
        stripped = line.strip()
        if "<ClCompile" not in stripped:
            continue
        owner = "{}:{}".format(project_path, line_number)
        if stripped == "<ClCompile>":
            continue
        if not stripped.startswith("<ClCompile") or "Condition=" in stripped or not stripped.endswith("/>"):
            fail("{} has unsupported ClCompile declaration".format(owner))
        value = _xml_attribute(stripped, "Include", owner)
        source = _pcbuild_source_path(value, owner)
        _validate_source(repository_ctx, source, owner)
        if source in sources:
            fail("{} duplicates ClCompile source {}".format(owner, repr(source)))
        sources.append(source)
    if not sources:
        fail("{} contains no ClCompile sources".format(project_path))
    return sources

def _pcbuild_modules(repository_ctx):
    modules = {}
    for module_name, project_path in _PCBUILD_MODULE_PROJECTS.items():
        if repository_ctx.path(project_path).exists:
            modules[module_name] = _pcbuild_project_sources(repository_ctx, project_path)
    for required in ["_overlapped", "_testconsole", "winsound"]:
        if required not in modules:
            fail("CPython PCbuild does not define required module {}".format(repr(required)))
    return modules

def _validate_pythoncore_sources(repository_ctx, expected_sources):
    found = {}
    in_comment = False
    project_path = "PCbuild/pythoncore.vcxproj"
    for line_number, line in enumerate(repository_ctx.read(project_path).splitlines(), 1):
        stripped = line.strip()
        if "<!--" in stripped:
            in_comment = True
        if not in_comment and "<ClCompile" in stripped:
            owner = "{}:{}".format(project_path, line_number)
            if ' Include="' not in stripped:
                if ' Remove="' in stripped or ' Update="' in stripped:
                    fail("{} modifies the ClCompile source set".format(owner))
                continue
            if not stripped.startswith("<ClCompile") or ">" not in stripped:
                fail("{} has unsupported ClCompile declaration".format(owner))
            value = _xml_attribute(stripped, "Include", owner).replace("\\", "/")
            if value.startswith("../"):
                source = value[3:]
                if source in expected_sources:
                    if "Condition=" in stripped or not stripped.endswith("/>"):
                        fail("{} conditionally compiles owned source {}".format(owner, repr(source)))
                    found[source] = found.get(source, 0) + 1
        if "-->" in stripped:
            in_comment = False
    for source in expected_sources:
        count = found.get(source, 0)
        if count != 1:
            fail("{} must compile owned source {} exactly once; found {}".format(
                project_path,
                repr(source),
                count,
            ))

def _module_sources(repository_ctx):
    modules = _setup_modules(repository_ctx)
    for module_name, sources in _pcbuild_modules(repository_ctx).items():
        if module_name in modules:
            fail("PCbuild project duplicates Setup module {}".format(repr(module_name)))
        modules[module_name] = struct(
            sources = sources,
            source_variables = [],
            windows_sources = [],
        )

    pythoncore_sources = []
    for module_name, source in _PYTHONCORE_MODULE_SOURCES.items():
        if module_name in modules:
            continue
        _validate_source(repository_ctx, source, "PCbuild/pythoncore.vcxproj")
        pythoncore_sources.append(source)
        modules[module_name] = struct(
            sources = [source],
            source_variables = [],
            windows_sources = [],
        )

    for module_name, windows_sources in _PYTHONCORE_WINDOWS_SOURCES.items():
        if module_name not in modules:
            fail("Windows sources name unknown Setup module {}".format(repr(module_name)))
        module = modules[module_name]
        for source in windows_sources:
            _validate_source(repository_ctx, source, "PCbuild/pythoncore.vcxproj")
            pythoncore_sources.append(source)
        modules[module_name] = struct(
            sources = module.sources,
            source_variables = module.source_variables,
            windows_sources = windows_sources,
        )
    _validate_pythoncore_sources(repository_ctx, pythoncore_sources)
    return modules

def _format_string_list(values, indent):
    if not values:
        return "[]"
    lines = ["["]
    for value in values:
        lines.append("{}{},".format(indent, repr(value)))
    lines.append(indent[:-4] + "]")
    return "\n".join(lines)

def _write_module_sources(repository_ctx):
    modules = _module_sources(repository_ctx)
    lines = [
        '"""Generated CPython module source membership."""',
        "",
        "CPYTHON_MODULE_SOURCES = {",
    ]
    for module_name in sorted(modules):
        module = modules[module_name]
        lines.extend([
            "    {}: struct(".format(repr(module_name)),
            "        sources = {},".format(_format_string_list(module.sources, "            ")),
            "        source_variables = {},".format(_format_string_list(module.source_variables, "            ")),
            "        windows_sources = {},".format(_format_string_list(module.windows_sources, "            ")),
            "    ),",
        ])
    lines.extend(["}", ""])
    repository_ctx.file("bazel/module_sources.bzl", "\n".join(lines))

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
    _write_module_sources(repository_ctx)
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
            "    supports_isolated_interpreters = {supports_isolated_interpreters},\n" +
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
            supports_isolated_interpreters = repr(repository_ctx.attr.supports_isolated_interpreters),
            venv_launcher_kind = repr(repository_ctx.attr.venv_launcher_kind),
            venv_launcher_runtime_name = repr(repository_ctx.attr.venv_launcher_runtime_name),
            venv_launcher_source = repr(repository_ctx.attr.venv_launcher_source),
            venvw_launcher_runtime_name = repr(repository_ctx.attr.venvw_launcher_runtime_name),
            windows_pyconfig_template = repr(repository_ctx.attr.windows_pyconfig_template),
        ),
    )
    repository_ctx.file(
        "bazel/BUILD.bazel",
        "exports_files([\"module_sources.bzl\", \"release.bzl\"])\n",
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
        "supports_isolated_interpreters": attr.bool(),
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
