"""Pinned official CPython source releases."""

CPYTHON_RELEASES = {
    "3.11": struct(
        release = "3.11.15",
        repository_name = "python3_11",
        sha256 = "272179ddd9a2e41a0fc8e42e33dfbdca0b3711aa5abf372d3f2d51543d09b625",
        strip_prefix = "Python-3.11.15",
        urls = [
            "https://www.python.org/ftp/python/3.11.15/Python-3.11.15.tar.xz",
        ],
    ),
    "3.12": struct(
        release = "3.12.13",
        repository_name = "python3_12",
        sha256 = "c08bc65a81971c1dd5783182826503369466c7e67374d1646519adf05207b684",
        strip_prefix = "Python-3.12.13",
        urls = [
            "https://www.python.org/ftp/python/3.12.13/Python-3.12.13.tar.xz",
        ],
    ),
    "3.13": struct(
        release = "3.13.13",
        repository_name = "python3_13",
        sha256 = "2ab91ff401783ccca64f75d10c882e957bdfd60e2bf5a72f8421793729b78a71",
        strip_prefix = "Python-3.13.13",
        urls = [
            "https://www.python.org/ftp/python/3.13.13/Python-3.13.13.tar.xz",
        ],
    ),
    "3.14": struct(
        release = "3.14.5",
        repository_name = "python3_14",
        sha256 = "7e32597b99e5d9a39abed35de4693fa169df3e5850d4c334337ffd6a19a36db6",
        strip_prefix = "Python-3.14.5",
        urls = [
            "https://www.python.org/ftp/python/3.14.5/Python-3.14.5.tar.xz",
        ],
    ),
}
