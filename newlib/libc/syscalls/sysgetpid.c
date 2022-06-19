/* connector for getpid */

#include <reent.h>
#include <unistd.h>

pid_t
getpid (void)
{
  return _getpid_r (_REENT);
}
