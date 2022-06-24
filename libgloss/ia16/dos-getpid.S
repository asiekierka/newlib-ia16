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

#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

/*
 * Get the current process identifier.  For MS-DOS, use the Program Segment
 * Prefix (PSP) segment as the PID, unless the system supports an actual
 * `getpid' syscall, e.g. European MS-DOS 4.0.
 *
 * Note that pid_t may be a 32-bit type.
 */

	TEXT_ (dos_getpid.S.LIBGLOSS)
	.global	getpid
getpid:
	movb	$0x87,	%ah
	stc
	int	$0x21
	jnc	.eur_dos
	movw	_psp,	%ax
.eur_dos:
	xorw	%dx,	%dx
	RET_ (0)
