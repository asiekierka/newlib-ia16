/* Variable to control the maximum heap size, under DOS.  */

#include <stdlib.h>

/*
 * If the linker script or the user defines a symbol __heaplen_val, use that
 * as the maximum heap size.  Otherwise, use 0.
 *
 * This also happens to force _heaplen to be given actual bytes in the output
 * executable --- which is useful, because some tools might want to patch
 * _heaplen statically (e.g. tools/ptchsize.c for FreeDOS command.com).
 */
extern char __heaplen_val[] __attribute__ ((weak));
size_t _heaplen = (size_t) __heaplen_val;
