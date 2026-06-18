"""Exact supported CPython release records."""

_RELEASE_LEVEL_CODES = {
    "alpha": 0xA,
    "beta": 0xB,
    "candidate": 0xC,
    "final": 0xF,
}

_COMMON_PATCHES = [
    Label("//python/patches/common:cgi-nonfork-content-length-test.patch"),
]

def _cpython_release(
        release,
        repository_name,
        sha256,
        patches,
        needs_deepfreeze,
        venv_launcher_kind,
        windows_pyconfig_template,
        build_details_schema = None,
        supports_isolated_interpreters = None,
        release_level = "final",
        serial = 0):
    version_parts = release.split(".")
    if len(version_parts) != 3:
        fail("CPython release must contain major, minor, and micro: {}".format(repr(release)))
    if release_level not in _RELEASE_LEVEL_CODES:
        fail("unsupported CPython release level: {}".format(repr(release_level)))
    if venv_launcher_kind not in ["dedicated", "redirect"]:
        fail("unsupported CPython venv launcher kind: {}".format(repr(venv_launcher_kind)))

    major = int(version_parts[0])
    minor = int(version_parts[1])
    micro = int(version_parts[2])
    minor_version = "{}.{}".format(major, minor)
    cache_tag = "cpython-{}{}".format(major, minor)
    release_level_code = _RELEASE_LEVEL_CODES[release_level]
    redirect_venv_launcher = venv_launcher_kind == "redirect"
    return struct(
        build_details_schema = build_details_schema,
        cache_tag = cache_tag,
        hexversion = (
            major * 0x1000000 +
            minor * 0x10000 +
            micro * 0x100 +
            release_level_code * 0x10 +
            serial
        ),
        major = major,
        micro = micro,
        minor = minor,
        minor_version = minor_version,
        needs_deepfreeze = needs_deepfreeze,
        patches = patches,
        release = release,
        release_level = release_level,
        repository_name = repository_name,
        resource_field3 = micro * 1000 + release_level_code * 10 + serial,
        serial = serial,
        sha256 = sha256,
        soabi = cache_tag,
        strip_prefix = "Python-{}".format(release),
        urls = [
            "https://www.python.org/ftp/python/{release}/Python-{release}.tar.xz".format(
                release = release,
            ),
        ],
        supports_isolated_interpreters = supports_isolated_interpreters,
        venv_launcher_kind = venv_launcher_kind,
        venv_launcher_runtime_name = "python" if redirect_venv_launcher else "venvlauncher",
        venv_launcher_source = "PC/launcher.c" if redirect_venv_launcher else "PC/venvlauncher.c",
        venvw_launcher_runtime_name = "pythonw" if redirect_venv_launcher else "venvwlauncher",
        windows_pyconfig_template = windows_pyconfig_template,
    )

def _validate_releases(releases):
    repository_names = {}
    for minor_version, release in releases.items():
        if minor_version != release.minor_version:
            fail(
                "CPython release key {} does not match {}".format(
                    repr(minor_version),
                    repr(release.minor_version),
                ),
            )
        if release.repository_name in repository_names:
            fail(
                "CPython releases {} and {} both use repository {}".format(
                    repository_names[release.repository_name],
                    minor_version,
                    repr(release.repository_name),
                ),
            )
        repository_names[release.repository_name] = minor_version

        if (release.build_details_schema == None) != (release.supports_isolated_interpreters == None):
            fail(
                "CPython {} must define build_details_schema and supports_isolated_interpreters together".format(
                    minor_version,
                ),
            )

        patch_labels = {}
        for patch in release.patches:
            patch_label = str(patch)
            if patch_label in patch_labels:
                fail("CPython {} repeats patch {}".format(minor_version, patch_label))
            patch_labels[patch_label] = True
    return releases

CPYTHON_RELEASES = _validate_releases({
    "3.11": _cpython_release(
        release = "3.11.15",
        repository_name = "python3_11",
        sha256 = "272179ddd9a2e41a0fc8e42e33dfbdca0b3711aa5abf372d3f2d51543d09b625",
        patches = [
            Label("//python/patches/common:getpath-generated-header.patch"),
            Label("//python/patches/3.11:clang-cl.patch"),
            Label("//python/patches/common:multiprocessing-semaphore-value-type.patch"),
            Label("//python/patches/3.11:test-ssl-tls-rejection-oserror.patch"),
            Label("//python/patches/common:winapi-previous-token-size.patch"),
            Label("//python/patches/3.11:wincrypt-header.patch"),
            Label("//python/patches/common:atomic-clang-cl-casts.patch"),
        ] + _COMMON_PATCHES + [
            Label("//python/patches/common:tarfile-mode-capabilities.patch"),
            Label("//python/patches/common:test-dtrace-windows.patch"),
        ],
        needs_deepfreeze = True,
        venv_launcher_kind = "redirect",
        windows_pyconfig_template = False,
    ),
    "3.12": _cpython_release(
        release = "3.12.13",
        repository_name = "python3_12",
        sha256 = "c08bc65a81971c1dd5783182826503369466c7e67374d1646519adf05207b684",
        patches = [
            Label("//python/patches/common:getpath-generated-header.patch"),
            Label("//python/patches/3.12:multiprocessing-rlock-repr-race.patch"),
            Label("//python/patches/common:multiprocessing-semaphore-value-type.patch"),
            Label("//python/patches/3.12:test-ssl-tls-rejection-oserror.patch"),
            Label("//python/patches/common:winapi-previous-token-size.patch"),
            Label("//python/patches/common:atomic-clang-cl-casts.patch"),
        ] + _COMMON_PATCHES + [
            Label("//python/patches/common:tarfile-mode-capabilities.patch"),
            Label("//python/patches/common:test-dtrace-windows.patch"),
        ],
        needs_deepfreeze = True,
        venv_launcher_kind = "redirect",
        windows_pyconfig_template = False,
    ),
    "3.13": _cpython_release(
        release = "3.13.13",
        repository_name = "python3_13",
        sha256 = "2ab91ff401783ccca64f75d10c882e957bdfd60e2bf5a72f8421793729b78a71",
        patches = [
            Label("//python/patches/3.13:stopwatch-perf-counter.patch"),
            Label("//python/patches/common:multiprocessing-semaphore-value-type.patch"),
            Label("//python/patches/common:winapi-previous-token-size.patch"),
        ] + _COMMON_PATCHES,
        needs_deepfreeze = False,
        venv_launcher_kind = "dedicated",
        windows_pyconfig_template = True,
    ),
    "3.14": _cpython_release(
        release = "3.14.5",
        repository_name = "python3_14",
        sha256 = "7e32597b99e5d9a39abed35de4693fa169df3e5850d4c334337ffd6a19a36db6",
        patches = _COMMON_PATCHES,
        needs_deepfreeze = False,
        venv_launcher_kind = "dedicated",
        windows_pyconfig_template = False,
        build_details_schema = "1.0",
        supports_isolated_interpreters = True,
    ),
})

SUPPORTED_PYTHON_VERSIONS = sorted(CPYTHON_RELEASES.keys())
