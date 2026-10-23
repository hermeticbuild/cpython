"""Build-time generation of CPython sysconfig metadata."""

load("@cpython//python/private:platforms.bzl", "DEFAULT_MACOSX_DEPLOYMENT_TARGET")

def merge_sysconfig_build_vars(common, platform):
    """Returns one build-variable dictionary without mutating either input."""
    result = dict(common)
    result.update(platform)
    return result

def _build_details_json(ctx, build_vars, platform_tag, base_prefix, base_interpreter, headers):
    if ctx.attr.build_details_schema != "1.0":
        fail("unsupported build-details schema: {}".format(ctx.attr.build_details_schema))
    required_vars = [
        "ABIFLAGS",
        "BINDIR",
        "EXT_SUFFIX",
        "INCLUDEPY",
        "MULTIARCH",
        "SHLIB_SUFFIX",
        "VERSION",
        "prefix",
    ]
    for name in required_vars:
        if name not in build_vars:
            fail("build-details generation requires build variable {}".format(name))
    if build_vars["ABIFLAGS"]:
        fail("build-details generation does not describe nonempty ABI flags")

    version_info = {
        "major": ctx.attr.major,
        "minor": ctx.attr.minor,
        "micro": ctx.attr.micro,
        "releaselevel": ctx.attr.release_level,
        "serial": ctx.attr.serial,
    }
    return json.encode_indent({
        "schema_version": ctx.attr.build_details_schema,
        "base_prefix": base_prefix,
        "base_interpreter": base_interpreter,
        "platform": platform_tag,
        "language": {
            "version": build_vars["VERSION"],
            "version_info": version_info,
        },
        "implementation": {
            "name": "cpython",
            "cache_tag": ctx.attr.cache_tag,
            "version": version_info,
            "hexversion": ctx.attr.hexversion,
            "_multiarch": build_vars["MULTIARCH"],
            "supports_isolated_interpreters": ctx.attr.supports_isolated_interpreters,
        },
        "abi": {
            "flags": [],
            "extension_suffix": build_vars["EXT_SUFFIX"],
            "stable_abi_suffix": ".abi3.so",
        },
        "suffixes": {
            "source": [".py"],
            "bytecode": [".pyc"],
            "extensions": [
                build_vars["EXT_SUFFIX"],
                ".abi3.so",
                build_vars["SHLIB_SUFFIX"],
            ],
        },
        "c_api": {
            "headers": headers,
        },
    }) + "\n"

def _cpython_sysconfig_impl(ctx):
    build_vars = dict(ctx.attr.build_vars)
    platform_tag = ctx.attr.platform_tag
    if ctx.attr.platform not in ["darwin", "linux", "windows"]:
        fail("unsupported CPython sysconfig platform: {}".format(ctx.attr.platform))
    if ctx.attr.platform == "darwin":
        deployment_target = str(ctx.fragments.apple.macos_minimum_os_flag or DEFAULT_MACOSX_DEPLOYMENT_TARGET)
        build_vars["MACOSX_DEPLOYMENT_TARGET"] = deployment_target
        platform_tag = platform_tag.format(macosx_deployment_target = deployment_target)

    forbidden_runtime_vars = [
        "base",
        "installed_base",
        "installed_platbase",
        "platbase",
        "projectbase",
    ]
    integer_build_vars = {name: True for name in ctx.attr.integer_build_vars}
    for name in integer_build_vars:
        if name not in build_vars:
            fail("integer_build_vars contains unknown build variable {}".format(name))

    for name in sorted(build_vars.keys()):
        if name.startswith("HAVE_") or name.startswith("WITH_"):
            fail("{} must come from pyconfig.h, not build_vars".format(name))
        if name in forbidden_runtime_vars:
            fail("{} is computed by sysconfig at runtime".format(name))
        if "\t" in name or "\n" in name:
            fail("invalid sysconfig variable name: {}".format(name))
        value = build_vars[name]
        if "\n" in value:
            fail("sysconfig variable {} contains a newline".format(name))

    build_vars_file = ctx.actions.declare_file(ctx.label.name + ".build_vars")
    ctx.actions.write(
        build_vars_file,
        "".join([
            "{}\t{}\t{}\n".format(
                "I" if name in integer_build_vars else "S",
                name,
                build_vars[name],
            )
            for name in sorted(build_vars.keys())
        ]),
    )

    sysconfig_data = ctx.actions.declare_file(
        "Lib/_sysconfigdata__{}_{}.py".format(
            ctx.attr.platform,
            ctx.attr.multiarch,
        ),
    )
    args = ctx.actions.args()
    args.add("--pyconfig", ctx.file.pyconfig)
    args.add("--build-vars", build_vars_file)
    args.add("--sysconfig-out", sysconfig_data)
    inputs = [ctx.file.pyconfig, build_vars_file]
    outputs = [sysconfig_data]
    makefile_outputs = []
    install_build_details_outputs = []
    runtime_build_details_outputs = []
    sysconfig_json_outputs = []
    if ctx.attr.platform != "windows":
        makefile = ctx.actions.declare_file("Makefile")
        args.add("--makefile-template", ctx.file.makefile_template)
        args.add("--makefile-out", makefile)
        inputs.append(ctx.file.makefile_template)
        outputs.append(makefile)
        makefile_outputs.append(makefile)
        if ctx.attr.build_details_schema:
            sysconfig_json = ctx.actions.declare_file(
                "runtime/build/lib.{}-{}/_sysconfig_vars__{}_{}.json".format(
                    platform_tag,
                    "{}.{}".format(ctx.attr.major, ctx.attr.minor),
                    ctx.attr.platform,
                    ctx.attr.multiarch,
                ),
            )
            install_build_details = ctx.actions.declare_file("install_metadata/build-details.json")
            runtime_build_details = ctx.actions.declare_file("runtime/build-details.json")
            args.add("--sysconfig-json-out", sysconfig_json)
            args.add("--major", ctx.attr.major)
            args.add("--minor", ctx.attr.minor)
            args.add("--release", ctx.attr.release)
            ctx.actions.write(
                install_build_details,
                _build_details_json(
                    ctx,
                    build_vars,
                    platform_tag,
                    base_prefix = "../..",
                    base_interpreter = "./bin/python{}".format(build_vars["VERSION"]),
                    headers = "./include/python{}".format(build_vars["VERSION"]),
                ),
            )
            ctx.actions.write(
                runtime_build_details,
                _build_details_json(
                    ctx,
                    build_vars,
                    platform_tag,
                    base_prefix = build_vars["prefix"],
                    base_interpreter = "{}/python{}".format(build_vars["BINDIR"], build_vars["VERSION"]),
                    headers = build_vars["INCLUDEPY"],
                ),
            )
            outputs.append(sysconfig_json)
            sysconfig_json_outputs.append(sysconfig_json)
            install_build_details_outputs.append(install_build_details)
            runtime_build_details_outputs.append(runtime_build_details)
    ctx.actions.run(
        executable = ctx.executable._generator,
        arguments = [args],
        inputs = inputs,
        outputs = outputs,
        mnemonic = "CpythonSysconfig",
        progress_message = "Generating CPython sysconfig metadata for %{label}",
    )

    return [
        DefaultInfo(files = depset(outputs + install_build_details_outputs + runtime_build_details_outputs)),
        OutputGroupInfo(
            install_build_details = depset(install_build_details_outputs),
            makefile = depset(makefile_outputs),
            runtime_build_details = depset(runtime_build_details_outputs),
            sysconfig_data = depset([sysconfig_data]),
            sysconfig_json = depset(sysconfig_json_outputs),
        ),
    ]

cpython_sysconfig = rule(
    implementation = _cpython_sysconfig_impl,
    fragments = ["apple"],
    attrs = {
        "build_details_schema": attr.string(),
        "build_vars": attr.string_dict(mandatory = True),
        "cache_tag": attr.string(mandatory = True),
        "hexversion": attr.int(mandatory = True),
        "integer_build_vars": attr.string_list(),
        "makefile_template": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "major": attr.int(mandatory = True),
        "micro": attr.int(mandatory = True),
        "multiarch": attr.string(mandatory = True),
        "minor": attr.int(mandatory = True),
        "platform": attr.string(mandatory = True),
        "platform_tag": attr.string(mandatory = True),
        "pyconfig": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "release": attr.string(mandatory = True),
        "release_level": attr.string(mandatory = True),
        "serial": attr.int(mandatory = True),
        "supports_isolated_interpreters": attr.bool(),
        "_generator": attr.label(
            cfg = "exec",
            default = Label("@cpython//python/private/sysconfig:sysconfig_generator"),
            executable = True,
        ),
    },
)
