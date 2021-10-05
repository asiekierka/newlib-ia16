#include "call-cvt.h"
#include "pmode.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (dos_readr.S.LIBGLOSS)
	.global		_read_r
_read_r:
	ENTER_BX_(8)
	pushw	ARG0W_BX_
#ifdef __IA16_CALLCVT_REGPARMCALL
	MOV_ARG2W_BX_CLOBBER_(%ax)
	MOV_ARG4W_BX_(%dx)
	MOV_ARG6W_BX_(%cx)
	xchgw	%ax,	%bx
#else
	MOV_ARG4W_BX_(%dx)
	MOV_ARG6W_BX_(%cx)
	MOV_ARG2W_BX_(%bx)
#endif
	movb	$0x3f,	%ah
	RMODE_DOS_CALL_
	popw	%bx
	jnc	.noerror
	movw	%ax,	(%bx)
	movw	$-1,	%ax
.noerror:
	RET_(8)
