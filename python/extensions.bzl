"""Bzlmod extension for selecting CPython source releases."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//python/private:repositories.bzl", "cpython_source_repository")
load("//python/private:versions.bzl", "CPYTHON_RELEASES")

_BUILD_FILE = Label("//:cpython.BUILD.bazel")
_LIBFFI_BUILD_FILE = Label("//:libffi.BUILD.bazel")
_PATCHES = {
    "3.11": [
        Label("//python/patches/3.11:getpath-generated-header.patch"),
        Label("//python/patches/3.11:libmpdec-clang-cl.patch"),
        Label("//python/patches/3.11:multiprocessing-semaphore-value-type.patch"),
        Label("//python/patches/3.11:pyconfig-clang-cl.patch"),
        Label("//python/patches/3.11:test-ssl-tls-rejection-oserror.patch"),
        Label("//python/patches/3.11:timeval-clang-cl.patch"),
        Label("//python/patches/3.11:tracemalloc-clang-cl-pack.patch"),
        Label("//python/patches/3.11:winapi-previous-token-size.patch"),
        Label("//python/patches/3.11:wincrypt-header.patch"),
        Label("//python/patches/common:atomic-clang-cl-casts.patch"),
        Label("//python/patches/common:cgi-nonfork-content-length-test.patch"),
        Label("//python/patches/common:static-windows-winver.patch"),
        Label("//python/patches/common:tarfile-mode-capabilities.patch"),
        Label("//python/patches/common:test-dtrace-windows.patch"),
        Label("//python/patches/common:venv-writable-windows-scripts.patch"),
    ],
    "3.12": [
        Label("//python/patches/3.12:getpath-generated-header.patch"),
        Label("//python/patches/3.12:multiprocessing-rlock-repr-race.patch"),
        Label("//python/patches/3.12:multiprocessing-semaphore-value-type.patch"),
        Label("//python/patches/3.12:test-ssl-tls-rejection-oserror.patch"),
        Label("//python/patches/3.12:winapi-previous-token-size.patch"),
        Label("//python/patches/common:atomic-clang-cl-casts.patch"),
        Label("//python/patches/common:cgi-nonfork-content-length-test.patch"),
        Label("//python/patches/common:static-windows-winver.patch"),
        Label("//python/patches/common:tarfile-mode-capabilities.patch"),
        Label("//python/patches/common:test-dtrace-windows.patch"),
        Label("//python/patches/common:venv-writable-windows-scripts.patch"),
    ],
    "3.13": [
        Label("//python/patches/3.13:multiprocessing-semaphore-value-type.patch"),
        Label("//python/patches/3.13:winapi-previous-token-size.patch"),
        Label("//python/patches/common:cgi-nonfork-content-length-test.patch"),
        Label("//python/patches/common:static-windows-winver.patch"),
        Label("//python/patches/common:venv-writable-windows-scripts.patch"),
    ],
    "3.14": [
        Label("//python/patches/common:cgi-nonfork-content-length-test.patch"),
        Label("//python/patches/common:static-windows-winver.patch"),
        Label("//python/patches/common:venv-writable-windows-scripts.patch"),
    ],
}

def _python_impl(module_ctx):
    requested_by_version = {}
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

            if version in requested_by_version:
                fail(
                    "Python version {version!r} was requested by both module {first!r} and module {second!r}".format(
                        version = version,
                        first = requested_by_version[version],
                        second = module.name,
                    ),
                )
            requested_by_version[version] = module.name
            if module.is_root:
                root_requested_versions[version] = True

    if requested_by_version:
        http_archive(
            name = "cpython_libffi",
            build_file = _LIBFFI_BUILD_FILE,
            integrity = "sha256-E4YH3uJovezzdK35FEwA6DnjhUH3XySh/PGLeP2kiy0=",
            patch_args = ["-p1"],
            patches = [Label("//python/patches/libffi:clang-cl-aarch64-hfa.patch")],
            strip_prefix = "libffi-3.4.7",
            urls = ["https://github.com/libffi/libffi/releases/download/v3.4.7/libffi-3.4.7.tar.gz"],
        )

    for version in sorted(requested_by_version.keys()):
        release = CPYTHON_RELEASES[version]
        repository_name = release.repository_name
        cpython_source_repository(
            name = repository_name,
            build_file = _BUILD_FILE,
            patches = _PATCHES[version],
            release = release.release,
            sha256 = release.sha256,
            strip_prefix = release.strip_prefix,
            urls = release.urls,
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
