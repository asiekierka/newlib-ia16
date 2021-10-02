/* Variable to control the maximum heap size, under DOS.  */

#include <stdlib.h>

/*
 * If the linker script or the user defines a symbol __heaplen_val, use that
 * as the maximum heap size.  Otherwise, use 0.
 */
extern char __heaplen_val[] __attribute__ ((weak));
size_t _heaplen = (size_t) __heaplen_val;
