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

/*
 * To use this file, one way is to just include it normally, e.g.
 *	#include <sys/syslimits.h>
 *
 * Alternatively, you can define __need_... macros before including this
 * file, in which case it will only define the requested macros.  E.g.
 *	#define __need_PATH_MAX
 *	#include <sys/syslimits.h>
 *
 * This is implemented using a similar technique as in GCC 6's <stddef.h>.
 */

#ifndef _PATH_MAX
# define _PATH_MAX
# define _PATH_MAX 144			/* per Open Watcom (FIXME?) */
# define _ARG_MAX	(_PATH_MAX + 128)
#endif  /* ! _PATH_MAX */

#if ! defined _SYS_SYSLIMITS_H_ \
    || defined __need_ARG_MAX || defined __need__ARG_MAX \
    || defined __need_PATH_MAX || defined __need__PATH_MAX

# if ! defined __need_ARG_MAX && ! defined __need__ARG_MAX \
     && ! defined __need_PATH_MAX && ! defined __need__PATH_MAX
#   define _SYS_SYSLIMITS_H_
# endif

# if ! defined ARG_MAX \
     && (defined __need_ARG_MAX || defined _SYS_SYSLIMITS_H_)
#   define ARG_MAX	_ARG_MAX
# endif
# undef __need_ARG_MAX
# undef __need__ARG_MAX

# if ! defined PATH_MAX \
     && (defined __need_PATH_MAX || defined _SYS_SYSLIMITS_H_)
#   define PATH_MAX	_PATH_MAX
# endif
# undef __need_PATH_MAX
# undef __need__PATH_MAX

#endif  /* ! _SYS_SYSLIMITS_H_ || __need_... */
