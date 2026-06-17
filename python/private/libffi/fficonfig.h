#ifndef CPYTHON_BAZEL_LIBFFI_CONFIG_H
#define CPYTHON_BAZEL_LIBFFI_CONFIG_H

#define EH_FRAME_FLAGS "a"
#define HAVE_ALLOCA 1
#if !defined(_WIN32)
#define HAVE_ALLOCA_H 1
#define HAVE_AS_CFI_PSEUDO_OP 1
#else
#define HAVE_ALLOCA_H 0
#endif
#if defined(__x86_64__) && !defined(_WIN32)
#define HAVE_AS_X86_PCREL 1
#endif
#if !defined(_WIN32)
#define HAVE_DLFCN_H 1
#define HAVE_HIDDEN_VISIBILITY_ATTRIBUTE 1
#endif
#define HAVE_INTTYPES_H 1
#define HAVE_MEMCPY 1
#define HAVE_LONG_DOUBLE_VARIANT 0
#if defined(__linux__)
#define HAVE_MEMFD_CREATE 1
#endif
#if !defined(_WIN32)
#define HAVE_RO_EH_FRAME 1
#endif
#define HAVE_STDINT_H 1
#define HAVE_STDIO_H 1
#define HAVE_STDLIB_H 1
#if !defined(_WIN32)
#define HAVE_STRINGS_H 1
#endif
#define HAVE_STRING_H 1
#if !defined(_WIN32)
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_UNISTD_H 1
#endif
#if defined(__linux__)
#define LIBFFI_GNU_SYMBOL_VERSIONING 1
#endif
#define LT_OBJDIR ".libs/"
#define PACKAGE "libffi"
#define PACKAGE_BUGREPORT "http://github.com/libffi/libffi/issues"
#define PACKAGE_NAME "libffi"
#define PACKAGE_STRING "libffi 3.4.7"
#define PACKAGE_TARNAME "libffi"
#define PACKAGE_URL ""
#define PACKAGE_VERSION "3.4.7"
#define SIZEOF_DOUBLE 8
#if defined(_WIN32) || (defined(__APPLE__) && defined(__aarch64__))
#define HAVE_LONG_DOUBLE 0
#define SIZEOF_LONG_DOUBLE 8
#else
#define HAVE_LONG_DOUBLE 1
#define SIZEOF_LONG_DOUBLE 16
#endif
#define SIZEOF_SIZE_T 8
#define STDC_HEADERS 1
#define PDP 0
#define WORDS_BIGENDIAN 0
#define VERSION "3.4.7"

#ifdef HAVE_HIDDEN_VISIBILITY_ATTRIBUTE
#ifdef LIBFFI_ASM
#ifdef __APPLE__
#define FFI_HIDDEN(name) .private_extern name
#else
#define FFI_HIDDEN(name) .hidden name
#endif
#else
#define FFI_HIDDEN __attribute__((visibility("hidden")))
#endif
#else
#ifdef LIBFFI_ASM
#define FFI_HIDDEN(name)
#else
#define FFI_HIDDEN
#endif
#endif

#endif
