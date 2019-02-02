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
  /* Small static lookup table to quickly convert a packed <year, month>
     returned by DOS to a value which can be scaled to a time_t.  */
  static const unsigned packed_ym_to_day[] = {
    3620u, 3651u, 3682u, 3711u, 3742u, 3772u, 3803u, 3833u,
    3864u, 3895u, 3925u, 3956u, 3986u, 4017u, 4048u, 4076u,
    3986u, 4017u, 4048u, 4076u, 4107u, 4137u, 4168u, 4198u,
    4229u, 4260u, 4290u, 4321u, 4351u, 4382u, 4413u, 4441u,
    4351u, 4382u, 4413u, 4441u, 4472u, 4502u, 4533u, 4563u,
    4594u, 4625u, 4655u, 4686u, 4716u, 4747u, 4778u, 4806u,
    4716u, 4747u, 4778u, 4806u, 4837u, 4867u, 4898u, 4928u,
    4959u, 4990u, 5020u, 5051u, 5081u, 5112u, 5143u, 5172u
  };
  /* Another small static lookup table to convert an hour count to a scaled
     second count.  */
  static const unsigned hour_to_scaled_sec[] = {
	0u,  1800u,  3600u,  5400u,  7200u,  9000u, 10800u, 12600u,
    14400u, 16200u, 18000u, 19800u, 21600u, 23400u, 25200u, 27000u,
    28800u, 30600u, 32400u, 34200u, 36000u, 37800u, 39600u, 41400u,
    43200u, 45000u, 46800u, 48600u, 50400u, 52200u, 54000u, 55800u
  };

  int ret, carry;
  unsigned cx, dx, ym, mday, hour, min, sec;
  time_t t;

  asm volatile ("int $0x21; sbbw %0, %0"
		: "=r" (carry), "=a" (ret), "=c" (cx), "=d" (dx)
		: "1" (0x5700u), "b" (fd)
		: "cc");
  if (carry)
    {
      errno = ret;
      return carry;
    }

  /* Convert the packed date and time to a "localized" time_t value.  */
  ym = dx >> 5;
  hour = cx >> 11;
  min = (cx >> 5) & 0x3fu;
  sec = (cx & 0x1fu) * 2;
  mday = dx & 0x1fu;
  t = packed_ym_to_day[ym % 0x40u];
  t += (time_t) (365 + 365 + 365 + 366) * (ym / 0x40u);
  t += mday;
  /* (Adjust for the year 2100, which is not a leap year...)  */
  if (dx >= 0xf060u)
    --t;
  t *= (time_t) 86400;
  /* And...  */
  t += (time_t) 2 * hour_to_scaled_sec[hour];
  t += (time_t) 60 * min;
  t += sec;

  /* Adjust to a UTC time value using time zone settings.  */
  tzset ();
  t += _timezone;
  return t;
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
