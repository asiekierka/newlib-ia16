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

extern char *__msdos_getcwd (char[PATH_MAX], unsigned char);

char *
getcwd (char *buf, size_t size)
{
  if (! buf)
    {
      char our_buf[PATH_MAX];

      if (! __msdos_getcwd (our_buf, 0))
	return NULL;

      return strdup (our_buf);
    }
  else if (size >= PATH_MAX)
    return __msdos_getcwd (buf, 0);
  else
    {
      char our_buf[PATH_MAX];
      size_t our_len;

      if (! __msdos_getcwd (our_buf, 0))
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
