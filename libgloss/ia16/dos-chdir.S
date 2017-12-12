#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	.section	".text"
	.global		_chdir
_chdir:
	movw	%sp,	%bx
	movw	2(%bx),	%dx
	movb	$0x3b,	%ah
	int	$0x21
	jc	.error
	xorw	%ax,	%ax
	RET_(2)
.error:
	movw	%ax,	errno
	movw	$-1,	%ax
	RET_(2)
