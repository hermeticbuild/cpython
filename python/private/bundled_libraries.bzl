"""Bundled C libraries shipped in supported CPython release archives."""

load("@rules_cc//cc:cc_library.bzl", "cc_library")

_SUPPORTED_RELEASES = {
    "3.11": "3.11.15",
    "3.11.15": "3.11.15",
    "3.12": "3.12.13",
    "3.12.13": "3.12.13",
    "3.13": "3.13.13",
    "3.13.13": "3.13.13",
    "3.14": "3.14.5",
    "3.14.5": "3.14.5",
}

_EXPAT_HEADERS = [
    "Modules/expat/ascii.h",
    "Modules/expat/asciitab.h",
    "Modules/expat/expat.h",
    "Modules/expat/expat_config.h",
    "Modules/expat/expat_external.h",
    "Modules/expat/iasciitab.h",
    "Modules/expat/internal.h",
    "Modules/expat/latin1tab.h",
    "Modules/expat/nametab.h",
    "Modules/expat/pyexpatns.h",
    "Modules/expat/siphash.h",
    "Modules/expat/utf8tab.h",
    "Modules/expat/xmlrole.h",
    "Modules/expat/xmltok.h",
    "Modules/expat/xmltok_impl.h",
]

_LIBMPDEC_HEADERS = [
    "Modules/_decimal/libmpdec/basearith.h",
    "Modules/_decimal/libmpdec/bits.h",
    "Modules/_decimal/libmpdec/constants.h",
    "Modules/_decimal/libmpdec/convolute.h",
    "Modules/_decimal/libmpdec/crt.h",
    "Modules/_decimal/libmpdec/difradix2.h",
    "Modules/_decimal/libmpdec/fnt.h",
    "Modules/_decimal/libmpdec/fourstep.h",
    "Modules/_decimal/libmpdec/io.h",
    "Modules/_decimal/libmpdec/mpalloc.h",
    "Modules/_decimal/libmpdec/mpdecimal.h",
    "Modules/_decimal/libmpdec/numbertheory.h",
    "Modules/_decimal/libmpdec/sixstep.h",
    "Modules/_decimal/libmpdec/transpose.h",
    "Modules/_decimal/libmpdec/typearith.h",
    "Modules/_decimal/libmpdec/umodarith.h",
]

_LIBMPDEC_SOURCES = [
    "Modules/_decimal/libmpdec/basearith.c",
    "Modules/_decimal/libmpdec/constants.c",
    "Modules/_decimal/libmpdec/context.c",
    "Modules/_decimal/libmpdec/convolute.c",
    "Modules/_decimal/libmpdec/crt.c",
    "Modules/_decimal/libmpdec/difradix2.c",
    "Modules/_decimal/libmpdec/fnt.c",
    "Modules/_decimal/libmpdec/fourstep.c",
    "Modules/_decimal/libmpdec/io.c",
    "Modules/_decimal/libmpdec/mpalloc.c",
    "Modules/_decimal/libmpdec/mpdecimal.c",
    "Modules/_decimal/libmpdec/mpsignal.c",
    "Modules/_decimal/libmpdec/numbertheory.c",
    "Modules/_decimal/libmpdec/sixstep.c",
    "Modules/_decimal/libmpdec/transpose.c",
]

_HACL_COMMON_HEADERS = [
    "Modules/_hacl/Hacl_Streaming_Types.h",
    "Modules/_hacl/include/krml/FStar_UInt128_Verified.h",
    "Modules/_hacl/include/krml/FStar_UInt_8_16_32_64.h",
    "Modules/_hacl/include/krml/fstar_uint128_struct_endianness.h",
    "Modules/_hacl/include/krml/internal/target.h",
    "Modules/_hacl/include/krml/lowstar_endianness.h",
    "Modules/_hacl/include/krml/types.h",
    "Modules/_hacl/python_hacl_namespaces.h",
]

_BLAKE2_HEADERS = [
    "Modules/_blake2/blake2module.h",
    "Modules/_blake2/clinic/blake2b_impl.c.h",
    "Modules/_blake2/clinic/blake2s_impl.c.h",
    "Modules/_blake2/impl/blake2-config.h",
    "Modules/_blake2/impl/blake2-impl.h",
    "Modules/_blake2/impl/blake2.h",
    "Modules/_blake2/impl/blake2b-load-sse2.h",
    "Modules/_blake2/impl/blake2b-load-sse41.h",
    "Modules/_blake2/impl/blake2b-round.h",
    "Modules/_blake2/impl/blake2s-load-sse2.h",
    "Modules/_blake2/impl/blake2s-load-sse41.h",
    "Modules/_blake2/impl/blake2s-load-xop.h",
    "Modules/_blake2/impl/blake2s-round.h",
]

_BLAKE2_IMPLEMENTATION_SOURCES = [
    "Modules/_blake2/impl/blake2b-ref.c",
    "Modules/_blake2/impl/blake2b.c",
    "Modules/_blake2/impl/blake2s-ref.c",
    "Modules/_blake2/impl/blake2s.c",
]

def _hacl_library(name, algorithm, visibility):
    cc_library(
        name = name,
        srcs = ["Modules/_hacl/Hacl_Hash_{}.c".format(algorithm)],
        hdrs = native.glob(["Modules/_hacl/**/*.h"]),
        defines = [
            "_BSD_SOURCE",
            "_DEFAULT_SOURCE",
        ],
        includes = [
            "Modules/_hacl",
            "Modules/_hacl/include",
            "Modules/_hacl/internal",
        ],
        visibility = visibility,
    )

def bundled_libraries(
        version,
        python_headers = ":headers",
        visibility = ["//visibility:public"]):
    """Declares bundled-library targets in an unpacked CPython repository.

    CPython 3.12.13 and 3.13.13 ship the same source sets declared here.
    Python 3.13 prefers a system libmpdec when one is available, but retains
    this bundled libmpdec source set as a fallback. This macro always selects
    the archive's hermetic libmpdec implementation.

    Upstream archives do not ship `libHacl_Hash_SHA2.a`. Upstream Make builds
    that archive from `Hacl_Hash_SHA2.c`; `bundled_hacl_sha2` compiles the C
    source directly and is the Bazel substitute for the generated archive.

    Upstream `_blake2` sources include one BLAKE2 implementation C file from
    `blake2b_impl.c` and `blake2s_impl.c`. `bundled_blake2` therefore exposes
    those implementation C files as textual headers. Compiling them as normal
    `srcs` would duplicate the definitions in the extension module.

    Args:
        version: `3.12`, `3.12.13`, `3.13`, or `3.13.13`.
        python_headers: Target providing the generated `pyconfig.h` used by
            CPython's bundled Expat configuration.
        visibility: Visibility assigned to every bundled-library target.
    """
    if version not in _SUPPORTED_RELEASES:
        fail(
            (
                "unsupported CPython release {version}; supported releases " +
                "are {supported}"
            ).format(
                supported = ", ".join(sorted(_SUPPORTED_RELEASES.keys())),
                version = version,
            ),
        )

    cc_library(
        name = "bundled_expat",
        srcs = [
            "Modules/expat/xmlparse.c",
            "Modules/expat/xmlrole.c",
            "Modules/expat/xmltok.c",
        ],
        hdrs = _EXPAT_HEADERS,
        textual_hdrs = [
            "Modules/expat/xmltok_impl.c",
            "Modules/expat/xmltok_ns.c",
        ],
        deps = [python_headers],
        includes = ["Modules/expat"],
        linkopts = ["-lm"],
        visibility = visibility,
    )

    cc_library(
        name = "bundled_libmpdec",
        srcs = _LIBMPDEC_SOURCES,
        hdrs = _LIBMPDEC_HEADERS,
        defines = [
            "ANSI=1",
            "CONFIG_64=1",
            "HAVE_UINT128_T=1",
        ],
        deps = [python_headers],
        includes = ["Modules/_decimal/libmpdec"],
        linkopts = ["-lm"],
        visibility = visibility,
    )

    if version not in ["3.11", "3.11.15"]:
        _hacl_library("bundled_hacl_md5", "MD5", visibility)
        _hacl_library("bundled_hacl_sha1", "SHA1", visibility)
        _hacl_library("bundled_hacl_sha2", "SHA2", visibility)
        _hacl_library("bundled_hacl_sha3", "SHA3", visibility)

    if version in ["3.14", "3.14.5"]:
        cc_library(
            name = "bundled_hacl_blake2",
            srcs = [
                "Modules/_hacl/Hacl_Hash_Blake2b.c",
                "Modules/_hacl/Hacl_Hash_Blake2s.c",
                "Modules/_hacl/Lib_Memzero0.c",
            ],
            hdrs = native.glob(["Modules/_hacl/**/*.h"]),
            defines = [
                "_BSD_SOURCE",
                "_DEFAULT_SOURCE",
            ],
            includes = [
                "Modules/_hacl",
                "Modules/_hacl/include",
                "Modules/_hacl/internal",
            ],
            visibility = visibility,
        )
        cc_library(
            name = "bundled_hacl_hmac",
            srcs = [
                "Modules/_hacl/Hacl_HMAC.c",
                "Modules/_hacl/Hacl_Streaming_HMAC.c",
            ],
            hdrs = native.glob(["Modules/_hacl/**/*.h"]),
            defines = [
                "_BSD_SOURCE",
                "_DEFAULT_SOURCE",
            ],
            includes = [
                "Modules/_hacl",
                "Modules/_hacl/include",
                "Modules/_hacl/internal",
            ],
            deps = [
                ":bundled_hacl_blake2",
                ":bundled_hacl_md5",
                ":bundled_hacl_sha1",
                ":bundled_hacl_sha2",
                ":bundled_hacl_sha3",
            ],
            visibility = visibility,
        )

    if version not in ["3.14", "3.14.5"]:
        cc_library(
            name = "bundled_blake2",
            hdrs = _BLAKE2_HEADERS,
            textual_hdrs = _BLAKE2_IMPLEMENTATION_SOURCES,
            includes = [
                "Modules/_blake2",
                "Modules/_blake2/impl",
            ],
            visibility = visibility,
        )
