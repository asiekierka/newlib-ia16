/*
 * Version of _gettimeofday_r for DOS.  This is slow and stupid, but probably
 * does not take up too much space.
 *
 * Copyright (c) 2017--2021 TK Chia
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

#include <_syslist.h>
#include <reent.h>
#include <time.h>
#include <sys/time.h>

int
_gettimeofday_r (struct _reent *reent, struct timeval *tv, void *tzvp)
{
  static volatile char tz_inited = 0;
  unsigned ax, bx, cx, dx, old_cx, old_dx;
  suseconds_t usec;
  struct tm tm;
  time_t tim;

  if (!tz_inited)
    {
      tzset ();
      tz_inited = 1;
    }

  /* Read the date once.  */
  __asm __volatile ("movb $0x2a, %%ah; int $0x21"
    : "=&a" (ax), "=b" (bx), "=c" (cx), "=d" (dx) : : "cc", "memory");

  do
    {
      old_cx = cx;
      old_dx = dx;

      /* Read the time.  */
      __asm __volatile ("movb $0x2c, %%ah; int $0x21"
	: "=&a" (ax), "=b" (bx), "=c" (cx), "=d" (dx) : : "cc", "memory");

      tm.tm_hour = cx >> 8;
      tm.tm_min = cx & 0xff;
      tm.tm_sec = dx >> 8;
      usec = (dx & 0xff) * 10000ul;

      if (tm.tm_hour != 0)
	break;

      /* If the time is close to midnight, read the date again to check for
	 midnight crossover.  If crossover happens, repeat until it stops.  */
      __asm __volatile ("movb $0x2a, %%ah; int $0x21"
	: "=&a" (ax), "=b" (bx), "=c" (cx), "=d" (dx) : : "cc", "memory");
    }
  while (cx != old_cx || dx != old_dx);

  tm.tm_year = old_cx - 1900;
  tm.tm_mon = (old_dx >> 8) - 1;
  tm.tm_mday = old_dx & 0xff;
  tm.tm_isdst = -1;

  tim = mktime (&tm);
  if (tim == -1)
    return -1;

  if (tv)
    {
      tv->tv_sec = tim;
      tv->tv_usec = usec;
    }

  if (tzvp)
    {
      struct timezone *tz = tzvp;
      tz->tz_minuteswest = _timezone / 60;
      tz->tz_dsttime = _daylight;
    }

  return 0;
}
