/*
 * Declarations for operation under a DOS extender.
 *
 * Copyright (c) 2019--2022 TK Chia
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *   * Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *   * Neither the name of the developer(s) nor the names of its
 *     contributors may be used to endorse or promote products derived from
 *     this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 * IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 * PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#ifndef FP_SEG
#define FP_SEG(x) \
  __builtin_ia16_selector ((unsigned)((unsigned long)(void __far *)(x) >> 16))
#endif
#ifndef FP_OFF
#define FP_OFF(x) ((unsigned) (unsigned long) (void __far *) (x))
#endif
#ifndef MK_FP
#define MK_FP(s, o) ((void __far *) ((unsigned long) (unsigned) (s) << 16 | \
				     (unsigned) (o)))
#endif

typedef struct __attribute__ ((__packed__))
  {
    union
      {
	uint32_t edi;
	uint16_t di;
      };
    union
      {
	uint32_t esi;
	uint16_t si;
      };
    union
      {
	uint32_t ebp;
	uint16_t bp;
      };
    uint32_t reserved;
    union
      {
	uint32_t ebx;
	uint16_t bx;
      };
    union
      {
	uint32_t edx;
	uint16_t dx;
      };
    union
      {
	uint32_t ecx;
	uint16_t cx;
      };
    union
      {
	uint32_t eax;
	uint16_t ax;
      };
    uint16_t flags, es, ds, fs, gs, ip, cs, sp, ss;
  }
rm_call_struct;

static inline int
_DPMISimulateRealModeInterrupt (uint8_t __intr_no, uint8_t __flags,
				uint16_t __words_to_copy,
				rm_call_struct __far *__call_st)
{
  int __res;
  __asm volatile ("int {$}0x31; sbb{w} %0, %0"
		  : "=abcr" (__res)
		  : "a" (0x0300U),
		    "b" ((uint16_t) __flags << 8 | __intr_no),
		    "c" (__words_to_copy),
		    "e" (FP_SEG (__call_st)), "D" (FP_OFF (__call_st))
		  : "cc", "memory");
  return __res;
}

extern __segment __dosx_tb_rm_seg, __dosx_tb_pm_sel;
extern size_t __dosx_tb_sz;

static inline void __far *
__dosx_tb (void)
{
  return MK_FP (__dosx_tb_pm_sel, 0);
}

static inline void __far *
__dosx_tb_end (void)
{
  return MK_FP (__dosx_tb_pm_sel, __dosx_tb_sz);
}
