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
#error "Linux arm64 must provide the required Linux capabilities"
#endif
#endif
#if PY_VERSION_HEX >= 0x030D0000 &&                                            \
    (!defined(HAVE_SYS_TIMERFD_H) || !defined(HAVE_TIMERFD_CREATE))
#error "CPython 3.13 and newer on Linux must provide timerfd"
#endif
#elif defined(__APPLE__)
#if !defined(HAVE_CHFLAGS) ||                                                  \
    !defined(HAVE_DYLD_SHARED_CACHE_CONTAINS_PATH) || !defined(HAVE_KQUEUE) || \
    !defined(HAVE_LCHFLAGS) || !defined(HAVE_LCHMOD) ||                        \
    !defined(HAVE_SYS_EVENT_H) || !defined(HAVE_SYS_KERN_CONTROL_H) ||         \
    !defined(HAVE_SYS_SYS_DOMAIN_H)
#error "Darwin arm64 must provide the required Darwin capabilities"
#endif
#if PY_VERSION_HEX >= 0x030D0000 &&                                            \
    !defined(HAVE_PTHREAD_COND_TIMEDWAIT_RELATIVE_NP)
#error                                                                         \
    "CPython 3.13 and newer on Darwin must provide pthread_cond_timedwait_relative_np"
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
