/* dos-openr.c basic open file for DOS
 *
 * Copyright (c) 2018 Bart Oldeman
 * Copyright (c) 2019--2021 TK Chia
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

#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <reent.h>
#include <_syslist.h>
#include "pmode.h"

#ifndef FP_SEG
#define FP_SEG(x) \
  __builtin_ia16_selector ((unsigned)((unsigned long)(void __far *)(x) >> 16))
#endif

/* the following flag combinations are used by fopen():
   'r': O_RDONLY
   'w': O_WRONLY | O_CREAT | O_TRUNC
   'a': O_WRONLY | O_CREAT | O_APPEND
   '+': |O_RDWR
   'b': |O_BINARY (not implemented yet)
   't': |O_TEXT (not implemented yet)
   'x': |O_EXCL
*/

static int dos_exists (const char *pathname)
{
  int carry;
  asm volatile (RMODE_DOS_CALL_ "; sbb %0, %0" :
		"=a"(carry) :
	        "a"(0x4300), "d"(pathname), "Rds"(FP_SEG(pathname)) :
		"cx", "cc");
  return carry + 1;
}

static int dos_open (struct _reent *reent, const char *pathname,
		     unsigned char flags)
{
  int ret, carry;
  asm volatile (RMODE_DOS_CALL_ "; sbb %0, %0" :
		"=r"(carry), "=a"(ret) :
	        "Rah"((char)0x3d), "Ral"(flags), "d"(pathname),
		"Rds"(FP_SEG(pathname)) : "cc");
  if (carry)
    {
      reent->_errno = ret;
      return carry;
    }
  return ret;
}

static int dos_creat (struct _reent *reent, const char *pathname,
		      unsigned char attr)
{
  int ret, carry;
  asm volatile (RMODE_DOS_CALL_ "; sbb %0, %0" :
		"=r"(carry), "=a"(ret) :
	        "Rah"((char)0x3c), "Rcl"(attr), "d"(pathname),
		"Rds"(FP_SEG(pathname)) : "cc");
  if (carry)
    {
      reent->_errno = ret;
      return carry;
    }
  return ret;
}

static int
dos_truncate_fd (struct _reent *reent, int fd)
{
  int ret, carry;
  asm volatile ("int $0x21; sbb %0, %0" :
		"=r" (carry), "=a" (ret) :
		"Rah" ((char)0x40), "b" (fd), "c" (0u) : "cc");
  if (carry)
    {
      reent->_errno = ret;
      return carry;
    }
  return ret;
}

int
_open_r (struct _reent *reent, const char *pathname, int flags, int mode)
{
  int fd = -1;
  off_t ret;

  if (flags & O_CREAT)
    {
      /* special but common case O_WRONLY | O_CREAT | O_TRUNC
	 should be handled by only calling dos_creat */
      int fileexists = 0;
      if ((flags & (O_EXCL|O_TRUNC)) != O_TRUNC)
	{
	  fileexists = dos_exists(pathname);
	  if (fileexists && (flags & O_EXCL))
	    {
	      reent->_errno = EEXIST;
	      return -1;
	    }
	}
      if (!fileexists)
	{
	  fd = dos_creat(reent, pathname, (mode & S_IWUSR) ? 0 : 1);
	  if (fd != -1)
	    {
	      if ((flags & O_ACCMODE) == O_WRONLY)
		return fd;
	      close(fd);
	      fd = -1;
	    }
	}
    }

  /* try to open file with mode */
  if (fd == -1)
    fd = dos_open(reent, pathname, flags & O_ACCMODE);
  if (fd == -1)
    return fd;
  ret = 0;
  if (flags & O_TRUNC)
    ret = dos_truncate_fd (reent, fd);
  else if (flags & O_APPEND)
    ret = _lseek_r(reent, fd, 0, SEEK_END);
  if (ret == -1)
    {
      close(fd);
      return ret;
    }
  return fd;
}
