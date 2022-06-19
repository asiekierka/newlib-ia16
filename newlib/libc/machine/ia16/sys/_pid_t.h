/*
 * Copyright (c) 2022 TK Chia
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

#ifndef _SYS__PID_T_H_
#define _SYS__PID_T_H_

#include <sys/_stdint.h>

/*
 * Open Watcom for MS-DOS defines pid_t to be an `int' (signed 16-bit), &
 * uses the running program's Program Segment Prefix (PSP) paragraph value
 * as the program's process identifier.
 *
 * This is potentially problematic because
 *   * the PSP may be positioned above paragraph 0x7fff in base memory; this
 *     would make the resulting pid value negative; &
 *   * POSIX assigns special meanings to negative pid values --- e.g. for
 *     the kill (, ) function.
 *
 * To address these problems, & still allow the use of PSP paragraph values
 * as process ids, make pid_t larger than 16 bits by default.
 */
#ifndef __USE_PID16
typedef __int32_t pid_t;
#else
typedef __int16_t pid_t;
#endif

#endif  /* _SYS__PID_T_H_ */
