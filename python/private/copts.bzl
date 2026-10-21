"""C options shared by every target compiled from the CPython sources."""

VISIBILITY_COPTS = select({
    "@platforms//os:windows": [],
    "//conditions:default": ["-fvisibility=hidden"],
})
