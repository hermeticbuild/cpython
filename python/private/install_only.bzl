"""Deterministic CPython install_only archive."""

load("@rules_shell//shell:sh_test.bzl", "sh_test")
load("@tar.bzl", "mtree_mutate", "mtree_spec", "tar")

def cpython_install_only(version, install_tree = ":install_tree"):
    """Defines the python-build-standalone-style install_only archive."""
    mtree_spec(
        name = "_install_only_mtree",
        srcs = [install_tree],
        include_runfiles = False,
        visibility = ["//visibility:private"],
    )

    mtree_mutate(
        name = "_install_only_normalized_mtree",
        mtree = ":_install_only_mtree",
        group = "0",
        groupname = "root",
        includes = ["@cpython//python/private:install_only_mtree.awk"],
        mtime = 1704067200,
        owner = "0",
        ownername = "root",
        script_args = select({
            "@platforms//os:linux": {
                "add_python_symlinks": "1",
                "python_version": version,
            },
            "@platforms//os:macos": {
                "add_python_symlinks": "1",
                "python_version": version,
            },
            "//conditions:default": {},
        }),
        strip_prefix = "install",
        visibility = ["//visibility:private"],
    )

    tar(
        name = "install_only",
        srcs = [install_tree],
        compress = "gzip",
        compute_unused_inputs = 1,
        mtree = ":_install_only_normalized_mtree",
        out = "python-install_only.tar.gz",
    )

    sh_test(
        name = "install_only_test",
        srcs = ["@cpython//python/private:install_only_test.sh"],
        args = [
            "$(rlocationpath :install_tree)",
            "$(rlocationpath :install_only)",
            "$(rlocationpath @cpython//python/private:install_only_test.py)",
            version,
        ],
        data = [
            ":install_only",
            ":install_tree",
            "@bazel_tools//tools/bash/runfiles",
            "@cpython//python/private:install_only_test.py",
        ],
        visibility = ["//visibility:private"],
    )
