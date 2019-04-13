/* Version of abort for ELKS.  */

#include <signal.h>

void
abort (void)
{
  for (;;)
    raise (SIGABRT);
}
