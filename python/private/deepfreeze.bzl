"""CPython deep-freeze generation for releases that require it."""

load("@bazel_lib//lib:run_binary.bzl", "run_binary")
load("@rules_cc//cc:cc_binary.bzl", "cc_binary")

def _exec_files_impl(ctx):
    return DefaultInfo(files = ctx.attr.src[DefaultInfo].files)

_exec_files = rule(
    implementation = _exec_files_impl,
    attrs = {
        "src": attr.label(
            cfg = "exec",
            executable = True,
            mandatory = True,
        ),
    },
)

def deepfreeze_sources(
        needs_deepfreeze,
        core_copts,
        frozen_modules,
        getpath_copts,
        linkopts,
        bootstrap_modules,
        version):
    """Defines the bootstrap interpreter and deepfreeze action."""
    if not needs_deepfreeze:
        return []

    cc_binary(
        name = "_bootstrap_python",
        srcs = [
            "Modules/getpath.c",
            "Programs/_bootstrap_python.c",
            "Python/frozen_modules/getpath.h",
            "Python/frozen_modules/importlib._bootstrap.h",
            "Python/frozen_modules/importlib._bootstrap_external.h",
            "Python/frozen_modules/zipimport.h",
        ],
        copts = getpath_copts + core_copts,
        deps = [
            bootstrap_modules,
            ":headers",
            ":python_core_no_frozen",
        ],
        linkopts = linkopts,
    )

    _exec_files(
        name = "_bootstrap_python_exec",
        src = ":_bootstrap_python",
    )

    # deepfreeze.py imports the source standard library, reads
    # Include/internal/pycore_global_strings.h, and scans every C source and
    # header in these directories through generate_global_objects.py.
    deepfreeze_script = "Tools/scripts/deepfreeze.py" if version == "3.11" else "Tools/build/deepfreeze.py"
    deepfreeze_inputs = native.glob([
        "Include/internal/pycore_global_strings.h",
        "Lib/**",
        "Modules/**/*.c",
        "Modules/**/*.h",
        "Objects/**/*.c",
        "Objects/**/*.h",
        "PC/**/*.c",
        "PC/**/*.h",
        "Parser/**/*.c",
        "Parser/**/*.h",
        "Programs/**/*.c",
        "Programs/**/*.h",
        "Python/**/*.c",
        "Python/**/*.h",
        "Tools/build/*.py",
        "Tools/scripts/*.py",
    ], allow_empty = True) + ["Modules/Setup.local"] + frozen_modules.keys()

    frozen_arguments = [
        "$(location %s):%s" % (output, module_name)
        for output, (module_name, _source) in frozen_modules.items()
    ]

    run_binary(
        name = "deepfreeze",
        args = [
            "$(execpath :_bootstrap_python_exec)",
            "$(execpath Lib/os.py)",
            "$(execpath Modules/Setup.local)",
            "$(execpath %s)" % deepfreeze_script,
            "$(execpath bazel_generated/deepfreeze.c)",
        ] + frozen_arguments,
        srcs = deepfreeze_inputs + [":_bootstrap_python_exec"],
        outs = ["bazel_generated/deepfreeze.c"],
        tool = "@cpython//python/private:deepfreeze",
    )

    return [":deepfreeze"]
