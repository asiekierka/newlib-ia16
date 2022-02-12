#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (dos_renamer.S.LIBGLOSS)
	.global		_rename_r
_rename_r:
	ENTER_BX_(6)
	pushw	%es
	pushw	%di
	movw	%ds,	%di
	movw	%di,	%es
	MOV_ARG4W_BX_(%di)
	MOV_ARG2W_BX_(%dx)
	MOV_ARG0W_BX_(%bx)
	movb	$0x56,	%ah
	int	$0x21
	jc	.error
	xorw	%ax,	%ax
	popw	%di
	popw	%es
	RET_(6)
.error:
	movw	%ax,	(%bx)
	sbbw	%ax,	%ax
	popw	%di
	popw	%es
	RET_(6)
