"""Compilation of Windows resource scripts with the hermetic LLVM toolchain."""

load("@bazel_skylib//rules/directory:providers.bzl", "DirectoryInfo")

def _windows_resource_impl(ctx):
    output = ctx.outputs.out
    resolved_source = ctx.actions.declare_file(ctx.label.name + ".resolved.rc")
    resource_substitutions = {}
    resource_files = []
    for resource_name, resource_target in ctx.attr.resources.items():
        files = resource_target.files.to_list()
        if len(files) != 1:
            fail("Windows resource {} must provide exactly one file".format(resource_target.label))
        resource_file = files[0]
        resource_files.append(resource_file)
        resource_substitutions["\"{}\"".format(resource_name)] = "\"{}\"".format(resource_file.path)
    ctx.actions.expand_template(
        output = resolved_source,
        substitutions = resource_substitutions,
        template = ctx.file.src,
    )

    arguments = ctx.actions.args()
    arguments.add("/nologo")
    arguments.add("/c", "1252")
    arguments.add_all(ctx.attr.defines, before_each = "/d")

    input_files = list(ctx.files.inputs) + resource_files
    input_files.append(resolved_source)
    include_directories = {}
    for include_root in ctx.files.include_roots:
        include_directories[include_root.dirname] = None
        input_files.append(include_root)
    for system_include_target in ctx.attr.system_include_directories:
        system_include = system_include_target[DirectoryInfo]
        include_directories[system_include.path] = None
        input_files.extend(system_include.transitive_files.to_list())

    for include_directory in sorted(include_directories):
        arguments.add("/i", include_directory)
    arguments.add("/fo", output)
    arguments.add(resolved_source)

    ctx.actions.run(
        arguments = [arguments],
        executable = ctx.executable._llvm_rc,
        inputs = depset(input_files),
        mnemonic = "WindowsResourceCompile",
        outputs = [output],
        tools = [ctx.attr._llvm_rc[DefaultInfo].files_to_run],
    )

    return [DefaultInfo(files = depset([output]))]

windows_resource = rule(
    implementation = _windows_resource_impl,
    attrs = {
        "defines": attr.string_list(),
        "include_roots": attr.label_list(allow_files = True),
        "inputs": attr.label_list(allow_files = True),
        "out": attr.output(mandatory = True),
        "resources": attr.string_keyed_label_dict(allow_files = True),
        "src": attr.label(
            allow_single_file = [".rc"],
            mandatory = True,
        ),
        "system_include_directories": attr.label_list(
            providers = [DirectoryInfo],
        ),
        "_llvm_rc": attr.label(
            allow_files = True,
            cfg = "exec",
            default = "@llvm//tools:llvm-rc",
            executable = True,
        ),
    },
)
