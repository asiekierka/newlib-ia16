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
 * Implementation of -mmsdos-handle-v1 for the tiny memory model.  This works
 * in conjunction with libdosv1.a.
 */

	.arch	i8086, jumps
	.code16

	.section .startupA, "ax"

	/*
	 * Sanity check for MS-DOS version >= 2.  The flags should contain
	 * the result of comparing the DOS version number with 2, & should
	 * be preserved if we want to continue execution.
	 */
	jnb	0f
	ret
0:

	.globl	__msdos_handle_v1
	.set	__msdos_handle_v1, 2
