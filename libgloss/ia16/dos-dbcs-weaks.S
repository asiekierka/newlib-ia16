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

#include "call-cvt.h"

	.arch	i8086, jumps
	.code16

	.section .msdos_init.dbcs, "ax"

	/*
	 * At this point %bp should contain 0 iff we are running under MS-DOS
	 * 2.x.
	 *
	 * According to Ralf Brown's Interrupt List, int 0x21 with %ax =
	 * 0x6600 returns with CF set on error under DOS 2.x, but on DOS 3+
	 * indicates an error by setting %al = 0xff.
	 */
	testw	%bp,	%bp
	jnz	0f
	incb	.Ldos2
0:

	.text

/*
 * Return a far pointer to the currently active double-byte character set
 * (DBCS) lead byte table.  If there is no lead byte table or the table is
 * empty, return 0:0.
 *
 * The routine name _dos_get_dbcs_lead_table () comes from Open Watcom's
 * library internal interfaces.
 */
	.weak	_dos_get_dbcs_lead_table
_dos_get_dbcs_lead_table:
#ifdef __IA16_FEATURE_PROTECTED_MODE
	call	__DPMI_hosted
	incw	%ax
	jz	10f
	movw	$10f,	%bx
	call	__ia16_rmode_func_call_bx
	/*
	 * We get a real mode far pointer in %dx:%ax.  If %dx == %ax == 0,
	 * this is an invalid table; return immediately.
	 */
	movw	%ax,	%bx
	orw	%dx,	%bx
	jz	8f
	/*
	 * Ugh.  We need to allocate an LDT descriptor for the lead byte
	 * table's segment.
	 */
	pushw	%ax
	xorw	%ax,	%ax		/* allocate descriptor(s): %ax := 0 */
	movw	$1,	%cx
	int	$0x31
	jc	9f
	xchgw	%ax,	%bx
	pushw	%es
	pushw	%di
	pushw	%ss
	popw	%es
	movw	$0x000b, %ax		/* get descriptor: %ax := 0x000b */
	subw	$8,	%sp
	movw	%sp,	%di
	int	$0x31
	jc	9f
	movw	$0xffff, (%di)		/* change limit to 0xffff */
	movb	$4,	%cl
	rolw	%cl,	%dx
	movw	%dx,	%cx
	andb	$-16,	%dl
	xorb	%dl,	%cl		/* %cl:%dx now gives segment base */
	movw	%dx,	2(%di)		/* fill in segment base */
	movb	%cl,	4(%di)
					/* make segment non-executable,
					   read-only, 16-bit, expand-up */
	andw	$0b0011000011110001, 5(%di)
	incw	%ax			/* set descriptor: %ax := 0x000c */
	int	$0x31
	jc	9f
	addw	$8,	%sp
	popw	%di
	popw	%es
	popw	%ax
	movw	%bx,	%dx
8:
	RET_ (0)
9:
	call	abort
10:
#endif
	pushw	%bp
	pushw	%si
	pushw	%di
	pushw	%ds
	pushw	%es
	movw	$0x6300, %ax
	movw	$-1,	%si
	testb	.Ldos2, %ah
	jnz	18f
	int	$0x21
11:
	incw	%si
	jz	19f
	decw	%si
	testb	%al,	%al
	jnz	19f
	cmpb	%al,	(%si)
	jz	19f
	xchgw	%ax,	%si
	movw	%ds,	%dx
12:
	popw	%es
	popw	%ds
	popw	%di
	popw	%si
	popw	%bp
	RET_ (0)
18:
	stc
	int	$0x21
	sbbb	%al,	%al
	jmp	11b
19:
	xorw	%ax,	%ax
	cwtd
	jmp	12b

	TEXT_ (dos_dbcs_weaks.S.LIBGLOSS)

#ifdef __IA16_FEATURE_PROTECTED_MODE
/* Free any DPMI resources allocated by _dos_get_dbcs_lead_table (). */
	.weak	_dos_free_dbcs_lead_table
_dos_free_dbcs_lead_table:
	ENTER_BX_ (4)
	MOV_ARG2W_BX_ (%bx)
	testw	%bx,	%bx
	jz	39f
	pushw	%bx
	call	__DPMI_hosted
	popw	%bx
	incw	%ax
	jz	39f
	movw	$0x0001, %ax
	int	$0x31
39:
	RET_ (4)
#endif

	.lcomm	.Ldos2, 1
