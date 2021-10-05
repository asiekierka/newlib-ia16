/* Version of sbrk for DOS.  */

#include <_syslist.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>
#include <reent.h>

extern size_t _heaplen;

void *
_sbrk_r (struct _reent *reent, int incr)
{
  extern char __heap_end_minimum; /* Set by linker script. */
  static char *heap_end = &__heap_end_minimum;
  char *prev_heap_end;
  char *new_heap_end;

  prev_heap_end = heap_end;
  if (__builtin_add_overflow((unsigned int)heap_end, (unsigned int)incr,
			     (unsigned int*)(&new_heap_end)) ||
      (unsigned int)new_heap_end >= (unsigned int)(&prev_heap_end) - 0x80u)
    {
      reent->_errno = ENOMEM;
      return (void*)-1;
    }
  if (_heaplen != 0 && new_heap_end - &__heap_end_minimum > _heaplen)
    {
      reent->_errno = ENOMEM;
      return (void*)-1;
    }
  heap_end = new_heap_end;
  memset(prev_heap_end, 0, incr);

  return (void *) prev_heap_end;
}
