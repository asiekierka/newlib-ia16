#include "call-cvt.h"

#define P(x, y, z)	PP (x, y, z)
#define PP(x, y, z)	x ## y ## z

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (i_stdio.S.LIBGLOSS)
	.global	P (H, , T)
	.type	P (H, , T), @function
P (H, , T):
	JMP_ (P (H, i, T))
