/* Startup code for
     * a "tiny" model MS-DOS .com file with combined text and data segment,
     * a "small" model MS-DOS .exe file with one text segment and one separate
       data segment, or
     * a "medium" model MS-DOS .exe file with multiple text segments and one
       data segment.  */

#if !defined TINY && !defined SMALL && !defined MEDIUM
#error "no memory model defined -- please use -DTINY, -DSMALL or -DMEDIUM"
#endif

#ifdef DPMIABLE
	.arch i286
#else
	.arch i8086
#endif
	.code16

#include "call-cvt.h"

	.global	_start

#ifdef TSR
	.section .startupA, "ax"

_start:
	jmp	__stext_nokeep_load
#endif

	.section .startupB, "ax"

#ifndef TSR
_start:
#endif
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

	.section .startupC, "ax"

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
	# If this is a TSR, copy the transient code & data after .startupC
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
#ifdef DPMIABLE
	# We still have segment registers pointing to the code segment, data
	# segment, and PSP; and we have not invoked the program's
	# constructor routines yet.  This is a good time to switch to
	# protected mode if we want to.
	movw	$0x1687, %ax
	int	$0x2f
	testw	%ax,	%ax
	jnz	.Lno_dpmi
	# Plug in the DPMI entry point address.  This is self-modifying code
	# (!) --- rely on the `int $0x21' later to get the instruction cache
	# flushed, before we reach the `lcallw'.
# ifdef TINY
	movw	%di,	.Ldpmi_lcall+1
	movw	%es,	.Ldpmi_lcall+3
# else
	movw	%di,	%cs:.Ldpmi_lcall+1
	movw	%es,	%cs:.Ldpmi_lcall+3
# endif
	# If we have a 32-bit DPMI host, try to see if we are running under
	# Sandmann's CWSDPMI, which works around a bug in some DPMI clients:
	#	"Ideally, on the request to enter DPMI's PM with a 16-bit
	#	 request, we would just fail the call setting the carry bit
	#	 like the DPMI specification describes.  Some buggy 16-bit
	#	 compiler tools don't check the return status and will hang
	#	 the machine in this case.  So, I issue an error message and
	#	 exit the image instead."
	# We work around this workaround, and continue in real (or V86) mode
	# instead of quitting.
	shrw	%bx
	jnc	.L16bit_ok
	.pushsection .rodata.startup, "a"
0:
	.byte	0xa8,0x01	#	"test	al,1"
	.byte	0x75,0x29	#	"jnz	short ok_32"
	.byte	0xba		#	"mov	dx,"...
1:
	.byte	0x0e		#	"push	cs"
	.byte	0x1f		#	"pop	ds"
	.byte	0xb4,0x09	#	"mov	ah,9"
	.byte	0xcd,0x21	#	"int	21h"
	.byte	0xb8,0x01,0x4c	#	"mov	ax,4c01h"
	.byte	0xcd,0x21	#	"int	21h"
2:
	.balign	2
	.popsection
	movw	$0b,	%si
	movw	$1b-0b,	%cx
# ifdef TINY
	repz cmpsb
# else
	repz cmpsb %es:(%di), %ss:(%si)
# endif
	jnz	.L16bit_ok
	scasw
	movb	$2b-1b,	%cl
# ifdef TINY
	repz cmpsb
# else
	repz cmpsb %es:(%di), %ss:(%si)
# endif
	jz	.Lno_dpmi
.L16bit_ok:
	# Allocate space for the DPMI private data area.  Do this by
	# adjusting the size of our own DOS memory control block.
	pushw	%ds
	popw	%es
	movw	%si,	%bx
	addw	$__msdos_initial_alloc_paras, %bx
	movb	$0x4a,	%ah
	int	$0x21
	jc	.Lno_dpmi
	# Try to switch to protected mode.
	movw	%es,	%ax
	addw	$__msdos_initial_alloc_paras, %ax
	movw	%ax,	%es
	xorw	%ax,	%ax
# ifndef TINY
	movw	%cs,	%cx
# endif
	movw	%ss,	%dx
.Ldpmi_lcall:
	lcallw	$0,	$0
	jc	.Lno_dpmi
	# Success!  Quickly store the real mode value of %ss, which may come
	# in useful later.
# ifdef TINY
	movw	%dx,	__ia16_dpmi_rmode_ds
# else
	movw	%cx,	%ss:__ia16_dpmi_rmode_cs
	movw	%dx,	%ss:__ia16_dpmi_rmode_ds
# endif
	# Limit %cs so that it does not go beyond the end of our actual
	# code.  Note that %ax == 0 is preserved from above.
	movb	$0x08,	%al
	movw	%cs,	%bx
	xorw	%cx,	%cx
	movw	$__etext-1, %dx
	int	$0x31
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
	jc	.Lcont_dpmi
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
.Lcont_dpmi:
.Lno_dpmi:
#endif
#ifndef TINY
	pushw	%ds
	pushw	%ss
	popw	%ds
#endif

#ifndef TINY
	# For the small memory model, we need to copy the command line
	# arguments out to the data segment, rather than modify them in
	# place in DOS's PSP --- since the PSP is outside the data segment.
	.lcomm	.Largv,	128
	# We currently do not use the PSP segment value after startup, so we
	# can overlap .Lpsp with .Largv.  This may change in the future.
	.set	.Lpsp,	.Largv
#endif

	# Find length of environment + progname
#ifndef TINY
	popw	%ds
	movw	%ds, %ss:.Lpsp
#endif
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
	movw	%ss:(.Lpsp-.Largv)(%di), %ds
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

	.section .startupD, "ax"

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
