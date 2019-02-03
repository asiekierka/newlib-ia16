/* Common code for _stat and _fstat to turn packed DOS file times to time_t's
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
#include <_syslist.h>

time_t
__msdos_cvt_file_time (unsigned ymd, unsigned hms)
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

  unsigned ym, mday, hour, min, sec;
  time_t t;

  /* Convert the packed date to a day count since a "localized" Epoch.  */
  ym = ymd >> 5;
  hour = hms >> 11;
  min = (hms >> 5) & 0x3fu;
  sec = (hms & 0x1fu) * 2;
  mday = ymd & 0x1fu;
  t = packed_ym_to_day[ym % 0x40u];
  t += (time_t) (366 + 365 + 365 + 365) * (ym / 0x40u);
  t += mday;

  /* Do a correction for the year 2100, which is not a leap year...  */
  if (ymd >= 0xf060u)
    --t;

  /* Add hours, minutes, and seconds.  */
  t *= (time_t) 86400;
  t += (time_t) 2 * hour_to_scaled_sec[hour];
  t += (time_t) 60 * min;
  t += sec;

  /* Adjust to a UTC time value using time zone settings.  */
  tzset ();
  t += _timezone;
  return t;
}
