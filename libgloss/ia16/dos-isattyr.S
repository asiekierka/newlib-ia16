#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (dos_isattyr.S.LIBGLOSS)
	.global		_isatty_r
_isatty_r:
	ENTER_BX_(4)
	pushw	ARG0W_BX_
	MOV_ARG2W_BX_(%bx)
	movw	$0x4400,	%ax
	int	$0x21
	popw	%bx
	jc	.error
	movw	$0x112,	%ax	# ENOTTY
	testb	$0x80,	%dl
	jz	.error
	movw	$1,	%ax
	RET_(4)
.error:
	movw	%ax,	(%bx)
	xorw	%ax,	%ax
	RET_(4)
