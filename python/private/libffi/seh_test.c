#include <windows.h>

#include <ffi.h>

__declspec(noinline) static void raise_access_violation(void) {
  RaiseException(EXCEPTION_ACCESS_VIOLATION, 0, 0, NULL);
}

int main(void) {
  ffi_cif cif;

  if (ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 0, &ffi_type_void, NULL) != FFI_OK) {
    return 1;
  }

  __try {
    ffi_call(&cif, FFI_FN(raise_access_violation), NULL, NULL);
  } __except (GetExceptionCode() == EXCEPTION_ACCESS_VIOLATION
                  ? EXCEPTION_EXECUTE_HANDLER
                  : EXCEPTION_CONTINUE_SEARCH) {
    return 0;
  }

  return 2;
}
