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
 * Invoke real/V86-mode interrupt 0x21 with %ds pointing to our data
 * segment.  %ds should already be pointing to the data segment, whether in
 * real/V86 mode or protected mode.
 *
 * If in addition %es == %ds, then %es will also point to the data segment
 * for the call.
 *
 * This is basically just an `int $0x21' outside of protected mode, but
 * needs to go through interrupt 0x31 when in DPMI.
 */

	.arch	i286, jumps
	.code16

	.text
	.global	__ia16_rmode_dos_call
__ia16_rmode_dos_call:
	pushw	%di
	movw	__ia16_dpmi_rmode_ds, %di
	test	%di,	%di
	jnz	0f
	popw	%di
	int	$0x21
	ret
0:
	pushw	%es			/* save %es */
	pushw	$0			/* blank %ss */
	pushw	$0			/* blank %sp */
	subw	$8,	%sp		/* %cs, %ip, %gs, %fs */
	pushw	%di			/* %ds */
	pushw	%di			/* %es */
	movw	%sp,	%di		/* fish out caller's %di */
	movw	0x12(%di), %di
	pushfw				/* flags */
	pushw	%ax			/* %ax/%eax */
	pushw	%ax
	pushw	%cx			/* %cx/%ecx */
	pushw	%cx
	pushw	%dx			/* %dx/%edx */
	pushw	%dx
	pushw	%bx			/* %bx/%ebx */
	pushw	%bx
	xorw	%cx,	%cx
	pushw	%cx			/* reserved */
	pushw	%cx
	pushw	%bp			/* %bp/%ebp */
	pushw	%bp
	pushw	%si			/* %si/%esi */
	pushw	%si
	pushw	%di			/* %di/%edi */
	pushw	%di
	movw	$0x0300, %ax
	movw	$0x0021, %bx
	movw	%sp,	%di
	int	$0x31			/* %cx == 0 here :) */
	movw	%sp,	%bx
	jc	1f
	popw	%di			/* %di/%edi */
	popw	%ax
	popw	%si			/* %si/%esi */
	popw	%ax
	popw	%bp			/* %bp/%ebp */
	popw	%ax
	popw	%ax			/* reserved */
	popw	%ax
	popw	0x30(%bx)		/* %bx/%ebx --- stash in %ss slot */
	popw	%ax
	popw	%dx			/* %dx/%edx */
	popw	%ax
	popw	%cx			/* %cx/%ecx */
	popw	%ax
	popw	0x34(%bx)		/* %ax/%eax --- stash in orig. %di */
	popw	%ax
	popw	%ax			/* flags */
	addw	$0xe,	%sp		/* %es, %ds, %fs, %gs, %ip, %cs, %ss */
	popw	%bx			/* get returned %bx */
	movb	%al,	%ah		/* get flags */
	sahf
	popw	%es			/* restore %es */
	popw	%ax			/* get returned %ax */
	ret				/* and we are done */
1:
	call	abort
