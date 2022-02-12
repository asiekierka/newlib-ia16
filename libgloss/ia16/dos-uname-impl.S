/* dos-uname-impl.S internal implementation bits for uname
 *
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
#include "hw.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (ia16_get_hw_cpu.S.LIBGLOSS)
	.global	__ia16_get_hw_cpu
__ia16_get_hw_cpu:
#if defined __IA16_FEATURE_PROTECTED_MODE
	/*
	 * If we are already running under DPMI, then the CPU is obviously
	 * a 286 or above.
	 */
#else
	xorw	%ax,	%ax
	/*
	 * Detect an NEC V20 or V30.  The opcode 0xd6 is `setalc'/`salc' on
	 * Intel CPUs, but an alias of `xlat' on NEC (according to 86bugs.lst
	 * in Ralf Brown's Interrupt List).
	 */
	pushw	%ax
	movw	%sp,	%bx
	stc
	.byte	0xd6
	popw	%bx			/* %bx := 0, used below */
	cmpb	$-1,	%al
	jnz	.v20
	/*
	 * Try to tell between an 8086/186 & a 286+: `pushw %sp' on 286+
	 * stores the %sp value before decrementing %sp, while on 8086 & 186
	 * it does the opposite.
	 */
	pushw	%sp
	popw	%ax
	cmpw	%ax,	%sp
	jz	.i286
# if ! defined _M_IX86 || _M_IX86 - 0 < 100
	/*
	 * Try to tell between an 8086 & a 186, while avoiding the use of
	 * invalid instructions.  Use the fact that a word write at offset
	 * 0xffff in a segment wraps around on an 8086 but not on a 186
	 * (www.rcollins.org/ddj/Nov96/Nov96.html).  We frob a byte that is
	 * just above our current stack top.
	 */
	movw	%ss,	%ax
	movw	%sp,	%dx
	decw	%dx
	movb	$4,	%cl
	shrw	%cl,	%dx
	addw	%dx,	%ax
	movw	%ds,	%ax
	pushfw
	cli
	movw	-1(%bx), %dx		/* %bx = 0 from above */
	decb	(%bx)
	movw	-1(%bx), %ax
	popfw
	pushw	%ss
	popw	%ds
	cmpw	%dx,	%ax
	jz	.i186
	movb	$HW_I86, %al
	.byte	0x3d
.i186:
# endif
	movb	$HW_I186, %al
	.byte	0x3d
.v20:
	movb	$HW_V20, %al
	.byte	0x3d
.i286:
#endif
	movb	$HW_I286, %al
	cbtw
	RET_ (0)

	.section .text

	.global __msdos_get_kern_ver_str
__msdos_get_kern_ver_str:
	pushw	%es
	pushw	%si
	pushw	%di
	xchgw	%ax,	%di
	movw	%dx,	%cx
	jcxz	.error
	decw	%cx
	jcxz	.error
	/*
	 * Call int 0x21, %ax = 0x33ff, with different values of %dx, to
	 * test if this syscall is actually supported.
	 */
	movw	$0x33ff, %ax
	cwtd
	clc
	int	$0x21
	jc	.error
	testw	%dx,	%dx
	jnz	.ok
	movw	$0x33ff, %ax
	movw	%ax,	%dx
	clc
	int	$0x21
	jc	.error
	testw	%dx,	%dx
	jnz	.error
.ok:
	pushw	%ss
	popw	%es
	movw	%dx,	%ds
	xchgw	%ax,	%si
.copy:
	lodsb
	stosb
	testb	%al,	%al
	loopnz	.copy
	/*
	 * Make sure the output string is 0-terminated.  At the same time
	 * set %ax := 0 for the return value.
	 */
	xorw	%ax,	%ax
	stosb
	pushw	%ss
	popw	%ds
.done:
	popw	%di
	popw	%si
	popw	%es
	RET_ (0)
.error:
	movw	$-1,	%ax
	jmp	.done
