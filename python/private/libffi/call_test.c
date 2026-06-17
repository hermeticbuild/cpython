#include <stdint.h>

#include <ffi.h>

static int32_t compare_pointers(const void *left, const void *right) {
  return left == right ? 0 : -1;
}

int main(void) {
  ffi_cif cif;
  ffi_type *argument_types[] = {
      &ffi_type_pointer,
      &ffi_type_pointer,
  };
  int marker;
  void *left = &marker;
  void *right = &marker;
  void *arguments[] = {
      &left,
      &right,
  };
  int32_t result = -1;

  if (ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 2, &ffi_type_sint32,
                   argument_types) != FFI_OK) {
    return 1;
  }
  ffi_call(&cif, FFI_FN(compare_pointers), &result, arguments);
  return result != 0;
}
