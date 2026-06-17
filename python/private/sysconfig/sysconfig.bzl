"""Build-time generation of CPython sysconfig metadata."""

def merge_sysconfig_build_vars(common, platform):
    """Returns one build-variable dictionary without mutating either input."""
    result = dict(common)
    result.update(platform)
    return result

def _cpython_sysconfig_impl(ctx):
    if ctx.attr.platform not in ["darwin", "linux", "windows"]:
        fail("unsupported CPython sysconfig platform: {}".format(ctx.attr.platform))

    forbidden_runtime_vars = [
        "base",
        "installed_base",
        "installed_platbase",
        "platbase",
        "projectbase",
    ]
    integer_build_vars = {name: True for name in ctx.attr.integer_build_vars}
    for name in integer_build_vars:
        if name not in ctx.attr.build_vars:
            fail("integer_build_vars contains unknown build variable {}".format(name))

    for name in sorted(ctx.attr.build_vars.keys()):
        if name.startswith("HAVE_") or name.startswith("WITH_"):
            fail("{} must come from pyconfig.h, not build_vars".format(name))
        if name in forbidden_runtime_vars:
            fail("{} is computed by sysconfig at runtime".format(name))
        if "\t" in name or "\n" in name:
            fail("invalid sysconfig variable name: {}".format(name))
        value = ctx.attr.build_vars[name]
        if "\n" in value:
            fail("sysconfig variable {} contains a newline".format(name))

    build_vars = ctx.actions.declare_file(ctx.label.name + ".build_vars")
    ctx.actions.write(
        build_vars,
        "".join([
            "{}\t{}\t{}\n".format(
                "I" if name in integer_build_vars else "S",
                name,
                ctx.attr.build_vars[name],
            )
            for name in sorted(ctx.attr.build_vars.keys())
        ]),
    )

    sysconfig_data = ctx.actions.declare_file(
        "Lib/_sysconfigdata__{}_{}.py".format(
            ctx.attr.platform,
            ctx.attr.multiarch,
        ),
    )
    makefile = ctx.actions.declare_file("Makefile")
    args = ctx.actions.args()
    args.add("--pyconfig", ctx.file.pyconfig)
    args.add("--build-vars", build_vars)
    args.add("--makefile-template", ctx.file.makefile_template)
    args.add("--sysconfig-out", sysconfig_data)
    args.add("--makefile-out", makefile)
    ctx.actions.run(
        executable = ctx.executable._generator,
        arguments = [args],
        inputs = [ctx.file.pyconfig, ctx.file.makefile_template, build_vars],
        outputs = [sysconfig_data, makefile],
        mnemonic = "CpythonSysconfig",
        progress_message = "Generating CPython sysconfig metadata for %{label}",
    )

    return [
        DefaultInfo(files = depset([sysconfig_data, makefile])),
        OutputGroupInfo(
            makefile = depset([makefile]),
            sysconfig_data = depset([sysconfig_data]),
        ),
    ]

cpython_sysconfig = rule(
    implementation = _cpython_sysconfig_impl,
    attrs = {
        "build_vars": attr.string_dict(mandatory = True),
        "integer_build_vars": attr.string_list(),
        "makefile_template": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "multiarch": attr.string(mandatory = True),
        "platform": attr.string(mandatory = True),
        "pyconfig": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "_generator": attr.label(
            cfg = "exec",
            default = Label("@cpython//python/private/sysconfig:sysconfig_generator"),
            executable = True,
        ),
    },
)
