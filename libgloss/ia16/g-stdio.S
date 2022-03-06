#include "call-cvt.h"

#define P(x, y, z)	PP (x, y, z)
#define PP(x, y, z)	x ## y ## z
#define P2(w, x, y, z)	PP2 (w, x, y, z)
#define PP2(w, x, y, z)	w ## x ## y ## z

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (autofloat_stdio.S.LIBGLOSS)
	.global	P (H, , T.impl)
	.type	P (H, , T.impl), @function
P (H, , T.impl):
	JMP_ (P (H, , T.float_impl))
	.weak	P2 (__ia16_have_, A, _float.H, T.v2)
	.set	P2 (__ia16_have_, A, _float.H, T.v2), 1
