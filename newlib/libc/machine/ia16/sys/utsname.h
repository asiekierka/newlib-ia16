/*
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

#ifndef _SYS_UTSNAME_H_
#define _SYS_UTSNAME_H_

/*
 * In an effort to make this uname (.) implementation semi-extensible ---
 * seeing that Linux has no less than 3 different versions of the uname
 * syscall (!) --- I am implementing a simple redirection scheme, such that
 * uname (.) is internally renamed to something that encodes the lengths of
 * the `struct utsname' fields, e.g. __ia16_uname_m9_n9_r9_s9_v9 (.).
 *
 * The names given to the field lengths are taken from glibc 2.31.  The order
 * of the fields follows DJGPP.  -- tkchia
 */

#define _UTSNAME_MACHINE_LENGTH 9
#define _UTSNAME_NODENAME_LENGTH 32
#define _UTSNAME_RELEASE_LENGTH 9
#define _UTSNAME_SYSNAME_LENGTH 9
#define _UTSNAME_VERSION_LENGTH 65

struct utsname
{
  char machine[_UTSNAME_MACHINE_LENGTH];
  char nodename[_UTSNAME_NODENAME_LENGTH];
  char release[_UTSNAME_RELEASE_LENGTH];
  char sysname[_UTSNAME_SYSNAME_LENGTH];
  char version[_UTSNAME_VERSION_LENGTH];
};

#define _UNAME_STRINGIZE(__x) _UNAME_STRINGIZE_2(__x)
#define _UNAME_STRINGIZE_2(__x) #__x

extern int uname (struct utsname *)
	   __asm (_UNAME_STRINGIZE (__USER_LABEL_PREFIX__) "__ia16_uname"
		  "_m" _UNAME_STRINGIZE (_UTSNAME_MACHINE_LENGTH)
		  "_n" _UNAME_STRINGIZE (_UTSNAME_NODENAME_LENGTH)
		  "_r" _UNAME_STRINGIZE (_UTSNAME_RELEASE_LENGTH)
		  "_s" _UNAME_STRINGIZE (_UTSNAME_SYSNAME_LENGTH)
		  "_v" _UNAME_STRINGIZE (_UTSNAME_VERSION_LENGTH));

#undef _UNAME_STRINGIZE
#undef _UNAME_STRINGIZE_2

#endif  /* _SYS_UTSNAME_H_ */
