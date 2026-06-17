#include <stdint.h>

#include <ffi.h>

typedef int32_t (*binary_function)(int32_t, int32_t);

static void
add_with_bias(ffi_cif *cif, void *result, void **arguments, void *user_data)
{
    int32_t left = *(int32_t *)arguments[0];
    int32_t right = *(int32_t *)arguments[1];
    int32_t bias = *(int32_t *)user_data;

    (void)cif;
    *(int32_t *)result = left + right + bias;
}

int
main(void)
{
    ffi_cif cif;
    ffi_closure *closure;
    ffi_type *argument_types[] = {
        &ffi_type_sint32,
        &ffi_type_sint32,
    };
    void *code;
    int32_t bias = 7;
    binary_function function;

    if (ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 2, &ffi_type_sint32,
                     argument_types) != FFI_OK) {
        return 1;
    }

    closure = ffi_closure_alloc(sizeof(ffi_closure), &code);
    if (closure == NULL) {
        return 2;
    }

    if (ffi_prep_closure_loc(closure, &cif, add_with_bias, &bias, code) != FFI_OK) {
        ffi_closure_free(closure);
        return 3;
    }

    function = (binary_function)code;
    if (function(11, 13) != 31) {
        ffi_closure_free(closure);
        return 4;
    }

    ffi_closure_free(closure);
    return 0;
}
