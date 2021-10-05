#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (dos_closer.S.LIBGLOSS)
	.global		_close_r
_close_r:
	ENTER_BX_(4)
	pushw	ARG0W_BX_
	MOV_ARG2W_BX_(%bx)
	movb	$0x3e,	%ah
	int	$0x21
	popw	%bx
	jc	.error
	xorw	%ax,	%ax
	RET_(4)
.error:
	movw	%ax,	(%bx)
	movw	$-1,	%ax
	RET_(4)
