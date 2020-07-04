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
 * Implementation of -mhandle-non-i186 for all memory models.  This works
 * in conjunction with libck086.a.
 */

	.arch	i8086, jumps
	.code16

	.section .msdos_init.handle_i186, "ax"

	/*
	 * Do a quick check that we are indeed dealing with a 186+.
	 *
	 * 0x6a is `pushw' on 186+, and as alias for 0x7a (`jpe') on the
	 * 8086 (www.os2museum.com/wp/undocumented-8086-opcodes/).
	 */
	movw	%sp,	%ax
	.byte	0x6a, 0x00
	subw	%sp,	%ax
	jnz	0f
	decw	%ax
	jmp	__msdos_crt_exit
0:
	popw	%ax

	.globl	__msdos_handle_non_i186
	.set	__msdos_handle_non_i186, 1
