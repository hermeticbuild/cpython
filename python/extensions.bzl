"""Bzlmod extension for selecting CPython source releases."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//python/private:repositories.bzl", "cpython_source_repository")
load("//python/private:versions.bzl", "CPYTHON_RELEASES")

_BUILD_FILE = Label("//:cpython.BUILD.bazel")
_LIBFFI_BUILD_FILE = Label("//:libffi.BUILD.bazel")

def _python_impl(module_ctx):
    requested_versions = {}
    root_requested_versions = {}

    for module in module_ctx.modules:
        for version_tag in module.tags.version:
            version = version_tag.version
            if version not in CPYTHON_RELEASES:
                fail(
                    "Unsupported Python version {version!r}; supported versions are {supported}".format(
                        version = version,
                        supported = ", ".join(sorted(CPYTHON_RELEASES.keys())),
                    ),
                )

            requested_versions[version] = True
            if module.is_root:
                root_requested_versions[version] = True

    if requested_versions:
        http_archive(
            name = "cpython_libffi",
            build_file = _LIBFFI_BUILD_FILE,
            integrity = "sha256-E4YH3uJovezzdK35FEwA6DnjhUH3XySh/PGLeP2kiy0=",
            patch_args = ["-p1"],
            patches = [
                Label("//python/patches/libffi:clang-cl-aarch64-hfa.patch"),
                Label("//python/patches/libffi:windows-arm64-seh.patch"),
            ],
            strip_prefix = "libffi-3.4.7",
            urls = ["https://github.com/libffi/libffi/releases/download/v3.4.7/libffi-3.4.7.tar.gz"],
        )

    for version in sorted(requested_versions.keys()):
        release = CPYTHON_RELEASES[version]
        repository_name = release.repository_name
        cpython_source_repository(
            name = repository_name,
            build_file = _BUILD_FILE,
            build_details_schema = release.build_details_schema or "",
            cache_tag = release.cache_tag,
            hexversion = release.hexversion,
            major = release.major,
            micro = release.micro,
            minor = release.minor,
            minor_version = release.minor_version,
            needs_deepfreeze = release.needs_deepfreeze,
            patches = release.patches,
            release = release.release,
            release_level = release.release_level,
            resource_field3 = release.resource_field3,
            serial = release.serial,
            sha256 = release.sha256,
            soabi = release.soabi,
            strip_prefix = release.strip_prefix,
            supports_isolated_interpreters = release.supports_isolated_interpreters or False,
            urls = release.urls,
            venv_launcher_kind = release.venv_launcher_kind,
            venv_launcher_runtime_name = release.venv_launcher_runtime_name,
            venv_launcher_source = release.venv_launcher_source,
            venvw_launcher_runtime_name = release.venvw_launcher_runtime_name,
            windows_pyconfig_template = release.windows_pyconfig_template,
        )

    root_direct_deps = [
        CPYTHON_RELEASES[version].repository_name
        for version in sorted(root_requested_versions.keys())
    ]
    root_direct_dev_deps = []
    if not module_ctx.root_module_has_non_dev_dependency:
        root_direct_dev_deps = root_direct_deps
        root_direct_deps = []

    return module_ctx.extension_metadata(
        reproducible = True,
        root_module_direct_deps = root_direct_deps,
        root_module_direct_dev_deps = root_direct_dev_deps,
    )

_version = tag_class(
    attrs = {
        "version": attr.string(mandatory = True),
    },
    doc = "Selects a supported Python minor version.",
)

python = module_extension(
    implementation = _python_impl,
    tag_classes = {
        "version": _version,
    },
)
