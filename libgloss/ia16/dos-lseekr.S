#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (dos_lseekr.S.LIBGLOSS)
	.global		_lseek_r
_lseek_r:
	ENTER2_BX_(10)
	pushw	ARG0W_BX_
#ifdef __IA16_CALLCVT_REGPARMCALL
	MOV_ARG6W2_BX_(%cx)
	MOV_ARG8B2_BX_(%al)
	MOV_ARG4W2_BX_(%bx)
	xchgw	%dx,	%bx
#else
	MOV_ARG6W2_BX_(%cx)
	MOV_ARG4W2_BX_(%dx)
	MOV_ARG8B2_BX_(%al)
	MOV_ARG2W_BX_(%bx)
#endif
	movb	$0x42,	%ah
	int	$0x21
	popw	%bx
	jnc	.noerror
	movw	%ax,	(%bx)
	sbbw	%ax,	%ax
	cwd
.noerror:
	RET2_(10)
