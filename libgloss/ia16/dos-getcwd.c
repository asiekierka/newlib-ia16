/* dos-getcwd.c basic getcwd for MS-DOS which factors in drive letters
 *
 * Copyright (c) 2021 TK Chia
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

#include <errno.h>
#include <limits.h>
#include <string.h>
#include <unistd.h>
#include "pmode.h"

#ifndef FP_SEG
#define FP_SEG(x) \
  __builtin_ia16_selector ((unsigned)((unsigned long)(void __far *)(x) >> 16))
#endif

static unsigned char
__msdos_getdrive (void)
{
  unsigned ax;
  asm volatile ("int $0x21" : "=a" (ax)
			    : "Rah" ((unsigned char) 0x19)
			    : "cc", "bx", "cx", "dx");
  return (unsigned char) ax;
}

static char *
__msdos_getcwd (char buf[PATH_MAX])
{
  int err, carry, xx1, xx2;
  unsigned char drive;

  /*
   * First get the current directory for the current drive, sans drive
   * letter.  If that fails, bail out.
   */
  asm volatile (RMODE_DOS_CALL_ "; sbbw %1, %1"
		: "=a" (err), "=bcd" (carry), "=bcd" (xx1), "=bcd" (xx2)
		: "Rah" ((unsigned char) 0x47), "Rdl" ((unsigned char)0),
		  "Rds" (FP_SEG (buf + 3)), "S" (buf + 3)
		: "cc", "memory");
  if (carry)
    {
      errno = err;
      return NULL;
    }

  /* If there was no failure, get the drive letter. */
  drive = __msdos_getdrive ();

  /* Plug in the drive letter. */
  buf[0] = 'A' + drive;
  buf[1] = ':';
  buf[2] = '\\';
  return buf;
}

char *
getcwd (char *buf, size_t size)
{
  if (! buf)
    {
      char our_buf[PATH_MAX];

      if (! __msdos_getcwd (our_buf))
	return NULL;

      return strdup (our_buf);
    }
  else if (size >= PATH_MAX)
    return __msdos_getcwd (buf);
  else
    {
      char our_buf[PATH_MAX];
      size_t our_len;

      if (! __msdos_getcwd (our_buf))
	return NULL;

      our_len = strlen (our_buf);
      if (our_len >= size)
	{
	  errno = ERANGE;
	  return NULL;
	}

      memcpy (buf, our_buf, our_len + 1);
      return buf;
    }
}
