#include "call-cvt.h"
#include "pmode.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (dos_unlinkr.S.LIBGLOSS)
	.global		_unlink_r
_unlink_r:
	ENTER_BX_(4)
	pushw	ARG0W_BX_
	MOV_ARG2W_BX_(%dx)
	movb	$0x41,	%ah
	RMODE_DOS_CALL_
	popw	%bx
	jc	.error
	xorw	%ax,	%ax
	RET_(4)
.error:
	movw	%ax,	(%bx)
	movw	$-1,	%ax
	RET_(4)
