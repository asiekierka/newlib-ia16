#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	.section	".text"
	.global		dup2
dup2:
	movw	%sp,	%bx
	movw	4(%bx),	%cx
	movw	2(%bx),	%bx
	movb	$0x46,	%ah
	int	$0x21
	jnc	.noerror
	movw	%ax,	errno
	sbbw	%cx,	%cx
.noerror:
	movw	%cx,	%ax
	RET_(4)
