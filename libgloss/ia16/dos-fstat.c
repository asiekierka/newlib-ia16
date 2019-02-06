/* dos-fstat.c basic fstat for DOS
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

#include <string.h>
#include <time.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <errno.h>
#include <_syslist.h>

#undef errno
extern int errno;

extern time_t __msdos_cvt_file_time (unsigned, unsigned);

/*
 * From Jenner's old dos-fstat.S:
 *
 *	"Many of the fields of struct stat are not applicable for DOS, or
 *	 are complex to compute.  Newlib's makebuf uses fstat to validate
 *	 file descriptors, so we should do that at least.  For now we'll
 *	 just do the `Get Device Information' IOCTL call and fill in the
 *	 fields we can get from that."
 *
 * In addition, Dunkels (et al.)'s ubasic also uses fstat (...) to obtain the
 * size of regular files.  Now, DOS 2+'s file descriptor interface only allows
 * us to query an open file's size if we mess with its file pointer, so it
 * looks like that is what we have to do.  -- tkchia
 */

static int
dos_ioctl_get_fd_info (int fd, unsigned *p_diw)
{
  int ret, carry;
  unsigned diw;
  asm volatile ("int $0x21; sbbw %0, %0"
		: "=r" (carry), "=a" (ret), "=d" (diw)
		: "1" (0x4400u), "b" (fd) : "cc");
  if (carry)
    {
      errno = ret;
      return carry;
    }
  *p_diw = diw;
  return 0;
}

static int
dos_lseek (int fd, off_t offset, int whence, off_t *p_new_offset)
{
  int carry;
  unsigned ax, dx;
  asm volatile ("int $0x21; sbbw %0, %0"
		: "=r" (carry), "=a" (ax), "=d" (dx)
		: "1" (0x4200u | (unsigned char) whence), "b" (fd),
		  "c" ((unsigned) (offset >> 16)), "d" ((unsigned) offset)
		: "cc");
  if (carry)
    {
      errno = (int) ax;
      return carry;
    }
  if (p_new_offset)
    *p_new_offset = (off_t) dx << 16 | ax;
  return 0;
}

static time_t
dos_get_fd_mtime (int fd)
{
  int ret, carry;
  unsigned cx, dx;

  asm volatile ("int $0x21; sbbw %0, %0"
		: "=r" (carry), "=a" (ret), "=c" (cx), "=d" (dx)
		: "1" (0x5700u), "b" (fd)
		: "cc");
  if (carry)
    {
      errno = ret;
      return carry;
    }

  return __msdos_cvt_file_time (dx, cx);
}

int
_fstat (int fd, struct stat * restrict buf)
{
  unsigned diw;
  off_t save_offset, eof_offset;

  memset (buf, 0, sizeof *buf);

  if (dos_ioctl_get_fd_info (fd, &diw) != 0)
    return -1;

  if ((diw & 0x0080u) != 0)
    {					/* character device */
      buf->st_mode = S_IFCHR | S_IRWXU | S_IRWXG | S_IRWXO;
      buf->st_rdev = diw;		/* just stash the whole device
					   information word */
    }
  else
    {					/* regular file */
      if (dos_lseek (fd, (off_t) 0, 1, &save_offset) != 0
	  || dos_lseek (fd, (off_t) 0, 2, &eof_offset) != 0)
	return -1;			/* if we cannot get the file size,
					   return with an error rather than
					   silently returning a 0 file size */

      dos_lseek (fd, save_offset, 0, NULL);
      buf->st_size = eof_offset;

      buf->st_mode = S_IFREG | S_IRWXU | S_IRWXG | S_IRWXO;
      buf->st_dev = diw & 0x3fu;
    }

  buf->st_mtime = buf->st_atime = buf->st_ctime = dos_get_fd_mtime (fd);
  buf->st_nlink = 1;
  return 0;
}
