/* Startup code for
     * a "tiny" model MS-DOS .com file with combined text and data segment,
     * a "small" model MS-DOS .exe file with one text segment and one separate
       data segment, or
     * a "medium" model MS-DOS .exe file with multiple text segments and one
       data segment.  */

#if !defined TINY && !defined SMALL && !defined MEDIUM
# error "no memory model defined -- please use -DTINY, -DSMALL or -DMEDIUM"
#endif

#if defined TINY && defined DOSX
# error "tiny model in DOS extender mode not supported"
#endif

#if !defined TINY && defined TSR
# error "non-tiny model TSR not supported"
#endif

#ifdef DOSX
	.arch i286
#else
	.arch i8086
#endif
	.code16

#include "call-cvt.h"

	.global	_start

	.section .startupA, "ax"

_start:

#ifdef TSR
	.section .startupB, "ax"

	jmp	__stext_nokeep_load
#endif

	.section .startupC, "ax"

	# Get the MS-DOS version number & see if it is 2 or above.
	movb	$0x30,	%ah
	int	$0x21
	subb	$2,	%al
	cbtw
	# Set bp to zero iff the MS-DOS version is 2.x.  DOS 3+ gives us the
	# program's name in the environment segment, but DOS 2.x does not.
	xchgw	%ax,	%bp
	# At this point, the flags should contain the result of comparing the
	# DOS major version number with 2.  dos-mtv1.S & dos-mxv1.S make use
	# of this.

	.section .startupD, "ax"

	# For a .com file, resize the program's memory control block to
	# cover only the near code and data segments.  Abort on any failure.
	#
	# .exe files that are meant to fail properly under MS-DOS 1.x will
	# also need to do this, but this is handled by dos-mxv1.S.
	#
	# TODO: for non-TSRs, maybe allow the MCB to be less than 64 KiB
	# under certain conditions --- e.g. if it is enough for BSS and
	# stack and perhaps a user-specified heap space.
#ifdef TINY
# ifdef TSR
	movw	$__entry_stack_end_minimum, %ax
	cmpw	%ax,	%sp
	jb	.Lno_room
	xchgw	%ax,	%sp
# endif
	movb	$0x4a,	%ah
	movw	$__msdos_initial_alloc_paras, %bx
	int	$0x21
	jnc	.Lmcb_ok
.Lno_room:
	movw	$.Lno_room_msg, %dx
	.global	__msdos_crt_bail
__msdos_crt_bail:
	movb	$9,	%ah
	int	$0x21
	movb	$-1,	%al
	jmp	.Lexit
	.pushsection .msdos_init_rodata, "a"
.Lno_room_msg:
	.ascii	"No room$"
	.balign	2
	.popsection
.Lmcb_ok:
#endif
#ifndef TINY
	pushw	%ss
	popw	%es
#endif
#ifdef TSR
	# If this is a TSR, copy the transient code & data after .startupD
	# from their load address (LMA) to their runtime address (VMA).
	movw	$__edata_nokeep_load-2, %si
	movw	$__edata_nokeep-2, %di
	movw	$__lnokeep_to_copy2, %cx
	std
	rep	movsw
	# We are still running our startup code at the LMA.  The subsequent
	# code has been copied to the VMA; jump there.  0xe9 is a near
	# relative `jmp'.
	.byte	0xe9
	.word	__text_nokeep_leap
	# (This label is used by the linker script.)
	.global	__stext_nokeep_to_copy
__stext_nokeep_to_copy:
	# OK, we are now running at the VMA.  Switch to the transient stack.
	movw	$__stack_end_nokeep, %sp
#endif
	# Clear the BSS area(s).
	xorw	%ax, %ax
#ifndef TSR
	movw	$__sbss, %di
	movw	$__lbss, %cx
	cld
	rep	stosw
#else
	movw	$__sbss_keep, %di
	movw	$__lbss_keep2, %cx
	cld
	rep	stosw
	movw	$__sbss_nokeep, %di
	movw	$__lbss_nokeep2, %cx
	rep	stosw
#endif
#ifdef DOSX
	# Make %ss an expand-down descriptor, and limit it.  Use the area
	# just after BSS (which will be the heap/stack area) to temporarily
	# hold %ss's descriptor entry.
	movw	$0x000b, %ax
	movw	%ss,	%bx
# ifndef TINY
	movw	%bx,	%es
# endif
	movw	$__ebss, %di
	int	$0x31
	jc	.Lcont_dosx
# ifdef TINY
	movw	$0x2c-1, (%di)
	orb	$0x04,	5(%di)
	andb	$0x30,	6(%di)
# else
	movw	$__sdata-1, %ss:(%di)
	orb	$0x04,	%ss:5(%di)
	andb	$0x30,	%ss:6(%di)
# endif
	movw	$0x000c, %ax
	int	$0x31
# ifdef TINY
	pushw	%ss
	popw	%ds
# endif
.Lcont_dosx:
#endif
#ifndef TINY
	movw	%ds,	%bx
#endif

	.section .startupE, "ax"

	# Find length of environment + progname
	movw	0x2c,	%es
	xorw	%di,	%di
	xorw	%ax,	%ax
.Lfind_env_end:
	movw	$-1,	%cx
	repne	scasb
	incw	%cx
	incw	%cx
	jne	.Lfind_env_end
	testw	%bp,	%bp
	jz	.Lno_argv0
	scasw
	decw	%cx
	repne	scasb
.Lno_argv0:

	# Copy environment + progname
	pushw	%es
	popw	%ds
	pushw	%ss
	popw	%es
	incw	%di
	andw 	$-2,	%di
	subw	%di,	%sp
	movw	%di,	%cx
	movw	%sp,	%di
	xorw	%si,	%si
	rep	movsb

	# Push pointers to environment + progname
#ifdef TINY
	pushw	%es
	popw	%ds
#endif
	movw	%sp,	%di
	pushw	%ax		# envp ends with null pointer
.Lpush_env_pointers:
	pushw	%di
	movw	$-1,	%cx
	repne	scasb
	incw	%cx
	incw	%cx
	jne	.Lpush_env_pointers
	popw	%cx		# don't include the final empty string
	incw	%di		# advance di to progname (if there is a
	incw	%di		# progname)
	testw	%bp,	%bp
	movw	%sp,	%bp	# bp is envp
	pushw	%ax		# argv[argc] = NULL
	jnz	.Largv0
	movw	%sp,	%di	# if no progname, use the null byte in the
				# null pointer we just pushed as argv[0]
.Largv0:
	pushw	%di		# argv[0] will be first after reversal
	movw	%sp,	%dx	# dx points to last item of argv

	# Parse command tail and push argument pointers
	movw	$0x81,	%si
#ifdef TINY
	movw	%si,	%di
#else
	movw	$.Largv, %di
	movw	%bx,	%ds
#endif
	xchgw	%ax,	%cx
	incw	%cx		# initialize argc in cx to 1 (from ax = 0)

.Lspace:
	movw	%di,	%bx
	lodsb
	cmpb	$' ',	%al
	je	.Lspace
	cmpb	$9,	%al
	je	.Lspace
	cmpb	$'\"',	%al
	je	.Linside
	cmpb	$13,	%al
	je	.Lfinish
.Loutside_check_backslash:
	cmpb	$'\\',	%al
	je	.Loutside_backslash
.Loutside_other:
	stosb
.Loutside:
	lodsb
	cmpb	$' ',	%al
	je	.Lend_argument
	cmpb	$9,	%al
	je	.Lend_argument
	cmpb	$'\"',	%al
	je	.Loutside_quote
	cmpb	$13,	%al
	jne	.Loutside_check_backslash
.Largument_finish:
	movb	$0,	%al
	stosb
	pushw	%bx
	incw	%cx
.Lfinish:
#ifndef TINY
	pushw	%ss
	popw	%ds
#endif
	movw	%sp,	%si
	movw	%sp,	%di
	movw	%dx,	%bx
	movw	%cx,	%dx
	shrw	$1,	%cx
	jcxz	.Lno_reverse
.Ldo_reverse:
	lodsw
	xchgw	(%bx),	%ax
	stosw
	decw	%bx
	decw	%bx
	loop	.Ldo_reverse
.Lno_reverse:
	movw	%bp,	environ
#ifndef __IA16_CALLCVT_REGPARMCALL
	movw	%sp,	%ax
	pushw	%bp		# envp
	pushw	%ax		# argv
	pushw	%dx		# argc
#else
	pushw	%dx
#endif

	.section .startupF, "ax"

#ifdef __IA16_CALLCVT_REGPARMCALL
	popw	%ax		# argc
	movw	%sp,	%dx	# argv
	movw	%bp,	%cx	# envp
#endif
	CALL_ (main)
#if defined __IA16_CALLCVT_CDECL
	addw	$6,	%sp
#elif defined __IA16_CALLCVT_STDCALL
	# We do not know whether main (...) pops no arguments, two
	# arguments (argc, argv), or three arguments (argc, argv, envp).  So
	# pop nothing here; it should be safe to call exit (.) with extra
	# stuff on the stack.
#endif
#ifndef __IA16_CALLCVT_REGPARMCALL
	pushw	%ax
#endif
	CALL_ (exit)

.Linside_backslash_other:
#ifdef TINY
	movb	$'\\',	(%di)
#else
	movb	$'\\',	%es:(%di)
#endif
	incw	%di
.Linside_other:
	stosb
.Linside:
	lodsb
	cmpb	$'\"',	%al
	je	.Lend_argument
	cmpb	$13,	%al
	je	.Largument_finish
	cmpb	$'\\',	%al
	jne	.Linside_other
.Linside_backslash:
	lodsb
	cmpb	$'\"',	%al
	je	.Linside_backslash_quote
	cmpb	$13,	%al
	je	.Lbackslash_finish
	cmpb	$'\\',	%al
	jne	.Linside_backslash_other
.Linside_backslash_backslash:
	movb	$'\\',	%al
	stosb
	jmp	.Linside_backslash

.Loutside_backslash_backslash:
	movb	$'\\',	%al
	stosb
.Loutside_backslash:
	lodsb
	cmpb	$' ',	%al
	je	.Loutside_backslash_space
	cmpb	$9,	%al
	je	.Loutside_backslash_space
	cmpb	$'\"',	%al
	je	.Loutside_backslash_quote
	cmpb	$13,	%al
	je	.Lbackslash_finish
	cmpb	$'\\',	%al
	je	.Loutside_backslash_backslash
.Loutside_backslash_other:
#ifdef TINY
	movb	$'\\',	(%di)
#else
	movb	$'\\',	%es:(%di)
#endif
	incw	%di
	jmp	.Loutside_other

.Loutside_backslash_space:
	movb	$'\\',	%al
	stosb
.Lend_argument:
	movb	$0,	%al
	stosb
	pushw	%bx
	incw	%cx
	jmp	.Lspace

.Loutside_quote:
	mov	$0,	%al
	stosb
	pushw	%bx
	incw	%cx
	movw	%di,	%bx
	jmp	.Linside

.Lbackslash_finish:
	movb	$'\\',	%al
	stosb
	jmp	.Largument_finish

.Linside_backslash_quote:
	movb	$'\"',	%al
	jmp	.Linside_other

.Loutside_backslash_quote:
	movb	$'\"',	%al
	jmp	.Loutside_other


	.section .exitA, "ax"

	.global _exit
_exit:
#ifdef __IA16_CALLCVT_REGPARMCALL
	xchgw	%ax,	%si
#endif

	.section .exitB, "ax"

#ifndef __IA16_CALLCVT_REGPARMCALL
	popw	%bx
# ifdef MEDIUM
	popw	%bx
# endif
	popw	%ax
#else
	xchgw	%ax,	%si
#endif
	.global	__msdos_crt_exit
__msdos_crt_exit:
.Lexit:
	movb	$0x4c,	%ah
	int	$0x21

#ifndef TINY
	# For non-tiny memory models, we need to copy the command line
	# arguments out to the data segment, rather than modify them in
	# place in DOS's PSP --- since the PSP is outside the data segment.
	.lcomm	.Largv, 128
#endif
