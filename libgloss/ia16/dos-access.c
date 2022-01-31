/*
 * Copyright (c) 2022 TK Chia
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
#include <fcntl.h>
#include <unistd.h>
#include "pmode.h"

#ifndef FP_SEG
#define FP_SEG(x) \
  __builtin_ia16_selector ((unsigned)((unsigned long)(void __far *)(x) >> 16))
#endif

#define _A_RDONLY 1
#define _A_SUBDIR 0x10

static unsigned
dos_getfileattr (const char *path, unsigned *attrs)
{
  int carry, err, cx;

  __asm volatile (RMODE_DOS_CALL_ "; sbbw %2, %2"
		  : "=a" (err), "=c" (cx), "=d" (carry)
		  : "0" (0x4300U), "Rds" (FP_SEG (path)), "2" (path)
		  : "bx", "cc", "memory");

  if (carry)
    {
      errno = err;
      return err;
    }

  *attrs = cx;
  return 0;
}

int
access (const char *path, int checks)
{
  unsigned attrs;

  if ((checks & ~(F_OK | R_OK | W_OK | X_OK)) != 0)
    {
      errno = EINVAL;
      return -1;
    }

  if (dos_getfileattr (path, &attrs) != 0)
    return -1;

  if ((checks & W_OK) != 0)
    {
      if ((attrs & (_A_RDONLY | _A_SUBDIR)) == _A_RDONLY)
	{
	  errno = EACCES;
	  return -1;
	}
    }

  return 0;
}
