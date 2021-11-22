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

	TEXT_ (dos_dbcs.S.LIBGLOSS)

/*
 * Given a character C and a lead byte table pointer, say whether C is a
 * DBCS lead byte.
 */
	.global	__msdos_dbcs_lead_byte_p
__msdos_dbcs_lead_byte_p:
	ENTER_BX_ (6)
	MOV_ARG2W_BX_ (%dx)
	MOV_ARG4W_BX_ (%cx)
	MOV_ARG0B_BX_ (%al)
	movw	%dx,	%bx
	orw	%cx,	%bx
	jnz	20f
	xchgw	%ax,	%dx
	RET_ (6)
20:
	pushw	%es
	pushw	%si
	movw	%dx,	%si
	movw	%cx,	%es
	xchgw	%ax,	%cx
21:
	lodsw	%es:(%si)
	testb	%al,	%al
	jz	29f
	cmpb	%al,	%cl
	jb	21b
	cmpb	%ah,	%cl
	ja	21b
	movb	$1,	%al
29:
	cbtw
	popw	%si
	popw	%es
	RET_ (6)
