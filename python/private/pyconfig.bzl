"""Toolchain checks used to generate CPython's pyconfig.h."""

load("@rules_cc_autoconf//autoconf:checks.bzl", "utils")
load("@rules_cc_autoconf//autoconf:defs.bzl", "autoconf", "autoconf_hdr", "checks", "macros")

_SYSTEM_EXTENSION_DEFINES = [
    "_NETBSD_SOURCE",
    "_DARWIN_C_SOURCE",
    "_FILE_OFFSET_BITS",
    "_GNU_SOURCE",
    "_LARGEFILE_SOURCE",
    "_POSIX_C_SOURCE",
    "_REENTRANT",
    "_XOPEN_SOURCE",
    "_XOPEN_SOURCE_EXTENDED",
    "__BSD_VISIBLE",
]

_HEADERS = [
    "alloca.h",
    "arpa/inet.h",
    "asm/types.h",
    "bluetooth.h",
    "conio.h",
    "direct.h",
    "dlfcn.h",
    "dirent.h",
    "endian.h",
    "errno.h",
    "fcntl.h",
    "grp.h",
    "inttypes.h",
    "io.h",
    "langinfo.h",
    "libintl.h",
    "linux/random.h",
    "linux/auxvec.h",
    "linux/fs.h",
    "linux/limits.h",
    "linux/memfd.h",
    "linux/soundcard.h",
    "linux/tipc.h",
    "linux/wait.h",
    "libutil.h",
    "net/ethernet.h",
    "netdb.h",
    "netinet/in.h",
    "netinet/tcp.h",
    "netpacket/packet.h",
    "poll.h",
    "process.h",
    "pthread.h",
    "pty.h",
    "sched.h",
    "setjmp.h",
    "shadow.h",
    "signal.h",
    "spawn.h",
    "stdint.h",
    "stdio.h",
    "stdlib.h",
    "stropts.h",
    "string.h",
    "strings.h",
    "sys/audioio.h",
    "sys/auxv.h",
    "sys/bsdtty.h",
    "sys/devpoll.h",
    "sys/endian.h",
    "sys/epoll.h",
    "sys/event.h",
    "sys/eventfd.h",
    "sys/file.h",
    "sys/ioctl.h",
    "sys/kern_control.h",
    "sys/loadavg.h",
    "sys/lock.h",
    "sys/memfd.h",
    "sys/mkdev.h",
    "sys/mman.h",
    "sys/modem.h",
    "sys/param.h",
    "sys/pidfd.h",
    "sys/poll.h",
    "sys/random.h",
    "sys/resource.h",
    "sys/select.h",
    "sys/sendfile.h",
    "sys/socket.h",
    "sys/soundcard.h",
    "sys/stat.h",
    "sys/statvfs.h",
    "sys/sys_domain.h",
    "sys/syscall.h",
    "sys/sysmacros.h",
    "sys/termio.h",
    "sys/time.h",
    "sys/times.h",
    "sys/types.h",
    "sys/uio.h",
    "sys/un.h",
    "sys/utsname.h",
    "sys/wait.h",
    "sys/xattr.h",
    "sysexits.h",
    "syslog.h",
    "termios.h",
    "time.h",
    "unistd.h",
    "util.h",
    "utime.h",
    "utmp.h",
    "wchar.h",
]

_HEADERS_3_12 = [
    "crypt.h",
    "ieeefp.h",
]

_HEADERS_3_13 = [
    "sys/timerfd.h",
]

_FUNCTIONS = [
    "_getpty",
    "accept",
    "accept4",
    "alarm",
    "bind",
    "bind_textdomain_codeset",
    "chmod",
    "chown",
    "chroot",
    "clock_getres",
    "clock_gettime",
    "clock_nanosleep",
    "clock_settime",
    "clock",
    "closefrom",
    "close_range",
    "confstr",
    "connect",
    "copy_file_range",
    "ctermid",
    "dup",
    "dup2",
    "dup3",
    "endpwent",
    "execv",
    "explicit_bzero",
    "explicit_memset",
    "faccessat",
    "fchdir",
    "fchmod",
    "fchmodat",
    "fchown",
    "fchownat",
    "fdopendir",
    "fdwalk",
    "fexecve",
    "flock",
    "fork",
    "fork1",
    "fpathconf",
    "fstatat",
    "fstatvfs",
    "fseeko",
    "fsync",
    "ftello",
    "ftime",
    "ftruncate",
    "futimens",
    "futimes",
    "futimesat",
    "gai_strerror",
    "getaddrinfo",
    "getc_unlocked",
    "getegid",
    "getentropy",
    "geteuid",
    "getgid",
    "getgrgid",
    "getgrgid_r",
    "getgrnam_r",
    "getgrouplist",
    "getgroups",
    "gethostbyaddr",
    "gethostbyname",
    "gethostbyname_r",
    "gethostname",
    "getitimer",
    "getloadavg",
    "getlogin",
    "getnameinfo",
    "getpagesize",
    "getpeername",
    "getpgid",
    "getpgrp",
    "getpid",
    "getppid",
    "getpriority",
    "getpwent",
    "getpwnam_r",
    "getpwuid",
    "getpwuid_r",
    "getprotobyname",
    "getresgid",
    "getresuid",
    "getrusage",
    "getsid",
    "getsockname",
    "getservbyname",
    "getservbyport",
    "getspent",
    "getspnam",
    "getuid",
    "getwd",
    "grantpt",
    "hstrerror",
    "if_nameindex",
    "initgroups",
    "inet_aton",
    "inet_ntoa",
    "inet_ntop",
    "inet_pton",
    "kill",
    "killpg",
    "lchown",
    "link",
    "linkat",
    "listen",
    "lockf",
    "lstat",
    "lutimes",
    "madvise",
    "mbrtowc",
    "memrchr",
    "mkdirat",
    "mkfifo",
    "mkfifoat",
    "mknod",
    "mknodat",
    "mktime",
    "mmap",
    "mremap",
    "nanosleep",
    "nice",
    "openat",
    "opendir",
    "pathconf",
    "pause",
    "pipe",
    "pipe2",
    "plock",
    "poll",
    "posix_fadvise",
    "posix_fallocate",
    "posix_openpt",
    "posix_spawn",
    "posix_spawnp",
    "pread",
    "preadv",
    "preadv2",
    "pthread_condattr_setclock",
    "pthread_getcpuclockid",
    "pthread_kill",
    "pthread_init",
    "pthread_sigmask",
    "ptsname",
    "ptsname_r",
    "pwrite",
    "pwritev",
    "pwritev2",
    "readlink",
    "readlinkat",
    "readv",
    "realpath",
    "recvfrom",
    "renameat",
    "rtpSpawn",
    "sched_get_priority_max",
    "sched_rr_get_interval",
    "sched_setaffinity",
    "sched_setparam",
    "sched_setscheduler",
    "sem_clockwait",
    "sem_getvalue",
    "sem_open",
    "sem_timedwait",
    "sem_unlink",
    "sendfile",
    "sendto",
    "setegid",
    "seteuid",
    "setgid",
    "setgroups",
    "sethostname",
    "setitimer",
    "setlocale",
    "setns",
    "setpgid",
    "setpgrp",
    "setpriority",
    "setpwent",
    "setregid",
    "setresgid",
    "setresuid",
    "setreuid",
    "setsid",
    "setsockopt",
    "setuid",
    "setvbuf",
    "shutdown",
    "sigaction",
    "sigaltstack",
    "sigfillset",
    "siginterrupt",
    "sigpending",
    "sigrelse",
    "sigtimedwait",
    "sigwait",
    "sigwaitinfo",
    "socket",
    "socketpair",
    "snprintf",
    "splice",
    "statvfs",
    "strftime",
    "strlcpy",
    "strsignal",
    "symlink",
    "symlinkat",
    "sync",
    "sysconf",
    "system",
    "tcgetpgrp",
    "tcsetpgrp",
    "tempnam",
    "timegm",
    "times",
    "tmpfile",
    "tmpnam",
    "tmpnam_r",
    "truncate",
    "ttyname_r",
    "tzset",
    "umask",
    "uname",
    "unshare",
    "unlinkat",
    "unlockpt",
    "utimensat",
    "utimes",
    "vfork",
    "wait",
    "wait3",
    "wait4",
    "waitid",
    "waitpid",
    "wcscoll",
    "wcsftime",
    "wmemcmp",
    "wcsxfrm",
    "writev",
]

_FUNCTIONS_3_13 = [
    "getgrent",
    "getlogin_r",
    "posix_spawn_file_actions_addclosefrom_np",
    "process_vm_readv",
    "pthread_cond_timedwait_relative_np",
]

_PACKAGE_DEFINES = [
    "PACKAGE_BUGREPORT",
    "PACKAGE_NAME",
    "PACKAGE_STRING",
    "PACKAGE_TARNAME",
    "PACKAGE_URL",
    "PACKAGE_VERSION",
]

def _common_fixed_defines():
    return [
        checks.AC_DEFINE("DOUBLE_IS_LITTLE_ENDIAN_IEEE754", 1),
        checks.AC_DEFINE("ENABLE_IPV6", 1),
        checks.AC_DEFINE("HAVE_PROTOTYPES", 1),
        checks.AC_DEFINE("PY_COERCE_C_LOCALE", 1),
        checks.AC_DEFINE("PY_BUILTIN_HASHLIB_HASHES", '"md5,sha1,sha2,sha3,blake2"'),
        checks.AC_DEFINE("RETSIGTYPE", "void"),
        checks.AC_DEFINE("STDC_HEADERS", 1),
        checks.AC_DEFINE("SYS_SELECT_WITH_SYS_TIME", 1),
        checks.AC_DEFINE("WITH_DOC_STRINGS", 1),
        checks.AC_DEFINE("WITH_DECIMAL_CONTEXTVAR", 1),
        checks.AC_DEFINE("WITH_FREELISTS", 1),
        checks.AC_DEFINE("WITH_PYMALLOC", 1),
        checks.AC_DEFINE("_DARWIN_C_SOURCE", 1),
        checks.AC_DEFINE("_FILE_OFFSET_BITS", 64),
        checks.AC_DEFINE("_LARGEFILE_SOURCE", 1),
        checks.AC_DEFINE("_NETBSD_SOURCE", 1),
        checks.AC_DEFINE("_PYTHONFRAMEWORK", '\"\"'),
        checks.AC_DEFINE("_REENTRANT", 1),
        checks.AC_DEFINE("__BSD_VISIBLE", 1),
    ] + [checks.AC_FAIL(define) for define in _PACKAGE_DEFINES]

def _dynamic_loading_checks(linkopts):
    return [
        checks.AC_TRY_LINK(
            name = "ac_cv_func_dlopen",
            define = "HAVE_DLOPEN",
            code = utils.AC_LANG_PROGRAM(
                ["#include <dlfcn.h>"],
                "return dlopen(0, RTLD_LAZY) == 0;",
            ),
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
            if_false = None,
            linkopts = linkopts,
        ),
        checks.AC_DEFINE(
            "HAVE_DYNAMIC_LOADING",
            condition = "HAVE_DLOPEN",
            if_true = 1,
            if_false = None,
        ),
    ]

def _posix_shmem_checks(linkopts):
    return [
        checks.AC_TRY_LINK(
            name = "ac_cv_func_shm_open",
            define = "HAVE_SHM_OPEN",
            code = utils.AC_LANG_PROGRAM(
                ["#include <sys/mman.h>"],
                "return shm_open(\"/python-autoconf\", 0, 0);",
            ),
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
            if_false = None,
            linkopts = linkopts,
        ),
        checks.AC_TRY_LINK(
            name = "ac_cv_func_shm_unlink",
            define = "HAVE_SHM_UNLINK",
            code = utils.AC_LANG_PROGRAM(
                ["#include <sys/mman.h>"],
                "return shm_unlink(\"/python-autoconf\");",
            ),
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
            if_false = None,
            linkopts = linkopts,
        ),
    ]

def _epoll_checks():
    return [
        checks.AC_TRY_LINK(
            name = "ac_cv_func_epoll_create",
            define = "HAVE_EPOLL",
            code = utils.AC_LANG_PROGRAM(
                ["#include <sys/epoll.h>"],
                "return epoll_create(1) < 0;",
            ),
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
            if_false = None,
            requires = ["HAVE_SYS_EPOLL_H"],
        ),
        checks.AC_TRY_LINK(
            name = "ac_cv_func_epoll_create1",
            define = "HAVE_EPOLL_CREATE1",
            code = utils.AC_LANG_PROGRAM(
                ["#include <sys/epoll.h>"],
                "return epoll_create1(0) < 0;",
            ),
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
            if_false = None,
            requires = ["HAVE_SYS_EPOLL_H"],
        ),
    ]

def _header_check(header, define, includes = [], compile_defines = [], requires = []):
    return checks.AC_CHECK_HEADER(
        header,
        define = define,
        includes = includes,
        compile_defines = compile_defines,
        requires = requires,
    )

def _dependent_header_checks(version):
    socket_prerequisites = [
        "#include <stdio.h>",
        "#include <stdlib.h>",
        "#include <stddef.h>",
        "#if HAVE_SYS_SOCKET_H\n#include <sys/socket.h>\n#endif",
    ]
    linux_socket_prerequisites = [
        "#if HAVE_ASM_TYPES_H\n#include <asm/types.h>\n#endif",
        "#if HAVE_SYS_SOCKET_H\n#include <sys/socket.h>\n#endif",
    ]
    checks_list = [
        _header_check(
            "bluetooth/bluetooth.h",
            "HAVE_BLUETOOTH_BLUETOOTH_H",
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
        ),
        _header_check(
            "net/if.h",
            "HAVE_NET_IF_H",
            includes = socket_prerequisites,
            compile_defines = _SYSTEM_EXTENSION_DEFINES + ["HAVE_SYS_SOCKET_H"],
        ),
        _header_check(
            "linux/netlink.h",
            "HAVE_LINUX_NETLINK_H",
            includes = linux_socket_prerequisites,
            compile_defines = _SYSTEM_EXTENSION_DEFINES + ["HAVE_ASM_TYPES_H", "HAVE_SYS_SOCKET_H"],
        ),
        _header_check(
            "linux/qrtr.h",
            "HAVE_LINUX_QRTR_H",
            includes = linux_socket_prerequisites,
            compile_defines = _SYSTEM_EXTENSION_DEFINES + ["HAVE_ASM_TYPES_H", "HAVE_SYS_SOCKET_H"],
        ),
        _header_check(
            "linux/vm_sockets.h",
            "HAVE_LINUX_VM_SOCKETS_H",
            includes = socket_prerequisites,
            compile_defines = _SYSTEM_EXTENSION_DEFINES + ["HAVE_SYS_SOCKET_H"],
        ),
    ]
    for header, define in [
        ("linux/can.h", "HAVE_LINUX_CAN_H"),
        ("linux/can/bcm.h", "HAVE_LINUX_CAN_BCM_H"),
        ("linux/can/j1939.h", "HAVE_LINUX_CAN_J1939_H"),
        ("linux/can/raw.h", "HAVE_LINUX_CAN_RAW_H"),
        ("netcan/can.h", "HAVE_NETCAN_CAN_H"),
    ]:
        checks_list.append(_header_check(
            header,
            define,
            includes = socket_prerequisites,
            compile_defines = _SYSTEM_EXTENSION_DEFINES + ["HAVE_SYS_SOCKET_H"],
        ))
    if version in ["3.13", "3.14"]:
        checks_list.append(_header_check(
            "netlink/netlink.h",
            "HAVE_NETLINK_NETLINK_H",
            includes = linux_socket_prerequisites,
            compile_defines = _SYSTEM_EXTENSION_DEFINES + ["HAVE_ASM_TYPES_H", "HAVE_SYS_SOCKET_H"],
        ))
    return checks_list

def _pty_checks(header, login_header, linkopts):
    return [
        checks.AC_TRY_LINK(
            name = "ac_cv_func_openpty",
            define = "HAVE_OPENPTY",
            code = utils.AC_LANG_PROGRAM(
                ["#include <{}>".format(header)],
                [
                    "int master_fd;",
                    "int slave_fd;",
                    "return openpty(&master_fd, &slave_fd, 0, 0, 0);",
                ],
            ),
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
            if_false = None,
            linkopts = linkopts,
        ),
        checks.AC_TRY_LINK(
            name = "ac_cv_func_forkpty",
            define = "HAVE_FORKPTY",
            code = utils.AC_LANG_PROGRAM(
                ["#include <{}>".format(header)],
                [
                    "int master_fd;",
                    "return forkpty(&master_fd, 0, 0, 0) < 0;",
                ],
            ),
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
            if_false = None,
            linkopts = linkopts,
        ),
        checks.AC_TRY_LINK(
            name = "ac_cv_func_login_tty",
            define = "HAVE_LOGIN_TTY",
            code = utils.AC_LANG_PROGRAM(
                ["#include <{}>".format(login_header)],
                "return login_tty(-1);",
            ),
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
            if_false = None,
            linkopts = linkopts,
        ),
    ]

def _declared_function_check(function, define, includes, requires = [], linkopts = []):
    return checks.AC_TRY_LINK(
        name = "ac_cv_func_{}".format(function),
        define = define,
        code = utils.AC_LANG_PROGRAM(
            includes,
            "return &{} == 0;".format(function),
        ),
        compile_defines = _SYSTEM_EXTENSION_DEFINES,
        if_false = None,
        linkopts = linkopts,
        requires = requires,
    )

def _darwin_filesystem_checks():
    return [
        _declared_function_check(
            "chflags",
            "HAVE_CHFLAGS",
            ["#include <sys/stat.h>"],
        ),
        _declared_function_check(
            "lchflags",
            "HAVE_LCHFLAGS",
            ["#include <sys/stat.h>"],
        ),
        _declared_function_check(
            "lchmod",
            "HAVE_LCHMOD",
            ["#include <sys/stat.h>"],
        ),
    ]

def _darwin_library_checks():
    return [
        checks.AC_FAIL("HAVE_HTOLE64"),
        checks.AC_FAIL("HAVE_LIBDL"),
    ]

def _linux_filesystem_checks():
    return [
        checks.AC_FAIL("HAVE_CHFLAGS"),
        checks.AC_FAIL("HAVE_LCHFLAGS"),
        checks.AC_FAIL("HAVE_LCHMOD"),
    ]

def _linux_library_checks():
    return [
        checks.AC_TRY_COMPILE(
            name = "ac_cv_func_le64toh",
            define = "HAVE_HTOLE64",
            code = utils.AC_LANG_PROGRAM(
                ["#include <endian.h>"],
                "return le64toh(1) != 1;",
            ),
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
            if_false = None,
        ),
        checks.AC_DEFINE(
            "HAVE_LIBDL",
            condition = "HAVE_DLOPEN",
            if_true = 1,
            if_false = None,
        ),
    ]

def _special_function_checks(version):
    checks_list = [
        _declared_function_check(
            "ctermid_r",
            "HAVE_CTERMID_R",
            ["#include <stdio.h>"],
        ),
        _declared_function_check(
            "fdatasync",
            "HAVE_FDATASYNC",
            ["#include <unistd.h>"],
        ),
        _declared_function_check(
            "kqueue",
            "HAVE_KQUEUE",
            ["#include <sys/types.h>", "#include <sys/event.h>"],
            requires = ["HAVE_SYS_EVENT_H"],
        ),
        _declared_function_check(
            "_dyld_shared_cache_contains_path",
            "HAVE_DYLD_SHARED_CACHE_CONTAINS_PATH",
            ["#include <mach-o/dyld.h>"],
        ),
        _declared_function_check(
            "prlimit",
            "HAVE_PRLIMIT",
            ["#include <sys/time.h>", "#include <sys/resource.h>"],
        ),
        _declared_function_check(
            "memfd_create",
            "HAVE_MEMFD_CREATE",
            ["#include <sys/mman.h>"],
            requires = ["HAVE_SYS_MMAN_H"],
        ),
        _declared_function_check(
            "eventfd",
            "HAVE_EVENTFD",
            ["#include <sys/eventfd.h>"],
            requires = ["HAVE_SYS_EVENTFD_H"],
        ),
        _declared_function_check(
            "getrandom",
            "HAVE_GETRANDOM",
            ["#include <sys/random.h>"],
            requires = ["HAVE_SYS_RANDOM_H"],
        ),
    ]
    if version in ["3.13", "3.14"]:
        checks_list.append(_declared_function_check(
            "timerfd_create",
            "HAVE_TIMERFD_CREATE",
            ["#include <sys/timerfd.h>"],
            requires = ["HAVE_SYS_TIMERFD_H"],
        ))
    return checks_list

def _declaration_checks(version):
    checks_list = macros.AC_CHECK_DECLS(
        [
            "RTLD_LAZY",
            "RTLD_NOW",
            "RTLD_GLOBAL",
            "RTLD_LOCAL",
            "RTLD_NODELETE",
            "RTLD_NOLOAD",
            "RTLD_DEEPBIND",
            "RTLD_MEMBER",
        ],
        includes = ["#include <dlfcn.h>"],
        compile_defines = _SYSTEM_EXTENSION_DEFINES,
        if_true = 1,
        if_false = 0,
    )
    checks_list += macros.AC_CHECK_DECLS(
        ["tzname"],
        includes = ["#include <time.h>"],
        compile_defines = _SYSTEM_EXTENSION_DEFINES,
        if_true = 1,
        if_false = 0,
    )
    if version in ["3.13", "3.14"]:
        checks_list += macros.AC_CHECK_DECLS(
            ["UT_NAMESIZE"],
            includes = ["#include <utmp.h>"],
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
            if_true = 1,
            if_false = 0,
        )
        checks_list += [
            checks.AC_TRY_COMPILE(
                name = "ac_cv_have_decl_MAXLOGNAME",
                define = "HAVE_MAXLOGNAME",
                code = utils.AC_LANG_PROGRAM(
                    ["#include <sys/param.h>"],
                    "int value = MAXLOGNAME; (void)value;",
                ),
                compile_defines = _SYSTEM_EXTENSION_DEFINES,
                if_false = None,
            ),
            checks.AC_DEFINE(
                "HAVE_UT_NAMESIZE",
                condition = "HAVE_DECL_UT_NAMESIZE",
                if_true = 1,
                if_false = None,
            ),
        ]
    return checks_list

def _compiler_checks():
    return [
        checks.AC_TRY_COMPILE(
            name = "ac_cv_computed_gotos",
            define = "HAVE_COMPUTED_GOTOS",
            code = """
int main(void) {
    static void *targets[] = {&&target};
    goto *targets[0];
target:
    return 0;
}
""",
            if_false = None,
        ),
        checks.AC_TRY_LINK(
            name = "ac_cv_std_atomic",
            define = "HAVE_STD_ATOMIC",
            code = utils.AC_LANG_PROGRAM(
                ["#include <stdatomic.h>", "#include <stdint.h>"],
                [
                    "atomic_int value = 0;",
                    "atomic_uintptr_t pointer = 0;",
                    "atomic_store(&value, 1);",
                    "atomic_store(&pointer, (uintptr_t)&value);",
                    "return atomic_load(&value) != 1;",
                ],
            ),
            if_false = None,
        ),
        checks.AC_TRY_LINK(
            name = "ac_cv_builtin_atomic",
            define = "HAVE_BUILTIN_ATOMIC",
            code = utils.AC_LANG_PROGRAM(
                [],
                [
                    "int value = 0;",
                    "__atomic_store_n(&value, 1, __ATOMIC_SEQ_CST);",
                    "return __atomic_load_n(&value, __ATOMIC_SEQ_CST) != 1;",
                ],
            ),
            if_false = None,
        ),
        checks.AC_TRY_COMPILE(
            name = "ac_cv_gethostbyname_r_6_arg",
            define = "HAVE_GETHOSTBYNAME_R_6_ARG",
            code = utils.AC_LANG_PROGRAM(
                [
                    "#include <netdb.h>",
                    "#include <stddef.h>",
                ],
                [
                    "struct hostent result_buf;",
                    "struct hostent *result;",
                    "char buffer[1024];",
                    "int error;",
                    "return gethostbyname_r(\"localhost\", &result_buf, buffer, sizeof(buffer), &result, &error);",
                ],
            ),
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
            requires = ["HAVE_GETHOSTBYNAME_R"],
        ),
    ]

def _required_math_checks():
    checks_list = []
    for function in [
        "acosh",
        "asinh",
        "atanh",
        "erf",
        "erfc",
        "expm1",
        "log1p",
        "log2",
    ]:
        checks_list.append(_declared_function_check(
            function,
            "HAVE_{}".format(function.upper()),
            ["#include <math.h>"],
            linkopts = ["-lm"],
        ))
    return checks_list

def _capability_checks(version):
    checks_list = [
        checks.AC_TRY_COMPILE(
            name = "ac_cv_long_double",
            define = "HAVE_LONG_DOUBLE",
            code = utils.AC_LANG_PROGRAM([], "long double value = 0.0L; (void)value;"),
            if_false = None,
        ),
        checks.AC_CHECK_DECL(
            "dirfd",
            define = "HAVE_DIRFD",
            includes = ["#include <sys/types.h>", "#include <dirent.h>"],
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
        ),
        checks.AC_TRY_COMPILE(
            name = "ac_cv_device_macros",
            define = "HAVE_DEVICE_MACROS",
            code = utils.AC_LANG_PROGRAM(
                [
                    "#include <sys/types.h>",
                    "#if HAVE_SYS_SYSMACROS_H\n#include <sys/sysmacros.h>\n#endif",
                ],
                [
                    "dev_t device = makedev(1, 2);",
                    "return major(device) != 1 || minor(device) != 2;",
                ],
            ),
            compile_defines = _SYSTEM_EXTENSION_DEFINES + ["HAVE_SYS_SYSMACROS_H"],
            if_false = None,
        ),
        checks.AC_TRY_COMPILE(
            name = "ac_cv_major_in_sysmacros",
            define = "MAJOR_IN_SYSMACROS",
            code = utils.AC_LANG_PROGRAM(
                ["#include <sys/types.h>", "#include <sys/sysmacros.h>"],
                "return major(makedev(1, 2)) != 1;",
            ),
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
            if_false = None,
            requires = ["HAVE_SYS_SYSMACROS_H"],
        ),
        checks.AC_TRY_COMPILE(
            name = "ac_cv_major_in_mkdev",
            define = "MAJOR_IN_MKDEV",
            code = utils.AC_LANG_PROGRAM(
                ["#include <sys/types.h>", "#include <sys/mkdev.h>"],
                "return major(makedev(1, 2)) != 1;",
            ),
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
            if_false = None,
            requires = ["HAVE_SYS_MKDEV_H"],
        ),
        checks.AC_TRY_LINK(
            name = "ac_cv_func_makedev",
            define = "HAVE_MAKEDEV",
            code = utils.AC_LANG_PROGRAM(
                [
                    "#include <sys/types.h>",
                    "#if MAJOR_IN_MKDEV\n#include <sys/mkdev.h>\n#endif",
                    "#if MAJOR_IN_SYSMACROS\n#include <sys/sysmacros.h>\n#endif",
                ],
                "return major(makedev(1, 2)) != 1;",
            ),
            compile_defines = _SYSTEM_EXTENSION_DEFINES + ["MAJOR_IN_MKDEV", "MAJOR_IN_SYSMACROS"],
            if_false = None,
        ),
        checks.AC_TRY_COMPILE(
            name = "ac_cv_struct_sockaddr_alg",
            define = "HAVE_SOCKADDR_ALG",
            code = utils.AC_LANG_PROGRAM(
                ["#include <sys/types.h>", "#include <sys/socket.h>", "#include <linux/if_alg.h>"],
                "struct sockaddr_alg address; (void)address;",
            ),
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
            if_false = None,
        ),
        checks.AC_TRY_COMPILE(
            name = "ac_cv_pthread_key_t_is_compatible_with_int",
            define = "PTHREAD_KEY_T_IS_COMPATIBLE_WITH_INT",
            code = utils.AC_LANG_PROGRAM(
                ["#include <pthread.h>"],
                [
                    "typedef int same_size[sizeof(pthread_key_t) == sizeof(int) ? 1 : -1];",
                    "pthread_key_t key = 0;",
                    "same_size value;",
                    "(void)value;",
                    "return key * 1;",
                ],
            ),
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
            if_false = None,
        ),
        checks.AC_TRY_COMPILE(
            name = "ac_cv_header_time_altzone",
            define = "HAVE_ALTZONE",
            code = utils.AC_LANG_PROGRAM(["#include <time.h>"], "return altzone != 0;"),
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
            if_false = None,
        ),
        checks.AC_DEFINE(
            "HAVE_TM_ZONE",
            condition = "HAVE_STRUCT_TM_TM_ZONE",
            if_true = 1,
            if_false = None,
        ),
        checks.AC_DEFINE(
            "HAVE_TZNAME",
            condition = "HAVE_DECL_TZNAME",
            if_true = 1,
            if_false = None,
        ),
        checks.AC_TRY_COMPILE(
            name = "ac_cv_can_raw_fd_frames",
            define = "HAVE_LINUX_CAN_RAW_FD_FRAMES",
            code = utils.AC_LANG_PROGRAM(["#include <linux/can/raw.h>"], "int value = CAN_RAW_FD_FRAMES; (void)value;"),
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
            if_false = None,
            requires = ["HAVE_LINUX_CAN_RAW_H"],
        ),
        checks.AC_TRY_COMPILE(
            name = "ac_cv_can_raw_join_filters",
            define = "HAVE_LINUX_CAN_RAW_JOIN_FILTERS",
            code = utils.AC_LANG_PROGRAM(["#include <linux/can/raw.h>"], "int value = CAN_RAW_JOIN_FILTERS; (void)value;"),
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
            if_false = None,
            requires = ["HAVE_LINUX_CAN_RAW_H"],
        ),
        checks.AC_TRY_LINK(
            name = "ac_cv_getrandom_syscall",
            define = "HAVE_GETRANDOM_SYSCALL",
            code = utils.AC_LANG_PROGRAM(
                [
                    "#include <stddef.h>",
                    "#include <unistd.h>",
                    "#include <sys/syscall.h>",
                    "#include <linux/random.h>",
                ],
                [
                    "char buffer[1];",
                    "(void)syscall(SYS_getrandom, buffer, sizeof(buffer), GRND_NONBLOCK);",
                ],
            ),
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
            if_false = None,
            requires = ["HAVE_SYS_SYSCALL_H", "HAVE_LINUX_RANDOM_H"],
        ),
    ]
    if version in ["3.13", "3.14"]:
        checks_list.append(checks.AC_DEFINE(
            "HAVE___UINT128_T",
            condition = "HAVE_GCC_UINT128_T",
            if_true = 1,
            if_false = None,
        ))
    return checks_list

def _member_checks():
    return [
        checks.AC_TRY_LINK(
            name = "ac_cv_dirent_d_type",
            define = "HAVE_DIRENT_D_TYPE",
            code = utils.AC_LANG_PROGRAM(
                ["#include <dirent.h>"],
                "struct dirent entry; return entry.d_type == DT_UNKNOWN;",
            ),
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
            if_false = None,
        ),
        checks.AC_CHECK_MEMBER(
            "struct passwd.pw_gecos",
            define = "HAVE_STRUCT_PASSWD_PW_GECOS",
            includes = ["#include <pwd.h>"],
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
        ),
        checks.AC_CHECK_MEMBER(
            "struct passwd.pw_passwd",
            define = "HAVE_STRUCT_PASSWD_PW_PASSWD",
            includes = ["#include <pwd.h>"],
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
        ),
        checks.AC_CHECK_MEMBER(
            "struct stat.st_blksize",
            define = "HAVE_STRUCT_STAT_ST_BLKSIZE",
            includes = ["#include <sys/stat.h>"],
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
        ),
        checks.AC_CHECK_MEMBER(
            "struct stat.st_blocks",
            define = "HAVE_STRUCT_STAT_ST_BLOCKS",
            includes = ["#include <sys/stat.h>"],
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
        ),
        checks.AC_CHECK_MEMBER(
            "struct stat.st_flags",
            define = "HAVE_STRUCT_STAT_ST_FLAGS",
            includes = ["#include <sys/stat.h>"],
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
        ),
        checks.AC_CHECK_MEMBER(
            "struct stat.st_gen",
            define = "HAVE_STRUCT_STAT_ST_GEN",
            includes = ["#include <sys/stat.h>"],
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
        ),
        checks.AC_CHECK_MEMBER(
            "struct stat.st_rdev",
            define = "HAVE_STRUCT_STAT_ST_RDEV",
            includes = ["#include <sys/stat.h>"],
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
        ),
        checks.AC_CHECK_MEMBER(
            "struct stat.st_birthtime",
            define = "HAVE_STRUCT_STAT_ST_BIRTHTIME",
            includes = ["#include <sys/stat.h>"],
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
        ),
        checks.AC_CHECK_MEMBER(
            "struct stat.st_mtim.tv_nsec",
            define = "HAVE_STAT_TV_NSEC",
            includes = ["#include <sys/stat.h>"],
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
        ),
        checks.AC_CHECK_MEMBER(
            "struct stat.st_mtimespec.tv_nsec",
            define = "HAVE_STAT_TV_NSEC2",
            includes = ["#include <sys/stat.h>"],
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
        ),
        checks.AC_CHECK_MEMBER(
            "struct tm.tm_zone",
            define = "HAVE_STRUCT_TM_TM_ZONE",
            includes = ["#include <time.h>"],
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
        ),
        checks.AC_CHECK_MEMBER(
            "siginfo_t.si_band",
            define = "HAVE_SIGINFO_T_SI_BAND",
            includes = ["#include <signal.h>"],
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
        ),
        checks.AC_CHECK_MEMBER(
            "struct sockaddr.sa_len",
            define = "HAVE_SOCKADDR_SA_LEN",
            includes = ["#include <sys/socket.h>"],
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
        ),
    ]

def _darwin_platform_checks(version, support_tier):
    return _common_fixed_defines() + [
        checks.AC_FAIL("_GNU_SOURCE"),
        checks.AC_FAIL("_POSIX_C_SOURCE"),
        checks.AC_FAIL("_XOPEN_SOURCE"),
        checks.AC_FAIL("_XOPEN_SOURCE_EXTENDED"),
        checks.AC_DEFINE("HAVE_BROKEN_SEM_GETVALUE", 1),
        checks.AC_DEFINE("HAVE_DEV_PTMX", 1),
        checks.AC_DEFINE("HAVE_WORKING_TZSET", 1),
        checks.AC_DEFINE("PTHREAD_SYSTEM_SCHED_SUPPORTED", 1),
        checks.AC_DEFINE("PY_SUPPORT_TIER", support_tier),
        checks.AC_DEFINE("THREAD_STACK_SIZE", "0x1000000"),
        checks.AC_DEFINE("WITH_DYLD", 1),
    ] + ([checks.AC_DEFINE("HAVE_STDARG_PROTOTYPES", 1)] if version == "3.11" else []) + _dynamic_loading_checks([]) + _posix_shmem_checks([]) + _pty_checks("util.h", "util.h", []) + _darwin_filesystem_checks() + _darwin_library_checks()

def _linux_platform_checks(version):
    return _common_fixed_defines() + [
        checks.AC_DEFINE("_GNU_SOURCE", 1),
        checks.AC_DEFINE("HAVE_BZLIB_H", 1),
        checks.AC_DEFINE("HAVE_DEV_PTMX", 1),
        checks.AC_DEFINE("HAVE_FFI_CLOSURE_ALLOC", 1),
        checks.AC_DEFINE("HAVE_FFI_PREP_CIF_VAR", 1),
        checks.AC_DEFINE("HAVE_FFI_PREP_CLOSURE_LOC", 1),
        checks.AC_DEFINE("HAVE_LZMA_H", 1),
        checks.AC_DEFINE("HAVE_ZLIB_COPY", 1),
        checks.AC_DEFINE("HAVE_ZLIB_H", 1),
        checks.AC_DEFINE("HAVE_WORKING_TZSET", 1),
        checks.AC_DEFINE("PTHREAD_SYSTEM_SCHED_SUPPORTED", 1),
        checks.AC_DEFINE("PY_SSL_DEFAULT_CIPHERS", 1),
        checks.AC_DEFINE("PY_SQLITE_HAVE_SERIALIZE", 1),
        checks.AC_DEFINE("PY_SUPPORT_TIER", 2),
        checks.AC_DEFINE("_POSIX_C_SOURCE", "200809L"),
        checks.AC_DEFINE("_XOPEN_SOURCE", 700),
        checks.AC_DEFINE("_XOPEN_SOURCE_EXTENDED", 1),
    ] + ([checks.AC_DEFINE("HAVE_STDARG_PROTOTYPES", 1)] if version == "3.11" else []) + _dynamic_loading_checks(["-ldl"]) + _posix_shmem_checks(["-lrt"]) + _pty_checks("pty.h", "utmp.h", ["-lutil"]) + _linux_filesystem_checks() + _linux_library_checks()

def pyconfig(name, version):
    """Generates pyconfig.h with checks executed by the selected C toolchain.

    Args:
        name: Target name for the generated header.
        version: Supported CPython minor version.
    """
    if version not in ["3.11", "3.12", "3.13", "3.14"]:
        fail("unsupported CPython version: {}".format(version))

    autoconf(
        name = name + "_darwin_arm64",
        checks = _darwin_platform_checks(version, 1 if version in ["3.13", "3.14"] else 2),
    )

    autoconf(
        name = name + "_darwin_x86_64",
        checks = _darwin_platform_checks(version, 1),
    )

    autoconf(
        name = name + "_linux_arm64",
        checks = _linux_platform_checks(version),
    )

    autoconf(
        name = name + "_linux_x86_64",
        checks = _linux_platform_checks(version),
    )

    size_checks = [
        checks.AC_CHECK_ALIGNOF("long", define = "ALIGNOF_LONG"),
        checks.AC_CHECK_ALIGNOF("max_align_t", define = "ALIGNOF_MAX_ALIGN_T"),
        checks.AC_CHECK_ALIGNOF("size_t", define = "ALIGNOF_SIZE_T"),
        checks.AC_CHECK_SIZEOF("double", define = "SIZEOF_DOUBLE"),
        checks.AC_CHECK_SIZEOF("float", define = "SIZEOF_FLOAT"),
        checks.AC_CHECK_SIZEOF("fpos_t", define = "SIZEOF_FPOS_T", includes = ["#include <stdio.h>"]),
        checks.AC_CHECK_SIZEOF("int", define = "SIZEOF_INT"),
        checks.AC_CHECK_SIZEOF("long", define = "SIZEOF_LONG"),
        checks.AC_CHECK_SIZEOF("long double", define = "SIZEOF_LONG_DOUBLE"),
        checks.AC_CHECK_SIZEOF("long long", define = "SIZEOF_LONG_LONG"),
        checks.AC_CHECK_SIZEOF("off_t", define = "SIZEOF_OFF_T", includes = ["#define _FILE_OFFSET_BITS 64", "#include <sys/types.h>"]),
        checks.AC_CHECK_SIZEOF("pid_t", define = "SIZEOF_PID_T", includes = ["#include <sys/types.h>"]),
        checks.AC_CHECK_SIZEOF("pthread_t", define = "SIZEOF_PTHREAD_T", includes = ["#include <pthread.h>"]),
        checks.AC_CHECK_SIZEOF("pthread_key_t", define = "SIZEOF_PTHREAD_KEY_T", includes = ["#include <pthread.h>"]),
        checks.AC_CHECK_SIZEOF("short", define = "SIZEOF_SHORT"),
        checks.AC_CHECK_SIZEOF("size_t", define = "SIZEOF_SIZE_T"),
        checks.AC_CHECK_SIZEOF("time_t", define = "SIZEOF_TIME_T", includes = ["#include <time.h>"]),
        checks.AC_CHECK_SIZEOF("uintptr_t", define = "SIZEOF_UINTPTR_T", includes = ["#include <stdint.h>"]),
        checks.AC_CHECK_SIZEOF("void *", define = "SIZEOF_VOID_P"),
        checks.AC_CHECK_SIZEOF("wchar_t", define = "SIZEOF_WCHAR_T", includes = ["#include <wchar.h>"]),
        checks.AC_CHECK_SIZEOF("_Bool", define = "SIZEOF__BOOL"),
    ]

    type_checks = [
        checks.AC_CHECK_TYPE("clock_t", define = "HAVE_CLOCK_T", includes = ["#include <time.h>"], compile_defines = _SYSTEM_EXTENSION_DEFINES),
        checks.AC_CHECK_TYPE(
            "struct addrinfo",
            define = "HAVE_ADDRINFO",
            includes = ["#include <netdb.h>"],
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
        ),
        checks.AC_CHECK_TYPE("struct sockaddr_storage", define = "HAVE_SOCKADDR_STORAGE", includes = ["#include <sys/socket.h>"], compile_defines = _SYSTEM_EXTENSION_DEFINES),
        checks.AC_CHECK_TYPE("socklen_t", define = "HAVE_SOCKLEN_T", includes = ["#include <sys/socket.h>"], compile_defines = _SYSTEM_EXTENSION_DEFINES),
        checks.AC_CHECK_TYPE("ssize_t", define = "HAVE_SSIZE_T", includes = ["#include <sys/types.h>"], compile_defines = _SYSTEM_EXTENSION_DEFINES),
        checks.AC_CHECK_TYPE("__uint128_t", define = "HAVE_GCC_UINT128_T"),
    ]

    headers = _HEADERS + (_HEADERS_3_12 if version in ["3.11", "3.12"] else _HEADERS_3_13)
    functions = _FUNCTIONS + (_FUNCTIONS_3_13 if version in ["3.13", "3.14"] else [])
    version_checks = []
    if version in ["3.13", "3.14"]:
        version_checks.append(checks.AC_DEFINE(
            "WITH_MIMALLOC",
            condition = "HAVE_STD_ATOMIC",
            if_true = 1,
            if_false = None,
        ))

    autoconf(
        name = name + "_checks",
        checks = size_checks + type_checks + _compiler_checks() + macros.AC_CHECK_HEADERS(
            headers,
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
        ) + _dependent_header_checks(version) + _member_checks() + _declaration_checks(version) + _epoll_checks() + _special_function_checks(version) + macros.AC_CHECK_FUNCS(
            functions,
            compile_defines = _SYSTEM_EXTENSION_DEFINES,
        ) + _required_math_checks() + _capability_checks(version) + version_checks,
        deps = select({
            "//:darwin_arm64": [":" + name + "_darwin_arm64"],
            "//:darwin_x86_64": [":" + name + "_darwin_x86_64"],
            "//:linux_arm64": [":" + name + "_linux_arm64"],
            "//:linux_x86_64": [":" + name + "_linux_x86_64"],
        }),
    )

    autoconf_hdr(
        name = name + "_posix",
        out = "pyconfig.h",
        deps = [":" + name + "_checks"],
        template = "pyconfig.h.in",
    )

    native.alias(
        name = name,
        actual = select({
            "//:windows_arm64": "PC/pyconfig.h",
            "//:windows_x86_64": "PC/pyconfig.h",
            "//conditions:default": ":" + name + "_posix",
        }),
    )
