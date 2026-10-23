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

def dependency(name):
    """Returns the label of a native library dependency."""
    if name not in DEPENDENCY_DEFAULTS:
        fail("Unknown CPython dependency {!r}".format(name))
    return "@{}//:{}".format(DEPENDENCIES_REPOSITORY, name)

def _cpython_dependencies_repository_impl(repository_ctx):
    repository_ctx.file("BUILD.bazel", "\n".join([
        """alias(
    name = "{name}",
    actual = "{actual}",
    visibility = ["//visibility:public"],
)
""".format(name = name, actual = actual)
        for name, actual in sorted(repository_ctx.attr.dependencies.items())
    ]))

cpython_dependencies_repository = repository_rule(
    implementation = _cpython_dependencies_repository_impl,
    attrs = {
        "dependencies": attr.string_dict(mandatory = True),
    },
)
