"""Toolchain checks used to generate libffi configuration headers."""

load("@rules_cc_autoconf//autoconf:checks.bzl", "utils")
load("@rules_cc_autoconf//autoconf:defs.bzl", "autoconf", "autoconf_hdr", "checks", "macros")

_HEADERS = [
    "alloca.h",
    "dlfcn.h",
    "inttypes.h",
    "stdint.h",
    "stdio.h",
    "stdlib.h",
    "string.h",
    "strings.h",
    "sys/memfd.h",
    "sys/stat.h",
    "sys/types.h",
    "unistd.h",
]

_PACKAGE_CHECKS = [
    checks.AC_FAIL("HAVE_LONG_DOUBLE_VARIANT"),
    checks.AC_DEFINE("LT_OBJDIR", '".libs/"'),
    checks.AC_DEFINE("PACKAGE", '"libffi"'),
    checks.AC_DEFINE("PACKAGE_BUGREPORT", '"http://github.com/libffi/libffi/issues"'),
    checks.AC_DEFINE("PACKAGE_NAME", '"libffi"'),
    checks.AC_DEFINE("PACKAGE_STRING", '"libffi 3.4.7"'),
    checks.AC_DEFINE("PACKAGE_TARNAME", '"libffi"'),
    checks.AC_DEFINE("PACKAGE_URL", '""'),
    checks.AC_DEFINE("PACKAGE_VERSION", '"3.4.7"'),
    checks.AC_DEFINE("VERSION", '"3.4.7"'),
    checks.AC_FAIL("WORDS_BIGENDIAN"),
    checks.AC_SUBST("VERSION", "3.4.7"),
]

def _compiler_checks():
    return [
        checks.AC_TRY_COMPILE(
            name = "libffi_cv_as_cfi_pseudo_op",
            code = utils.AC_LANG_PROGRAM(
                ['__asm__ (".cfi_sections\\n\\t.cfi_startproc\\n\\t.cfi_endproc");'],
                "",
            ),
        ),
        checks.AC_DEFINE(
            "HAVE_AS_CFI_PSEUDO_OP",
            condition = "libffi_cv_as_cfi_pseudo_op",
            if_false = None,
            if_true = 1,
        ),
        checks.AC_TRY_COMPILE(
            name = "libffi_cv_as_ptrauth",
            code = utils.AC_LANG_PROGRAM(
                [
                    "#ifdef __clang__",
                    "# if __has_feature(ptrauth_calls)",
                    "#  define HAVE_ARM64E_PTRAUTH 1",
                    "# endif",
                    "#endif",
                    "#ifndef HAVE_ARM64E_PTRAUTH",
                    "# error Pointer authentication not supported",
                    "#endif",
                ],
                "",
            ),
        ),
        checks.AC_DEFINE(
            "HAVE_ARM64E_PTRAUTH",
            condition = "libffi_cv_as_ptrauth",
            if_false = None,
            if_true = 1,
        ),
    ]

def _standard_header_checks():
    return [
        checks.AC_TRY_COMPILE(
            name = "libffi_cv_stdc_headers",
            code = utils.AC_LANG_PROGRAM(
                [
                    "#include <float.h>",
                    "#include <stdarg.h>",
                    "#include <stdio.h>",
                    "#include <stdlib.h>",
                    "#include <string.h>",
                ],
                "",
            ),
        ),
        checks.AC_DEFINE(
            "STDC_HEADERS",
            condition = "libffi_cv_stdc_headers",
            if_false = None,
            if_true = 1,
        ),
    ]

def _hidden_visibility_checks():
    return [
        checks.AC_TRY_COMPILE(
            name = "libffi_cv_hidden_visibility_attribute",
            code = utils.AC_LANG_PROGRAM(
                [
                    "#if defined(_WIN32)",
                    "# error COFF does not implement ELF or Mach-O hidden visibility",
                    "#endif",
                    'int __attribute__((visibility("hidden"))) foo(void) { return 1; }',
                ],
                "return foo() != 1;",
            ),
            copts = ["-Werror"],
        ),
        checks.AC_DEFINE(
            "HAVE_HIDDEN_VISIBILITY_ATTRIBUTE",
            condition = "libffi_cv_hidden_visibility_attribute",
            if_false = None,
            if_true = 1,
        ),
    ]

def _long_double_checks():
    return [
        checks.AC_CHECK_SIZEOF("double", define = "SIZEOF_DOUBLE"),
        checks.AC_CHECK_SIZEOF("long double", define = "SIZEOF_LONG_DOUBLE"),
        checks.AC_CHECK_SIZEOF("size_t", define = "SIZEOF_SIZE_T"),
        checks.AC_TRY_COMPILE(
            name = "libffi_cv_long_double_bigger",
            code = """
typedef char libffi_long_double_check[
    sizeof(long double) != sizeof(double) ? 1 : -1
];

int main(void) {
    return 0;
}
""",
        ),
        checks.AC_DEFINE(
            "HAVE_LONG_DOUBLE",
            condition = "libffi_cv_long_double_bigger",
            if_false = None,
            if_true = 1,
        ),
        checks.AC_SUBST(
            "HAVE_LONG_DOUBLE",
            condition = "libffi_cv_long_double_bigger",
            if_false = 0,
            if_true = 1,
        ),
    ]

def _x86_checks():
    return [
        checks.AC_TRY_COMPILE(
            name = "libffi_cv_as_x86_pcrel",
            code = utils.AC_LANG_PROGRAM(
                [
                    "#if defined(__x86_64__) || defined(_M_X64)",
                    '__asm__ (".text; libffi_pcrel: nop; .data; .long libffi_pcrel-.; .text");',
                    "#else",
                    "# error x86-64 assembler required",
                    "#endif",
                ],
                "",
            ),
        ),
        checks.AC_DEFINE(
            "HAVE_AS_X86_PCREL",
            condition = "libffi_cv_as_x86_pcrel",
            if_false = None,
            if_true = 1,
        ),
    ]

def _x86_64_unwind_checks():
    return [
        checks.AC_TRY_LINK(
            name = "libffi_cv_as_x86_64_unwind_section_type",
            code = utils.AC_LANG_PROGRAM(
                [
                    "#if defined(__x86_64__) && !defined(_WIN32)",
                    '__asm__ (".text\\n\\t.globl libffi_unwind\\nlibffi_unwind:\\n\\tnop\\n\\t.section .eh_frame,\\\"a\\\",@unwind\\n\\t.long 0\\n\\t.text");',
                    "#else",
                    "# error ELF or Mach-O x86-64 assembler required",
                    "#endif",
                ],
                "",
            ),
            copts = ["-Wa,--fatal-warnings"],
        ),
        checks.AC_DEFINE(
            "HAVE_AS_X86_64_UNWIND_SECTION_TYPE",
            condition = "libffi_cv_as_x86_64_unwind_section_type",
            if_false = None,
            if_true = 1,
        ),
    ]

def _target_policy(target, trampoline_table, defines = []):
    return [
        checks.AC_SUBST("FFI_EXEC_TRAMPOLINE_TABLE", trampoline_table),
        checks.AC_SUBST("TARGET", target),
    ] + [checks.AC_DEFINE(define, 1) for define in defines]

def libffi_config(name):
    """Generates fficonfig.h and ffi.h for the selected target toolchain."""

    target_policy = select({
        ":darwin_arm64": _target_policy(
            "AARCH64",
            1,
            defines = [
                "FFI_EXEC_TRAMPOLINE_TABLE",
                "SYMBOL_UNDERSCORE",
            ],
        ),
        ":darwin_x86_64": _target_policy(
            "X86_64",
            0,
            defines = [
                "FFI_MMAP_EXEC_WRIT",
                "SYMBOL_UNDERSCORE",
            ],
        ),
        ":linux_arm64": _target_policy(
            "AARCH64",
            0,
            defines = [
                "FFI_EXEC_STATIC_TRAMP",
            ],
        ),
        ":linux_x86_64": _target_policy(
            "X86_64",
            0,
            defines = [
                "FFI_EXEC_STATIC_TRAMP",
            ],
        ),
        ":windows_arm64": _target_policy("ARM_WIN64", 0),
        ":windows_x86_64": _target_policy("X86_WIN64", 0),
        "//conditions:default": [],
    })

    autoconf(
        name = name + "_checks",
        checks = _PACKAGE_CHECKS + _compiler_checks() + _hidden_visibility_checks() + _long_double_checks() + _standard_header_checks() + _x86_checks() + _x86_64_unwind_checks() + macros.AC_CHECK_HEADERS(_HEADERS) + macros.AC_CHECK_FUNCS([
            "memcpy",
            "memfd_create",
        ]) + target_policy,
        tags = ["manual"],
    )

    autoconf_hdr(
        name = name + "_fficonfig_h",
        out = "fficonfig.h",
        deps = [":" + name + "_checks"],
        tags = ["manual"],
        template = "fficonfig.h.in",
    )

    autoconf_hdr(
        name = name + "_ffi_h",
        out = "ffi.h",
        deps = [":" + name + "_checks"],
        mode = "all",
        tags = ["manual"],
        template = "include/ffi.h.in",
    )
