#include "call-cvt.h"

#define P(x, y, z)	PP (x, y, z)
#define PP(x, y, z)	x ## y ## z

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (autofloat_stdio.S.LIBGLOSS)
	.global	P (H, , T)
	.type	P (H, , T), @function
P (H, , T):
	jmp	P (H, , T.impl)		/* note: near jmp */
