/* Startup code for ELKS systems.  */

#include "elks-syscalls.h"

	.arch	i8086
	.code16

/* We're started with a stack that looks like this:
	0
	envp[n-1]
	...
	envp[0]
	0
	argv[argc-1]
	...
	argv[0]
	argc  */

	.section .startupA

	.global	_start
_start:

	.section .startupB

	popw	%di		# Get argc.
	movw	%sp, %bx	# Get argv.
	leaw	(%bx,%di),%bp
	leaw	2(%bp,%di),%cx	# Envp = %bx + %di + %di + 2.
#ifndef __IA16_CALLCVT_REGPARMCALL
	pushw	%cx
	pushw	%bx
	pushw	%di
#else
	xchgw	%ax, %di
	movw	%bx, %dx
#endif
	call	main
#ifndef __IA16_CALLCVT_REGPARMCALL
	pushw	%ax
#endif
	call	exit

	.global	_exit
_exit:
/* Call .fini destructors here.  FIXME: this means that _exit (.) is not the
   same as just the syscall --- is this a good idea?  -- tkchia 20190414  */
#ifdef __IA16_CALLCVT_REGPARMCALL
	xchgw	%ax, %si
#endif

	.section .startupC

#ifndef __IA16_CALLCVT_REGPARMCALL
	popw	%bx
	popw	%bx
#else
	movw	%si, %bx
#endif
	movw	$__NR_exit, %ax
	int	$0x80
