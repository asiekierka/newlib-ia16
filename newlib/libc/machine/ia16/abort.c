/* abort.c verbose abort () implementation for IA-16
 *
 * Copyright (c) 2018 TK Chia
 *
 * The authors hereby grant permission to use, copy, modify, distribute,
 * and license this software and its documentation for any purpose, provided
 * that existing copyright notices are retained in all copies and that this
 * notice is included verbatim in any distributions. No written agreement,
 * license, or royalty fee is required for any of the authorized uses.
 * Modifications to this software may be copyrighted by their authors
 * and need not follow the licensing terms described here, provided that
 * the new terms are clearly indicated on the first page of each file where
 * they apply.
 */

#include <signal.h>
#include <unistd.h>

#ifdef __MSDOS__
# define NL		"\r\n"
#else
# define NL		"\n"
#endif

typedef struct {
  unsigned ax, bx, cx, dx, bp, si, di, flags, cs, ds, es, ss, sp;
} abort_regs_t;

static void
dump_mem (const unsigned *mem, unsigned n_words)
{
  unsigned word;
  char buf[5];

  buf[4] = ' ';
  while (n_words-- != 0)
    {
      word = *mem++;
      buf[3] = "0123456789abcdef"[word & 0xf];
      word >>= 4;
      buf[2] = "0123456789abcdef"[word & 0xf];
      word >>= 4;
      buf[1] = "0123456789abcdef"[word & 0xf];
      word >>= 4;
      buf[0] = "0123456789abcdef"[word];
      write (2, buf, 5);
    }
}

void
__ia16_abort_impl (abort_regs_t regs)
{
  static const char msg1[] = NL "abort () called" NL
				"reg (a-d bp si di f cs ds es ss sp):" NL,
		    msg2[] = NL "stk:" NL;

  write (2, msg1, sizeof (msg1) - 1);
  dump_mem ((const unsigned *) &regs, sizeof (regs) / sizeof (unsigned));
  write (2, msg2, sizeof (msg2) - 1);
  dump_mem ((const unsigned *) regs.sp, 192);

#ifndef __IA16_FEATURE_PROTECTED_MODE
  /* _exit (.) may ultimately make the system weird out and wipe the
     information dump from the screen.  Try to delay a bit before actually
     exiting, if possible.

     If we are not compiling for protected mode, then it should be fine to
     use the `hlt' instruction.  */
  {
    unsigned delay = 64;
    while (delay-- != 0)
      __asm volatile ("hlt");
  }
#endif

  for (;;)
    _exit (128 | SIGABRT);
}

__asm(
  "	.text\n"
  "	.global	abort\n"
  "abort:\n"
  "	movw	%sp,	%ss:abort_stack-2\n"
  "	movw	$abort_stack-2, %sp\n"
  "	pushw	%ss\n"
  "	pushw	%es\n"
  "	pushw	%ds\n"
  "	pushw	%cs\n"
  "	pushfw\n"
  "	pushw	%di\n"
  "	pushw	%si\n"
  "	pushw	%bp\n"
  "	pushw	%dx\n"
  "	pushw	%cx\n"
  "	pushw	%bx\n"
  "	pushw	%ax\n"
  "	pushw	%ss\n"
  "	popw	%ds\n"
  "	cld\n"
  "	call	__ia16_abort_impl\n"
  "	.bss\n"
  "	.skip	128\n"
  "abort_stack:\n"
  "	.text");
