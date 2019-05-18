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

/*
 * Invoke the near routine pointed to by %bx, in real or V86 mode.  The
 * routine should accept arguments and pass return values --- if any ---
 * through %ax, %dx, and/or %cx.
 *
 * This is used by the _times (.) implementation (dos-times.S) to run its
 * constructor and destructor routines in real mode.
 */

	.arch	i286, jumps
	.code16

	.text
	.global	__ia16_rmode_func_call_bx
__ia16_rmode_func_call_bx:
	pushw	%di
	movw	__ia16_dpmi_rmode_ds, %di
	test	%di,	%di
	jnz	0f
	popw	%di
	jmpw	*%bx
0:
	pushw	%es			/* save %es */
	pushw	%ss
	popw	%es
	pushw	%di			/* %ss */
	pushw	$rmode_stack		/* %sp */
	pushw	__ia16_dpmi_rmode_cs	/* %cs */
	pushw	$.Lthunk		/* %ip */
	subw	$4,	%sp		/* %gs, %fs */
	pushw	%di			/* %ds */
	pushw	%di			/* %es */
	pushfw				/* flags */
	pushw	%ax			/* %ax/%eax */
	pushw	%ax
	pushw	%cx			/* %cx/%ecx */
	pushw	%cx
	pushw	%dx			/* %dx/%edx */
	pushw	%dx
	pushw	%bx			/* %bx/%ebx */
	pushw	%bx
	subw	$0x10,	%sp		/* ... */
	movw	$0x0301, %ax
	movb	$0x00,	%bh
	xorw	%cx,	%cx
	movw	%sp,	%di
	int	$0x31
	movw	%sp,	%bx
	jc	1f
	addw	$0x14,	%sp		/* ... */
	popw	%dx			/* %dx/%edx */
	popw	%ax
	popw	%cx			/* %cx/%ecx */
	popw	%ax
	popw	%ax			/* %ax/%eax */
	addw	$0x14,	%sp		/* ... */
	popw	%es			/* restore %es */
	popw	%di			/* restore %di */
	ret
1:
	call	abort

.Lthunk:
	callw	*%bx
	lretw

	.bss
	.skip	128
rmode_stack:
