/*
 * Copyright (c) 2021--2022 TK Chia
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

#include <stdlib.h>
#include <string.h>
#include "dbcs.h"
#include "dosx.h"

static volatile __segment cached_seg_pm = 0;
static volatile uint16_t cached_seg_rm = 0;

_dos_dbcs_lead_table_t
_dos_get_dbcs_lead_table (void)
{
  rm_call_struct rmc;
  int res;
  uint16_t seg_rm, off;
  __segment seg_pm;
  int32_t res32;
  _dos_dbcs_lead_table_t lt;

  memset (&rmc, 0, sizeof (rmc));  /* also set rmc.ss = rmc.sp := 0 */
  rmc.flags = 1;  /* pre-set carry flag */
  rmc.ax = 0x6300U;
  rmc.si = 0xffffU;
  res = _DPMISimulateRealModeInterrupt (0x21, 0, 0, &rmc);

  if (res != 0)
    abort ();

  if ((uint8_t) rmc.ax != 0)
    return _null_dbcs_lt;

  off = rmc.si;
  seg_rm = rmc.ds;

  if (off == 0xffffU)
    return _null_dbcs_lt;

  seg_pm = cached_seg_pm;
  if (! seg_pm || seg_rm != cached_seg_rm)
    {
      res32 = _DPMISegmentToDescriptor (seg_rm);
      if (res32 < 0)
	abort ();

      seg_pm = (__segment) res32;
      cached_seg_pm = 0;
      cached_seg_rm = seg_rm;
      cached_seg_pm = seg_pm;
    }

  lt = MK_FP (seg_pm, off);
  if (! *lt)
    return _null_dbcs_lt;

  return lt;
}
