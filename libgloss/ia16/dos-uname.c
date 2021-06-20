/* dos-uname.c return system information
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

/*
 * This uname (.) implementation works similarly to DJGPP's uname (.) (as
 * described at www.delorie.com/djgpp/doc/libc-2.02/libc_706.html), but with
 * some improvements.  For example, the .release[] field gives not only the
 * MS-DOS minor version number, but also includes a FreeDOS-style kernel
 * version string if that is present.
 */

#include <errno.h>
#include <string.h>
#include <sys/utsname.h>
#include "pmode.h"
#include "hw.h"

#ifndef FP_SEG
#define FP_SEG(x) \
  __builtin_ia16_selector ((unsigned)((unsigned long)(void __far *)(x) >> 16))
#endif
#ifndef FP_OFF
#define FP_OFF(x) ((unsigned) (unsigned long) (void __far *) (x))
#endif

extern unsigned __ia16_get_hw_cpu (void);
extern __attribute__ ((regparmcall)) int __msdos_get_kern_ver_str
					 (char *, size_t);

static void
get_machine (struct utsname *unm)
{
  unsigned hw = __ia16_get_hw_cpu ();
  switch (hw)
    {
    default:
      strcpy (unm->machine, "i86");
      break;
    case HW_I186:
      strcpy (unm->machine, "i186");
      break;
    case HW_V20:
      strcpy (unm->machine, "necv20");
      break;
    case HW_I286:
      strcpy (unm->machine, "i286");
    }
}

static void
get_nodename (struct utsname *unm)
{
  int carry, cx;
  size_t len;

  memset (unm->nodename, 0, sizeof unm->nodename);

  /* Get the machine's network name using a sycall. */
  __asm volatile (RMODE_DOS_CALL_ "; sbbw %0, %0"
		  : "=a" (carry), "=c" (cx)
		  : "0" (0x5e00U),
		    "Rds" (FP_SEG (unm->nodename)),
		    "d" (FP_OFF (unm->nodename))
		  : "memory", "bx", "es", "di", "cc");

  /*
   * If the call failed, or the call said that the name is invalid, return a
   * default name.
   */
  if (carry || (cx >> 8) == 0)
    {
      strcpy (unm->nodename, "pc");
      return;
    }

  /* Otherwise, remove trailing spaces from the name. */
  len = strlen (unm->nodename);
  while (len != 0 && unm->nodename[len - 1] == ' ')
    --len;

  if (! len)
    strcpy (unm->nodename, "pc");
  else
    unm->nodename[len] = 0;
}

static void
get_release_version_sysname (struct utsname *unm)
{
  static char unknown_oem_prefix[6] = "?MSOEM";
  static char digit[16] = "0123456789abcdef";
  unsigned char major, minor, oem, al, bh, bl, carry;
  unsigned bx;

  __asm volatile ("int $0x21"
		  : "=Rah" (minor), "=Ral" (major), "=b" (oem)
		  : "a" (0x3000U)
		  : "cc", "bl", "cx", "dx");

  __asm volatile ("int $0x21; sbbb %2, %2"
		  : "=Ral" (al), "=b" (bx), "=r" (carry)
		  : "a" (0x3306U), "1" (0U)
		  : "cc", "dx");
  if (! carry && al != 0xff)
    {
      bh = bx >> 8;
      bl = (unsigned char) bx;
      if (bh < 100 && bl >= 5)
	{
	  major = bl;
	  minor = bh;
	}
    }

  switch (oem)
    {
    case 0x00:
      strcpy (unm->sysname, "IBMPcDos");
      break;
    case 0x01:
      strcpy (unm->sysname, "CompqDOS");
      break;
    case 0x02:
      strcpy (unm->sysname, "MsoftDOS");
      break;
    case 0x04:
      strcpy (unm->sysname, "AT&T DOS");
      break;
    case 0x05:
      strcpy (unm->sysname, "ZenitDOS");
      break;
    case 0x06:
      strcpy (unm->sysname, "HP DOS");
      break;
    case 0x07:
      strcpy (unm->sysname, "GrBulDOS");
      break;
    case 0x08:
      strcpy (unm->sysname, "TandnDOS");
      break;
    case 0x09:
      strcpy (unm->sysname, "AST DOS");
      break;
    case 0x0a:
      strcpy (unm->sysname, "AsemDOS");
      break;
    case 0x0b:
      strcpy (unm->sysname, "HntrxDOS");
      break;
    case 0x0c:
      strcpy (unm->sysname, "SysLnDOS");
      break;
    case 0x0d:
      strcpy (unm->sysname, "PBellDOS");
      break;
    case 0x0e:
      strcpy (unm->sysname, "IcompDOS");
      break;
    case 0x0f:
      strcpy (unm->sysname, "UnibtDOS");
      break;
    case 0x10:
      strcpy (unm->sysname, "UnidtDOS");
      break;
    case 0x16:
      strcpy (unm->sysname, "DEC DOS");
      break;
    case 0x17:
      strcpy (unm->sysname, "OlivtDOS");
      break;
    case 0x28:
      strcpy (unm->sysname, "TI DOS");
      break;
    case 0x29:
      strcpy (unm->sysname, "Toshiba");
      break;
    case 0x33:
      strcpy (unm->sysname, "NWin3Dev");
      break;
    case 0x34:
    case 0x35:
      strcpy (unm->sysname, "MSWinDev");
      break;
    case 0x4d:
      strcpy (unm->sysname, "HP DOS");
      break;
    case 0x5e:
      strcpy (unm->sysname, "RxDOS");
      break;
    case 0x66:
      strcpy (unm->sysname, "PTS-DOS");
      break;
    case 0x99:
      strcpy (unm->sysname, "GenSoft");
      break;
    case 0xcd:
      strcpy (unm->sysname, "SrcDOS");
      break;
    case 0xee:
      strcpy (unm->sysname, "DR-DOS");
      break;
    case 0xef:
      strcpy (unm->sysname, "NovelDOS");
      break;
    case 0xfd:
      strcpy (unm->sysname, "FreeDOS");
      break;
    case 0xff:
      strcpy (unm->sysname, "MS-DOS");
      break;
    default:
      memcpy (unm->sysname, unknown_oem_prefix, 6);
      unm->sysname[6] = digit[oem >> 4];
      unm->sysname[7] = digit[oem & 0xf];
    }

  if (major <= 9)
    {
      unm->release[0] = digit[major];
      unm->release[1] = 0;
    }
  else if (major <= 99)
    {
      unm->release[0] = digit[major / 10];
      unm->release[1] = digit[major % 10];
      unm->release[2] = 0;
    }
  else
    {
      unm->release[2] = digit[major % 10];
      major /= 10;
      unm->release[0] = digit[major / 10];
      unm->release[1] = digit[major % 10];
      unm->release[3] = 0;
    }

  if (minor <= 99)
    {
      unm->version[0] = digit[minor / 10];
      unm->version[1] = digit[minor % 10];
      if (__msdos_get_kern_ver_str (unm->version + 4,
				    sizeof unm->version - 4) != 0)
	unm->version[2] = 0;
      else
	{
	  unm->version[2] = ';';
	  unm->version[3] = ' ';
	}
    }
  else
    {
      unm->version[2] = digit[minor % 10];
      minor /= 10;
      unm->version[0] = digit[minor / 10];
      unm->version[1] = digit[minor % 10];
      if (__msdos_get_kern_ver_str (unm->version + 5,
				    sizeof unm->version - 5) != 0)
	unm->version[3] = 0;
      else
	{
	  unm->version[3] = ';';
	  unm->version[4] = ' ';
	}
    }
}

int
uname (struct utsname *unm)
{
  if (! unm)
    {
      errno = EFAULT;
      return -1;
    }

  get_machine (unm);
  get_nodename (unm);
  get_release_version_sysname (unm);
  return 0;
}
