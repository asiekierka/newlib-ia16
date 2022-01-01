/*
 * Copyright (c) 2019--2021 TK Chia
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
 * Implementation of -mhandle-non-i286 for the tiny memory model.  This works
 * in conjunction with libck186.a.
 */

	.arch	i8086, nojumps
	.code16

	.section .msdos_init.handle_non_i286, "ax"

	/*
	 * Do a quick check that we are indeed dealing with a 286+.  On
	 * pre-286's, `pushw %sp' decrements %sp before storing its value,
	 * while on 286+, `pushw %sp' stores the old value of %sp first.
	 * (See Hamarsoft's 86BUGS, distributed with RBIL.)
	 */
	pushw	%sp
	popw	%ax
	subw	%sp,	%ax
	movw	$1f,	%dx
	jnz	__msdos_crt_bail

	.section .msdos_init_rodata, "a"

1:	.ascii	"No 286+$"

	.globl	__msdos_handle_non_i286
	.set	__msdos_handle_non_i286, 1
