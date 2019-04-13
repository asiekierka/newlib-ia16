# Startup code for ELKS systems.

	.arch	i8086
	.code16

# We're started with a stack that looks like this:
#	0
#	envp[n-1]
#	...
#	envp[0]
#	0
#	argv[argc-1]
#	...
#	argv[0]
#	argc

	.text
	.global	_start
_start:
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
