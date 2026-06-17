#include "Python.h"

/* PC/dl_nt.c defines PyWin_DLLhModule only when Py_ENABLE_SHARED is set. */
void *PyWin_DLLhModule = NULL;
