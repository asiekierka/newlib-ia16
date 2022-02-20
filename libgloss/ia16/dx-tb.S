/*
 * Copyright (c) 2022 TK Chia
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

#include <sys/syslimits.h>
#include "call-cvt.h"

	.arch	i386
	.code16

/*
 * For programs that use a DOS extender, set up a "transfer buffer" in base
 * memory for routines that need it, to allow them to communicate with real
 * or V86 mode interrupt handlers.  If we have a transfer buffer set up by
 * the CauseWay DOS extender, then use it.
 *
 * This transfer buffer is guaranteed to be at least 2 * PATH_MAX bytes in
 * size.
 */

#define MIN_TB_SZ	(2 * PATH_MAX)

	TEXT_ (dx_tb.S.LIBGLOSS)

.Lctor_dosx_tb:
	movw	$0xff25, %ax
	xorw	%bx,	%bx
	stc
	int	$0x31
	jc	5f
	testw	%bx,	%bx
	jz	5f
	cmpl	$0xfff0, %ecx		/* CauseWay APIs work, assume i386 */
	ja	0f
	movw	$0xfff0, %cx
0:
	cmpw	$(MIN_TB_SZ), %cx
	jb	5f
	movw	%bx,	__dosx_tb_rm_seg
	movw	%dx,	__dosx_tb_pm_sel
	movw	%cx,	__dosx_tb_sz
	RET_ (0)
5:
	movw	$0x0100, %ax
	movw	$(MIN_TB_SZ + 15) >> 4, %bx
	int	$0x31
	jc	9f
	movw	%ax,	__dosx_tb_rm_seg
	movw	%dx,	__dosx_tb_pm_sel
	incb	__dosx_tb_to_free
	RET_ (0)
9:
	CALL_ (abort)

.Ldtor_dosx_tb:
	testb	$1,	__dosx_tb_to_free
	jz	9f
	movw	__dosx_tb_pm_sel, %dx
	movw	$0x0101, %ax
	int	$0x31
9:
	RET_ (0)

	.section .data, "wa"

	.global	__dosx_tb_sz
__dosx_tb_sz:
	.hword	MIN_TB_SZ

	.section .ctors.65535

	.balign	2
	TEXT_PTR_ (.Lctor_dosx_tb)

	.section .dtors.65535

	.balign	2
	TEXT_PTR_ (.Ldtor_dosx_tb)

	.comm	__dosx_tb_rm_seg, 2
	.comm	__dosx_tb_pm_sel, 2
	.lcomm	__dosx_tb_to_free, 1
