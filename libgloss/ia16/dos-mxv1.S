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
 * Implementation of -mmsdos-handle-v1 for the memory models other than the
 * tiny model.  This works in conjunction with libdosv1.a.
 */

	.arch	i8086, jumps
	.code16

	.section .msdos_init, "ax"

	/*
	 * At this point the flags should contain the result of comparing the
	 * DOS major version number with 2.
	 *
	 * If the MS-DOS is too old (< 2), return to the `int $0x20' command
	 * at the PSP start --- we cannot just say `int $0x20' here, as %cs
	 * is wrong.
	 */
	jnb	0f
	movb	$9,	%ah
	cwtd
	pushw	%es
	pushw	%dx
	movw	$1f,	%dx
	pushw	%ss
	popw	%ds
	int	$0x21
	lretw
0:
	/*
	 * If -mmsdos-handle-v1 is on, then the .exe header will be set to
	 * allocate the largest possible memory block to our program (see
	 * dos-mx.ld.in).  Shrink the memory block.
	 */
	movb	$0x4a,	%ah
	movw	$__msdos_initial_alloc_paras, %bx
	int	$0x21

	.section .msdos_init_rodata, "a"

1:	.ascii	"Bad DOS$"

	.globl	__msdos_handle_v1
	.set	__msdos_handle_v1, 2
