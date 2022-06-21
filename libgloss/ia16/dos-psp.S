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

/*
 * If the variable _psp is used, define it, & store the Program Segment
 * Prefix (PSP) segment value there.  This code snippet must run after
 * after the C startup code has cleared BSS, but before it has switched %ds
 * to point to the program's data segment.
 */

	.arch	i8086, nojumps
	.code16

	.section .msdos_initB.psp, "ax"

	movw	%ds,	%ss:_psp

	.comm	_psp, 2
