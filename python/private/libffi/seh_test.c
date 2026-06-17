#include <windows.h>

#include <ffi.h>

__declspec(noinline) static void raise_access_violation(
    void *argument0, void *argument1, void *argument2, void *argument3,
    void *argument4, void *argument5, void *argument6, void *argument7,
    void *argument8) {
  (void)argument0;
  (void)argument1;
  (void)argument2;
  (void)argument3;
  (void)argument4;
  (void)argument5;
  (void)argument6;
  (void)argument7;
  (void)argument8;
  RaiseException(EXCEPTION_ACCESS_VIOLATION, 0, 0, NULL);
}

int main(void) {
  ffi_cif cif;
  ffi_type *argument_types[] = {
      &ffi_type_pointer, &ffi_type_pointer, &ffi_type_pointer,
      &ffi_type_pointer, &ffi_type_pointer, &ffi_type_pointer,
      &ffi_type_pointer, &ffi_type_pointer, &ffi_type_pointer,
  };
  void *argument = NULL;
  void *arguments[] = {
      &argument, &argument, &argument,
      &argument, &argument, &argument,
      &argument, &argument, &argument,
  };

  if (ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 9, &ffi_type_void,
                   argument_types) != FFI_OK) {
    return 1;
  }

  __try {
    ffi_call(&cif, FFI_FN(raise_access_violation), NULL, arguments);
  } __except (GetExceptionCode() == EXCEPTION_ACCESS_VIOLATION
                  ? EXCEPTION_EXECUTE_HANDLER
                  : EXCEPTION_CONTINUE_SEARCH) {
    return 0;
  }

  return 2;
}
