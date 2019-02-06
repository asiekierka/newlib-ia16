/*
 * Copyright (c) 2019 TK Chia
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

#ifndef _SYS_DIRENT_H
#define _SYS_DIRENT_H

#include <machine/types.h>

#ifdef __cplusplus
extern "C"
{
#endif

#ifdef __MSDOS__
/* MS-DOS target platform.  Follow DOS's FindFirst/FindNext structure, but
   allow .d_name[] to hold a long filename, in case we decide to implement
   LFN support later.  */
# ifndef MAXNAMLEN
#   define MAXNAMLEN 259
# endif
struct dirent
{
  unsigned char d_dta[21];
  unsigned char d_attr;
  unsigned short d_time;
  unsigned short d_date;
  long d_size;
  char d_name[MAXNAMLEN + 1];
};
typedef struct __msdos_DIR DIR;
#elif defined __ELKS__
/* ELKS target platform.  The definitions here follow those in the ELKS
   source tree.  */
# ifndef MAXNAMLEN
#   define MAXNAMLEN 255
# endif
struct dirent
{
  long d_ino;
  __off_t d_off;
  unsigned short d_reclen;
  char d_name[MAXNAMLEN + 1];
};
typedef struct __elks_DIR DIR;
#else
/* ?!?!? */
# error "<dirent.h> not supported"
#endif

/* FIXME: implement these!  */
extern DIR *opendir (const char *);
extern struct dirent *readdir (DIR *);
extern int closedir (DIR *);

#ifdef __cplusplus
}
#endif

#endif /* _SYS_DIRENT_H */
