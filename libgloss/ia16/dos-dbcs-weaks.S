/*
 * Copyright (c) 2021--2022 TK Chia
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

	TEXT_ (dos_dbcs_weaks.S.LIBGLOSS)

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

	.lcomm	.Ldos2, 1
