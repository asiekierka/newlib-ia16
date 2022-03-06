#include "call-cvt.h"

#define P(x, y, z)	PP (x, y, z)
#define PP(x, y, z)	x ## y ## z

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (autofloat_stdio.S.LIBGLOSS)
	.weak	P (H, , T.impl)
	.type	P (H, , T.impl), @function
P (H, , T.impl):
	JMP_ (P (H, i, T))
