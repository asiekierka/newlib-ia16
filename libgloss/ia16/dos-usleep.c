/* dos-usleep.c basic microsecond sleep implementation for DOS
 *
 * Copyright (c) 2018 TK Chia
 *
 * The authors hereby grant permission to use, copy, modify, distribute,
 * and license this software and its documentation for any purpose, provided
 * that existing copyright notices are retained in all copies and that this
 * notice is included verbatim in any distributions. No written agreement,
 * license, or royalty fee is required for any of the authorized uses.
 * Modifications to this software may be copyrighted by their authors
 * and need not follow the licensing terms described here, provided that
 * the new terms are clearly indicated on the first page of each file where
 * they apply.
 */

#include <limits.h>
#include <string.h>
#include <unistd.h>
#include <sys/times.h>
#include <errno.h>
#include <_syslist.h>
#include <machine/time.h>

#ifndef _CLOCKS_PER_SEC_
# define _CLOCKS_PER_SEC_ 1000
#endif

/* Sleep for a number of clock ticks.  */
static inline int
sleep_ticks (clock_t ticks)
{
  struct tms tms;
  clock_t start, now;

  start = times (&tms);
  if (start == -1)
    return -1;

  do
    {
      __asm volatile ("hlt");

      now = times (&tms);
      if (now == -1)
	return -1;
    }
  while (now - start < ticks);

  return 0;
}

#if 1000000UL % _CLOCKS_PER_SEC_ == 0
# define MULTIPLIER	((clock_t) 1)
# define DIVISOR	((clock_t) (1000000ULL / _CLOCKS_PER_SEC_))
#else
# define MULTIPLIER	((unsigned long long) _CLOCKS_PER_SEC_)
# define DIVISOR	1000000ULL
#endif

/* Convert microseconds to clock ticks.  The arithmetic is assumed not to
   overflow (the main usleep (.) routine should ensure that).  */
static inline clock_t
usecs_to_ticks (useconds_t usecs)
{
  return (clock_t) ((usecs * MULTIPLIER + DIVISOR - 1) / DIVISOR);
}

int
usleep (useconds_t usecs)
{
  const clock_t clock_limit_1
    = (clock_t) (1ULL << (sizeof(clock_t) * CHAR_BIT - 2));
  const unsigned long long usecs_limit_1
    = (unsigned long long) clock_limit_1 * 1000000ULL / _CLOCKS_PER_SEC_;
  const useconds_t usecs_limit_2
    = (((useconds_t) 0 - (useconds_t) DIVISOR) / DIVISOR - 1) * DIVISOR;
  const useconds_t max_usecs
    = usecs_limit_1 < usecs_limit_2 ? usecs_limit_1 : usecs_limit_2;
  struct tms tms;

  /* If the sleep is for more than MAX_USECS microseconds, divide it up into
     intervals of not more than that amount each.  */
  while (usecs > max_usecs)
    {
      if (sleep_ticks (usecs_to_ticks (max_usecs)))
	return -1;

      usecs -= max_usecs;
    }

  /* Return if there is no further need to sleep.  */
  if (! usecs)
    return 0;

  /* Otherwise, sleep the remaining amount.  */
  return sleep_ticks (usecs_to_ticks (usecs));
}
