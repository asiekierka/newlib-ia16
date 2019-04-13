/* Version of sbrk for ELKS.  */

#include <_syslist.h>
#include <errno.h>

#undef errno
extern int errno;

extern int _brk (char *);

size_t _heaplen = 0;

void *
_sbrk (incr)
     int incr;
{ 
   extern char __heap_end_minimum[]; /* Defined by linker script.  */
   static char *heap_end;
   char *prev_heap_end; 

   if (heap_end == 0)
     heap_end = __heap_end_minimum;

   if (_heaplen != 0 && heap_end + incr - __heap_end_minimum > _heaplen)
     {
       errno = ENOMEM;
       return (void *) -1;
     }

   prev_heap_end = heap_end; 
   heap_end += incr; 

   if (heap_end >= __heap_end_minimum
       && (0 == _brk (heap_end)))
     return (void *) prev_heap_end; 

   heap_end = prev_heap_end;
   errno = ENOMEM;
   return ((void *) -1);
} 
