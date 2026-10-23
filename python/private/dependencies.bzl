"""Native libraries linked into the CPython builds."""

DEPENDENCIES_REPOSITORY = "cpython_deps"

DEPENDENCY_DEFAULTS = {
    "bzip2": "@bzip2//:bz2",
    "bzip2_license": "@bzip2//:LICENSE",
    "libffi": "@cpython_libffi//:libffi",
    "libffi_license": "@cpython_libffi//:LICENSE",
    "openssl_crypto": "@openssl//:crypto",
    "openssl_license": "@openssl//:LICENSE.txt",
    "openssl_ssl": "@openssl//:ssl",
    "sqlite3": "@cpython//python/private/deps:sqlite3",
    "xz": "@xz//:lzma",
    "xz_license": "@xz//:COPYING",
    "zlib": "@zlib//:zlib",
    "zlib_license": "@zlib//:LICENSE",
}

SHARED_LIBRARY_DEPENDENCIES = [
    "bzip2",
    "libffi",
    "openssl_crypto",
    "openssl_ssl",
    "sqlite3",
    "xz",
    "zlib",
]

def dependency(name):
    """Returns the label of a native library dependency."""
    if name not in DEPENDENCY_DEFAULTS:
        fail("Unknown CPython dependency {!r}".format(name))
    return "@{}//:{}".format(DEPENDENCIES_REPOSITORY, name)

def dependency_names(deps):
    """Returns the names of the native dependencies among deps."""
    prefix = "@{}//:".format(DEPENDENCIES_REPOSITORY)
    return [dep[len(prefix):] for dep in deps if dep.startswith(prefix)]

def shared_library_dependencies(shared_libraries, names):
    """Returns the shared libraries provided for the given native dependencies."""
    return [shared_libraries[name] for name in sorted({name: True for name in names}) if name in shared_libraries]

def _alias(name, actual):
    return """alias(
    name = "{name}",
    actual = "{actual}",
    visibility = ["//visibility:public"],
)
""".format(name = name, actual = actual)

def _cpython_dependencies_repository_impl(repository_ctx):
    shared_libraries = repository_ctx.attr.shared_libraries
    repository_ctx.file("BUILD.bazel", "\n".join(
        [_alias(name, actual) for name, actual in sorted(repository_ctx.attr.dependencies.items())] +
        [_alias(name + "_shared_library", actual) for name, actual in sorted(shared_libraries.items())],
    ))
    repository_ctx.file("shared_libraries.bzl", "SHARED_LIBRARIES = {\n" + "".join([
        """    "{name}": Label("//:{name}_shared_library"),\n""".format(name = name)
        for name in sorted(shared_libraries)
    ]) + "}\n")

cpython_dependencies_repository = repository_rule(
    implementation = _cpython_dependencies_repository_impl,
    attrs = {
        "dependencies": attr.string_dict(mandatory = True),
        "shared_libraries": attr.string_dict(),
    },
)
