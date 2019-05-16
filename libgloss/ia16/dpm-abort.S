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

/* Implementation of abort () for MS-DOS and either the tiny or small memory
   model.  This implementation tries to work properly even if %ss is wrong,
   and even when running under DPMI.  */

	.arch	i8086, jumps
	.code16

	.text
	.balign	2
0:
	.hword	0
	.global	abort
abort:
	pushfw
	cli
	pushw	%ds
	movw	%cs:0b,	%ds
	popw	abort_stack-8
	popw	abort_stack-2
	movw	%sp,	abort_stack-4
	movw	%ss,	abort_stack-6
	movw	%ds,	%sp
	movw	%sp,	%ss
	movw	$abort_stack-8, %sp
	pushw	%es
	pushw	%cs
	pushw	%di
	pushw	%si
	pushw	%bp
	pushw	%dx
	pushw	%cx
	pushw	%bx
	pushw	%ax
	cld
	sti
	call	__ia16_abort_impl

.Lctor_abort:
	call	__DPMI_hosted
	decw	%ax
	jz	1f
	movw	%ss,	%cs:0b
	ret
1:
	/* Oh well.  Patch the text segment the hard way...  */
	movb	$0x0a,	%al		/* %ah == 0 */
	movw	%cs,	%bx
	int	$0x31
	jc	9f
	movw	%ax,	%ds
	movw	%ss,	0b
	xchgw	%ax,	%bx
	pushw	%ss
	popw	%ds
	movw	$0x0001, %ax
	int	$0x31
9:
	ret

	.section .ctors.65535

	.balign	2
	.hword	.Lctor_abort

	.bss
	.skip	128
abort_stack:
