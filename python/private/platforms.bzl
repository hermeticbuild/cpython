"""Exact supported CPython target records."""

CPYTHON_TARGETS = {
    "darwin_arm64": struct(
        config_setting = ":darwin_arm64",
        constraint_values = [
            "@platforms//cpu:aarch64",
            "@platforms//os:macos",
        ],
        multiarch = "darwin",
        sysconfig_platform = "darwin",
    ),
    "darwin_x86_64": struct(
        config_setting = ":darwin_x86_64",
        constraint_values = [
            "@platforms//cpu:x86_64",
            "@platforms//os:macos",
        ],
        multiarch = "darwin",
        sysconfig_platform = "darwin",
    ),
    "linux_arm64": struct(
        config_setting = ":linux_arm64",
        constraint_values = [
            "@platforms//cpu:aarch64",
            "@platforms//os:linux",
        ],
        multiarch = "aarch64-linux-gnu",
        sysconfig_platform = "linux",
    ),
    "linux_x86_64": struct(
        config_setting = ":linux_x86_64",
        constraint_values = [
            "@platforms//cpu:x86_64",
            "@platforms//os:linux",
        ],
        multiarch = "x86_64-linux-gnu",
        sysconfig_platform = "linux",
    ),
    "windows_arm64": struct(
        config_setting = ":windows_arm64",
        constraint_values = [
            "@platforms//cpu:aarch64",
            "@platforms//os:windows",
        ],
        multiarch = "win-arm64",
        sysconfig_platform = "windows",
    ),
    "windows_x86_64": struct(
        config_setting = ":windows_x86_64",
        constraint_values = [
            "@platforms//cpu:x86_64",
            "@platforms//os:windows",
        ],
        multiarch = "win-amd64",
        sysconfig_platform = "windows",
    ),
}

def declare_cpython_target_config_settings():
    """Declares one config_setting for every supported CPython target."""
    for name in sorted(CPYTHON_TARGETS.keys()):
        native.config_setting(
            name = name,
            constraint_values = CPYTHON_TARGETS[name].constraint_values,
        )

def cpython_target_field_select(field, targets = None):
    """Returns a select whose values are one exact CPython target field."""
    selected_targets = sorted(CPYTHON_TARGETS.keys()) if targets == None else targets
    return select({
        CPYTHON_TARGETS[name].config_setting: getattr(CPYTHON_TARGETS[name], field)
        for name in selected_targets
    })
