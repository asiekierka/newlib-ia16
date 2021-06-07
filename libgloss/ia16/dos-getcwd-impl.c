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

unsigned char
__msdos_getdrive (void)
{
  unsigned ax;
  asm volatile ("int $0x21" : "=a" (ax)
			    : "Rah" ((unsigned char) 0x19)
			    : "cc", "bx", "cx", "dx");
  return (unsigned char) ax;
}

/* DRIVE = 0 for the current drive, 1 for A:, 2 for B:, etc. */
char *
__msdos_getcwd (char buf[PATH_MAX], unsigned char drive)
{
  int err, carry, xx1, xx2;

  /*
   * First get the current directory for the specified drive, sans drive
   * letter.  If that fails, bail out.
   */
  asm volatile (RMODE_DOS_CALL_ "; sbbw %1, %1"
		: "=a" (err), "=r" (carry)
		: "Rah" ((unsigned char) 0x47), "Rdl" ((unsigned char)drive),
		  "Rds" (FP_SEG (buf + 3)), "S" (buf + 3)
		: "cc", "memory");
  if (carry)
    {
      errno = err;
      return NULL;
    }

  /* If there was no failure, get the drive letter. */
  if (drive)
    --drive;
  else
    drive = __msdos_getdrive ();

  /* Plug in the drive letter. */
  buf[0] = 'A' + drive;
  buf[1] = ':';
  buf[2] = '\\';
  return buf;
}
