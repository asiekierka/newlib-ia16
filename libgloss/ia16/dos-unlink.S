#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	.section	".text"
	.global		_unlink
_unlink:
	movw	%sp,	%bx
	movw	2(%bx),	%dx
	movb	$0x41,	%ah
	int	$0x21
	jc	.error
	xorw	%ax,	%ax
	RET_(2)
.error:
	movw	%ax,	errno
	movw	$-1,	%ax
	RET_(2)
