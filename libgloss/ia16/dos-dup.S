#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	.section	".text"
	.global		dup
dup:
	movw	%sp,	%bx
	movw	2(%bx),	%bx
	movb	$0x45,	%ah
	int	$0x21
	jnc	.noerror
	movw	%ax,	errno
	sbbw	%ax,	%ax
.noerror:
	RET_(2)
