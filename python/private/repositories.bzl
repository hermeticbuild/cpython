"""Repository rule for an official CPython source release."""

_RUNTIME_TZDATA_SHA256 = "9173fde7d80d9018e02a662e168e5a2d04f87c41ea174b139fbef642eda62d10"
_RUNTIME_TZDATA_STRIP_PREFIX = "tzdata-2026.2/src"
_RUNTIME_TZDATA_URL = "https://files.pythonhosted.org/packages/source/t/tzdata/tzdata-2026.2.tar.gz"

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
    repository_ctx.symlink(repository_ctx.attr.build_file, "BUILD.bazel")
    repository_ctx.file("Modules/Setup.local", "")
    repository_ctx.file("pybuilddir.txt", ".")
    version_parts = repository_ctx.attr.release.split(".")
    minor = ".".join(version_parts[:2])
    cpython_tag = "cpython-{}{}".format(version_parts[0], version_parts[1])
    repository_ctx.file(
        "bazel/release.bzl",
        "PYTHON_NEEDS_DEEPFREEZE = {needs_deepfreeze}\nPYTHON_VERSION = {minor}\nPYTHON_SOABI = {soabi}\n".format(
            minor = repr(minor),
            needs_deepfreeze = repr(minor in ["3.11", "3.12"]),
            soabi = repr(cpython_tag),
        ),
    )
    repository_ctx.file(
        "bazel/BUILD.bazel",
        "exports_files([\"release.bzl\"])\n",
    )

cpython_source_repository = repository_rule(
    implementation = _cpython_source_repository_impl,
    attrs = {
        "build_file": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "patches": attr.label_list(
            allow_files = True,
        ),
        "release": attr.string(mandatory = True),
        "sha256": attr.string(mandatory = True),
        "strip_prefix": attr.string(mandatory = True),
        "urls": attr.string_list(mandatory = True),
    },
)
