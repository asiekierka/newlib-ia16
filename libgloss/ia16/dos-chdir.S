#include "call-cvt.h"
#include "pmode.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (dos_chdir.S.LIBGLOSS)
	.global	chdir
chdir:
	ENTER_BX_(2)
	MOV_ARG0W_BX_(%dx)
	movb	$0x3b,	%ah
	RMODE_DOS_CALL_
	jc	.error
	xorw	%ax,	%ax
	RET_(2)
.error:
	movw	_impure_ptr, %bx
	movw	%ax,	(%bx)
	movw	$-1,	%ax
	RET_(2)
