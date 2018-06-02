#include <_ansi.h>
#include <reent.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/time.h>
#include "local.h"

#define sscanf siscanf	/* avoid to pull in FP functions. */

static char __tzname_std[11];
static char __tzname_dst[11];
static char *prev_tzenv = NULL;

static size_t
scan_tzname (const char *tzenv, char *tzname)
{
  size_t n = strcspn (tzenv, "0123456789,+-");

  if (n > 10)
    return 0;

  memcpy (tzname, tzenv, n);
  tzname[n] = 0;

  return n;
}

static size_t
scan_tzoffset (const char *tzenv, char delim, unsigned short *pa,
	       unsigned short *pb, unsigned short *pc)
{
  char *p;
  size_t n;

  *pb = *pc = 0;

  *pa = strtoul (tzenv, &p, 10);
  if (p == tzenv)
    return 0;

  n = p - tzenv;
  tzenv = p;
  if (*p != delim)
    return n;

  tzenv = p + 1;
  *pb = strtoul (tzenv, &p, 10);
  if (p == tzenv)
    return n;

  n += 1 + p - tzenv;
  tzenv = p;
  if (*p != delim)
    return n;

  tzenv = p + 1;
  *pc = strtoul (tzenv, &p, 10);
  if (p != tzenv)
    n += 1 + p - tzenv;

  return n;
}

void
_tzset_unlocked_r (struct _reent *reent_ptr)
{
  char *tzenv;
  unsigned short hh, mm, ss, m, w, d;
  int sign, n;
  int i, ch;
  __tzinfo_type *tz = __gettzinfo ();

  if ((tzenv = _getenv_r (reent_ptr, "TZ")) == NULL)
      {
	_timezone = 0;
	_daylight = 0;
	_tzname[0] = "GMT";
	_tzname[1] = "GMT";
	free(prev_tzenv);
	prev_tzenv = NULL;
	return;
      }

  if (prev_tzenv != NULL && strcmp(tzenv, prev_tzenv) == 0)
    return;

  free(prev_tzenv);
  prev_tzenv = _malloc_r (reent_ptr, strlen(tzenv) + 1);
  if (prev_tzenv != NULL)
    strcpy (prev_tzenv, tzenv);

  /* ignore implementation-specific format specifier */
  if (*tzenv == ':')
    ++tzenv;  

  n = scan_tzname (tzenv, __tzname_std);
  if (! n)
    return;
 
  tzenv += n;

  sign = 1;
  if (*tzenv == '-')
    {
      sign = -1;
      ++tzenv;
    }
  else if (*tzenv == '+')
    ++tzenv;

  n = scan_tzoffset (tzenv, ':', &hh, &mm, &ss);
  if (! n)
    return;
  
  tz->__tzrule[0].offset = sign * (ss + SECSPERMIN * mm + SECSPERHOUR * hh);
  _tzname[0] = __tzname_std;
  tzenv += n;

  n = scan_tzname (tzenv, __tzname_dst);
  if (! n)  
    { /* No dst */
      _tzname[1] = _tzname[0];
      _timezone = tz->__tzrule[0].offset;
      _daylight = 0;
      return;
    }
  else
    _tzname[1] = __tzname_dst;

  tzenv += n;

  /* otherwise we have a dst name, look for the offset */
  sign = 1;
  if (*tzenv == '-')
    {
      sign = -1;
      ++tzenv;
    }
  else if (*tzenv == '+')
    ++tzenv;

  n = scan_tzoffset (tzenv, ':', &hh, &mm, &ss);
  if (! n)
    tz->__tzrule[1].offset = tz->__tzrule[0].offset - 3600;
  else
    tz->__tzrule[1].offset = sign * (ss + SECSPERMIN * mm + SECSPERHOUR * hh);

  tzenv += n;

  for (i = 0; i < 2; ++i)
    {
      if (*tzenv == ',')
        ++tzenv;

      if (*tzenv == 'M')
	{
	  ++tzenv;
	  n = scan_tzoffset (tzenv, '.', &m, &w, &d);
	  if (! n || m < 1 || m > 12 || w < 1 || w > 5 || d > 6)
	    return;
	  
	  tz->__tzrule[i].ch = 'M';
	  tz->__tzrule[i].m = m;
	  tz->__tzrule[i].n = w;
	  tz->__tzrule[i].d = d;
	  
	  tzenv += n;
	}
      else 
	{
	  char *end;
	  if (*tzenv == 'J')
	    {
	      ch = 'J';
	      ++tzenv;
	    }
	  else
	    ch = 'D';
	  
	  d = strtoul (tzenv, &end, 10);
	  
	  /* if unspecified, default to US settings */
	  /* From 1987-2006, US was M4.1.0,M10.5.0, but starting in 2007 is
	   * M3.2.0,M11.1.0 (2nd Sunday March through 1st Sunday November)  */
	  if (end == tzenv)
	    {
	      if (i == 0)
		{
		  tz->__tzrule[0].ch = 'M';
		  tz->__tzrule[0].m = 3;
		  tz->__tzrule[0].n = 2;
		  tz->__tzrule[0].d = 0;
		}
	      else
		{
		  tz->__tzrule[1].ch = 'M';
		  tz->__tzrule[1].m = 11;
		  tz->__tzrule[1].n = 1;
		  tz->__tzrule[1].d = 0;
		}
	    }
	  else
	    {
	      tz->__tzrule[i].ch = ch;
	      tz->__tzrule[i].d = d;
	    }
	  
	  tzenv = end;
	}
      
      /* default time is 02:00:00 am */
      hh = 2;
      mm = 0;
      ss = 0;
      n = 0;
      
      if (*tzenv == '/')
	{
	  ++tzenv;
	  n = scan_tzoffset (tzenv, ':', &hh, &mm, &ss);
	}

      tz->__tzrule[i].s = ss + SECSPERMIN * mm + SECSPERHOUR  * hh;
      
      tzenv += n;
    }

  __tzcalc_limits (tz->__tzyear);
  _timezone = tz->__tzrule[0].offset;  
  _daylight = tz->__tzrule[0].offset != tz->__tzrule[1].offset;
}

void
_tzset_r (struct _reent *reent_ptr)
{
  TZ_LOCK;
  _tzset_unlocked_r (reent_ptr);
  TZ_UNLOCK;
}
