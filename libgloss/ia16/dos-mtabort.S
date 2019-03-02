/*
 * Copyright (c) 2018--2019 TK Chia
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

/* Implementation of abort () for MS-DOS and the tiny memory model.  This
   implementation tries to work properly even if %ss is wrong.  */

	.arch	i8086, jumps
	.code16

	.text
	.global	abort
abort:
	pushfw
	cli
	popw	%cs:abort_stack-2
	movw	%sp,	%cs:abort_stack-4
	movw	%ss,	%cs:abort_stack-6
	movw	%cs,	%sp
	movw	%sp,	%ss
	movw	$abort_stack-6, %sp
	pushw	%ds
	pushw	%es
	pushw	%cs
	pushw	%di
	pushw	%si
	pushw	%bp
	pushw	%dx
	pushw	%cx
	pushw	%bx
	pushw	%ax
	pushw	%ss
	popw	%ds
	cld
	sti
	call	__ia16_abort_impl

	.bss
	.skip	128
abort_stack:
