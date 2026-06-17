#include "pyconfig.h"

#if defined(PACKAGE_BUGREPORT) || defined(PACKAGE_NAME) ||                     \
    defined(PACKAGE_STRING) || defined(PACKAGE_TARNAME) ||                     \
    defined(PACKAGE_URL) || defined(PACKAGE_VERSION)
#error "PACKAGE_* must remain undefined"
#endif

#ifdef PYLONG_BITS_IN_DIGIT
#error "PYLONG_BITS_IN_DIGIT must use the CPython header default"
#endif

#ifdef Py_HASH_ALGORITHM
#error "Py_HASH_ALGORITHM must use the CPython header default"
#endif

#include "Python.h"

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <sys/types.h>
#include <time.h>
#include <wchar.h>

#ifndef MS_WINDOWS
#include <pthread.h>
#endif

#if !defined(HAVE_ACOSH) || !defined(HAVE_ASINH) || !defined(HAVE_ATANH) ||    \
    !defined(HAVE_ERF) || !defined(HAVE_ERFC) || !defined(HAVE_EXPM1) ||       \
    !defined(HAVE_LOG1P) || !defined(HAVE_LOG2)
#error "the required C99 math functions must be available"
#endif

#ifndef MS_WINDOWS
#if !defined(HAVE_DIRFD) || !defined(HAVE_FSEEKO) || !defined(HAVE_FTELLO) ||  \
    !defined(HAVE_GETC_UNLOCKED) || !defined(HAVE_IF_NAMEINDEX) ||             \
    !defined(HAVE_INTTYPES_H) || !defined(HAVE_LOGIN_TTY) ||                   \
    !defined(HAVE_LONG_DOUBLE) || !defined(HAVE_MAKEDEV) ||                    \
    !defined(HAVE_SETVBUF) || !defined(HAVE_TM_ZONE) ||                        \
    !defined(HAVE_WCSFTIME) || !defined(HAVE_WMEMCMP) ||                       \
    !defined(HAVE_WORKING_TZSET) || !defined(PTHREAD_SYSTEM_SCHED_SUPPORTED)
#error "the supported POSIX targets must provide the required capabilities"
#endif

#if !defined(HAVE_BZLIB_H) || !defined(HAVE_LIBSQLITE3) ||                    \
    !defined(HAVE_LZMA_H) || !defined(HAVE_ZLIB_COPY) ||                      \
    !defined(HAVE_ZLIB_H) || !defined(PY_SQLITE_HAVE_SERIALIZE) ||            \
    !defined(PY_SSL_DEFAULT_CIPHERS)
#error "the bundled dependencies must provide their configured capabilities"
#endif

#if PY_VERSION_HEX >= 0x030C0000 &&                                           \
    (!defined(HAVE_FFI_CLOSURE_ALLOC) || !defined(HAVE_FFI_PREP_CIF_VAR) ||   \
     !defined(HAVE_FFI_PREP_CLOSURE_LOC))
#error "the bundled libffi must provide its configured capabilities"
#endif

#if PY_VERSION_HEX < 0x030C0000 &&                                            \
    (!defined(HAVE_MEMORY_H) || !defined(HAVE_STDARG_PROTOTYPES) ||            \
     !defined(HAVE_TTYNAME) || !defined(PY_FORMAT_SIZE_T) ||                   \
     !defined(TIME_WITH_SYS_TIME))
#error "CPython 3.11 must provide its compatibility definitions"
#endif

#if defined(__x86_64__)
#if !defined(HAVE_GCC_ASM_FOR_X64)
#error "the supported x86_64 targets must provide the x64 assembly check"
#endif
#if defined(__linux__) && !defined(HAVE_GCC_ASM_FOR_X87)
#error "the supported Linux x86_64 target must provide the x87 assembly check"
#endif
#if defined(__APPLE__) && PY_VERSION_HEX < 0x030C0000 &&                       \
    defined(HAVE_GCC_ASM_FOR_X87)
#error "CPython 3.11 must disable x87 assembly on Darwin x86_64"
#endif
#if defined(__APPLE__) && PY_VERSION_HEX >= 0x030C0000 &&                      \
    !defined(HAVE_GCC_ASM_FOR_X87)
#error "CPython 3.12 and newer must enable x87 assembly on Darwin x86_64"
#endif
#elif defined(__aarch64__)
#if defined(HAVE_GCC_ASM_FOR_X64) || defined(HAVE_GCC_ASM_FOR_X87)
#error "the supported arm64 targets must not provide x86 assembly checks"
#endif
#endif

#if PY_VERSION_HEX >= 0x030E0000 &&                                           \
    (!defined(HAVE_BACKTRACE) || !defined(HAVE_DLADDR) ||                     \
     !defined(HAVE_EXECINFO_H) || !defined(HAVE_PTHREAD_GETNAME_NP) ||        \
     !defined(HAVE_PTHREAD_SETNAME_NP) || !defined(Py_REMOTE_DEBUG) ||        \
     !defined(_Py_FFI_SUPPORT_C_COMPLEX) || !defined(_Py_STACK_GROWS_DOWN))
#error "CPython 3.14 must provide its required POSIX capabilities"
#endif
#endif

#if !defined(MS_WINDOWS) && PY_VERSION_HEX >= 0x030D0000 &&                    \
    (!defined(HAVE___UINT128_T) || !defined(WITH_MIMALLOC))
#error "CPython 3.13 and newer must use __uint128_t and mimalloc"
#endif

#if defined(__linux__)
#if PY_VERSION_HEX >= 0x030C0000
#if !defined(HAVE_DEVICE_MACROS) || !defined(HAVE_EVENTFD) ||                  \
    !defined(HAVE_FDATASYNC) || !defined(HAVE_GETRANDOM_SYSCALL) ||            \
    !defined(HAVE_HTOLE64) || !defined(HAVE_LINUX_LIMITS_H) ||                 \
    !defined(HAVE_LINUX_NETLINK_H) || !defined(HAVE_LINUX_VM_SOCKETS_H) ||     \
    !defined(HAVE_NETPACKET_PACKET_H) || !defined(HAVE_PREADV2) ||             \
    !defined(HAVE_PWRITEV2) || !defined(HAVE_SETNS) ||                         \
    !defined(HAVE_SOCKADDR_ALG) || !defined(HAVE_SPLICE) ||                    \
    !defined(HAVE_SYS_EVENTFD_H) || !defined(HAVE_SYS_SYSCALL_H) ||            \
    !defined(HAVE_SYS_SYSMACROS_H) || !defined(HAVE_SYS_XATTR_H) ||            \
    !defined(HAVE_UNSHARE) || !defined(MAJOR_IN_SYSMACROS) ||                  \
    !defined(PTHREAD_KEY_T_IS_COMPATIBLE_WITH_INT)
#error "the supported Linux targets must provide the required Linux capabilities"
#endif
#endif
#if PY_VERSION_HEX >= 0x030D0000 &&                                            \
    (!defined(HAVE_SYS_TIMERFD_H) || !defined(HAVE_TIMERFD_CREATE))
#error "CPython 3.13 and newer on Linux must provide timerfd"
#endif
#if PY_VERSION_HEX >= 0x030E0000 &&                                           \
    (!defined(HAVE_DLADDR1) || !defined(HAVE_LINK_H) ||                       \
     !defined(HAVE_LINUX_NETFILTER_IPV4_H) || !defined(HAVE_LINUX_SCHED_H) || \
     !defined(HAVE_PTHREAD_GETATTR_NP) || _PYTHREAD_NAME_MAXLEN != 15)
#error "CPython 3.14 on Linux must provide its platform capabilities"
#endif
#elif defined(__APPLE__)
#if !defined(HAVE_CHFLAGS) ||                                                  \
    !defined(HAVE_DYLD_SHARED_CACHE_CONTAINS_PATH) || !defined(HAVE_KQUEUE) || \
    !defined(HAVE_LCHFLAGS) || !defined(HAVE_LCHMOD) ||                        \
    !defined(HAVE_SYS_EVENT_H) || !defined(HAVE_SYS_KERN_CONTROL_H) ||         \
    !defined(HAVE_SYS_SYS_DOMAIN_H)
#error "the supported Darwin targets must provide the required Darwin capabilities"
#endif
#if PY_VERSION_HEX >= 0x030D0000 &&                                            \
    !defined(HAVE_PTHREAD_COND_TIMEDWAIT_RELATIVE_NP)
#error                                                                         \
    "CPython 3.13 and newer on Darwin must provide pthread_cond_timedwait_relative_np"
#endif
#if PY_VERSION_HEX >= 0x030E0000 && _PYTHREAD_NAME_MAXLEN != 63
#error "CPython 3.14 on Darwin must use a 63-byte pthread name limit"
#endif
#elif defined(MS_WINDOWS)
#if !defined(_MSC_VER) || !defined(MS_WIN64)
#error "Windows builds must use the MSVC ABI on a 64-bit target"
#endif
#else
#error "unsupported CPython platform"
#endif

#define CHECK_SIZE(name, type)                                                 \
  _Static_assert(name == sizeof(type),                                         \
                 #name " does not match sizeof(" #type ")")
#define CHECK_ALIGNMENT(name, type)                                            \
  _Static_assert(name == _Alignof(type),                                       \
                 #name " does not match _Alignof(" #type ")")

CHECK_ALIGNMENT(ALIGNOF_LONG, long);
#if PY_VERSION_HEX >= 0x030C0000
CHECK_ALIGNMENT(ALIGNOF_MAX_ALIGN_T, max_align_t);
#endif
CHECK_ALIGNMENT(ALIGNOF_SIZE_T, size_t);
CHECK_SIZE(SIZEOF_DOUBLE, double);
CHECK_SIZE(SIZEOF_FLOAT, float);
CHECK_SIZE(SIZEOF_FPOS_T, fpos_t);
CHECK_SIZE(SIZEOF_INT, int);
CHECK_SIZE(SIZEOF_LONG, long);
#ifndef MS_WINDOWS
CHECK_SIZE(SIZEOF_LONG_DOUBLE, long double);
#endif
CHECK_SIZE(SIZEOF_LONG_LONG, long long);
CHECK_SIZE(SIZEOF_OFF_T, off_t);
CHECK_SIZE(SIZEOF_PID_T, pid_t);
#ifndef MS_WINDOWS
CHECK_SIZE(SIZEOF_PTHREAD_KEY_T, pthread_key_t);
CHECK_SIZE(SIZEOF_PTHREAD_T, pthread_t);
#endif
CHECK_SIZE(SIZEOF_SHORT, short);
CHECK_SIZE(SIZEOF_SIZE_T, size_t);
CHECK_SIZE(SIZEOF_TIME_T, time_t);
CHECK_SIZE(SIZEOF_UINTPTR_T, uintptr_t);
CHECK_SIZE(SIZEOF_VOID_P, void *);
CHECK_SIZE(SIZEOF_WCHAR_T, wchar_t);
CHECK_SIZE(SIZEOF__BOOL, _Bool);
