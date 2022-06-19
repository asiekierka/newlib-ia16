/* connector for kill */

#include <reent.h>
#include <signal.h>

int
kill (pid_t pid,
     int sig)
{
  return _kill_r (_REENT, pid, sig);
}
