"""Deterministic CPython install_only archive."""

load("@bazel_lib//lib:run_binary.bzl", "run_binary")
load("@rules_shell//shell:sh_test.bzl", "sh_test")
load("@tar.bzl", "mtree_spec", "tar")

def cpython_install_only(version, install_tree = ":install_tree"):
    """Defines the python-build-standalone-style install_only archive."""
    mtree_spec(
        name = "_install_only_mtree",
        srcs = [install_tree],
        include_runfiles = False,
        visibility = ["//visibility:private"],
    )

    run_binary(
        name = "_install_only_normalized_mtree",
        srcs = [":_install_only_mtree"],
        outs = ["_install_only_normalized.mtree"],
        args = [
            "$(execpath :_install_only_mtree)",
            "$(execpath _install_only_normalized.mtree)",
            version,
        ] + select({
            "@platforms//os:linux": ["--add-python-symlinks"],
            "@platforms//os:macos": ["--add-python-symlinks"],
            "//conditions:default": [],
        }),
        tool = "@cpython//python/private:install_only_mtree",
        visibility = ["//visibility:private"],
    )

    tar(
        name = "install_only",
        srcs = [install_tree],
        compress = "gzip",
        compute_unused_inputs = 0,
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
