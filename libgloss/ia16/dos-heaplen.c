/* Variable to control the maximum heap size, under DOS.  */

#include <stdlib.h>

/* Force _heaplen to be given actual bytes in the output executable, in case
   some tools want to patch it statically (e.g. tools/ptchsize.c for FreeDOS
   command.com).  */
size_t _heaplen __attribute__ ((nocommon, section (".data"))) = 0;
