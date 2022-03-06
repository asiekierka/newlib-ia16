#include "call-cvt.h"

	.arch	i8086, jumps
	.code16
	.att_syntax prefix

	.irp	func, sscanf fscanf scanf vscanf vfscanf vsscanf
	.weak	__ia16_have_scanf_float.\func\().v2
	.set	__ia16_have_scanf_float.\func\().v2, 0
	.weak	__ia16_have_scanf_float._\func\()_r.v2
	.set	__ia16_have_scanf_float._\func\()_r.v2, 0
	.endr

	TEXT_ (autofloat_stdio.S.LIBGLOSS)

	.reloc	., R_386_NONE, _scanf_float
