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
 * Say whether we are running under DPMI.  Return 1 if so, -1 otherwise ---
 * similar to Open Watcom's corresponding routine.
 *
 * Use the variable for the stored real mode %ds value as a quick handy way
 * to check for DPMI.  If we are in real mode, this will be zero.
 */

	.arch	i8086, jumps
	.code16

	.text
	.global	__DPMI_hosted
__DPMI_hosted:
	xorw	%ax,	%ax
	cmpw	%ax,	__ia16_dpmi_rmode_ds
	jnz	0f
	decw	%ax
	ret
0:
	incw	%ax
	ret
