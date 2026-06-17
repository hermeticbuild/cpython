#include <complex.h>
#include <ffi.h>

static int
z_is_expected(double complex z)
{
    const double complex expected = 1.25 - 0.5 * I;
    return z == expected;
}

int
main(void)
{
    double complex z = 1.25 - 0.5 * I;
    ffi_type *args[1] = {&ffi_type_complex_double};
    void *values[1] = {&z};
    ffi_cif cif;
    ffi_arg result;

    if (ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 1, &ffi_type_sint, args) != FFI_OK) {
        return 2;
    }
    ffi_call(&cif, FFI_FN(z_is_expected), &result, values);
    return !result;
}
