# Copyright (c) 2022 TK Chia
#
# The authors hereby grant permission to use, copy, modify, distribute,
# and license this software and its documentation for any purpose, provided
# that existing copyright notices are retained in all copies and that this
# notice is included verbatim in any distributions. No written agreement,
# license, or royalty fee is required for any of the authorized uses.
# Modifications to this software may be copyrighted by their authors
# and need not follow the licensing terms described here, provided that
# the new terms are clearly indicated on the first page of each file where
# they apply.

*cmodel_ld:
%{mcmodel=medium:m.ld;mcmodel=small:s.ld;:t.ld}

*cmodel_c0_a:
%{mcmodel=medium:m-c0.a;mcmodel=small:s-c0.a;:t-c0.a}

*cmodel_lc_a:
%{mcmodel=medium:m-lc.a;mcmodel=small:s-lc.a;:t-lc.a}

*cmodel_s_ld:
%{mcmodel=medium:ms.ld;mcmodel=small:ss.ld;:ts.ld}

*cmodel_l_ld:
%{mcmodel=medium:ml.ld;mcmodel=small:sl.ld;:tl.ld}

*cmodel_sl_ld:
%{mcmodel=medium:msl.ld;mcmodel=small:ssl.ld;:tsl.ld}

*ia16_impl_rt_switches:
%{mdosx} %{mmsdos-handle-v1} %{mnewlib-nano-stdio} %{mnewlib-autofloat-stdio} \
%{mno-newlib-autofloat-stdio} %{mhandle-non-i186} %{mhandle-non-i286} \
%{maout-heap=*}

*self_spec:
%{mdosx:\
    %{mcmodel=medium:%emedium model not supported in DOS extender mode}\
    %{march=*:;:-march=i80286} \
    %{mno-segelf:;:-msegelf} \
    %{fuse-ld=*:;:-fuse-ld=gold} \
    %{msegment-relocation-stuff:\
	%nwarning: -msegment-relocation-stuff with -mdosx may result in \
bogus output}\
 } \
%{mcmodel=small|mcmodel=medium:\
    %{!mdosx:\
	%{!mno-segment-relocation-stuff:-msegment-relocation-stuff}\
     }\
 }

*asm:
%{msegelf:--32-segelf}

# Borland C apparently defines __MSDOS__, and Bruce's C compiler defines
# either __MSDOS__ or __ELKS__.
#
# For the MS-DOS target, the Amsterdam Compiler Kit defines __msdos86, while
# Open Watcom defines (!) __DOS__, _DOS, & MSDOS.  The last macro may
# pollute the user namespace, so it is probably not a good idea (yet) to
# define it here.
#	-- tkchia
%rename cpp ia16_cpp_builtin
*cpp:
%(ia16_cpp_builtin) -D__MSDOS__ -D__msdos86 -D__DOS__ -D_DOS

# For -nostdlib, -nodefaultlibs, and -nostartfiles:  arrange for the linker
# script specification (%T...) to appear in %(link_gcc_c_sequence) if we are
# linking in default libraries, but in %(link) if we are not (i.e.
# -nostdlib or -nodefaultlibs).  An exception is the main linker script for
# -mdosx, which will always appear in %(link).
#
# If default libraries are used, then we want them to appear at the end of
# the ld command line, so %(link_gcc_c_sequence) is the right place to use.
#
# If default libraries are not used, then GCC will not use
# %(link_gcc_c_sequence) at all, so we may need to rely on %(link) to pass
# the linker script to ld.
#
# TODO: simplify the linker script arrangement in general to be like the
# -mdosx case.
#	-- tkchia
*link:
%{!T*:\
    %{mdosx:\
	%Tdx-m%(cmodel_ld);\
      nostdlib|nodefaultlibs:\
	%{mtsr:\
	    %{nostdlib|nostartfiles:%Tdtr-m%(cmodel_ld);\
	      :%Tdtr-m%(cmodel_s_ld)};\
	  nostdlib|nostartfiles:\
	    %Tdos-m%(cmodel_ld);\
	  :\
	    %Tdos-m%(cmodel_s_ld)}\
     }\
 } \
%{maout-heap=*:--defsym=__heaplen_val=%*}

*startfile:
%{mdosx:-l:dx-%(cmodel_c0_a)}

*link_gcc_c_sequence:
%{mnewlib-nano-stdio:\
    %{!mno-newlib-autofloat-stdio:-lanstdio} -lnstdio;\
  :\
    %{!mno-newlib-autofloat-stdio:-lastdio} -lfstdio\
 } \
%{mdosx:\
    -l:dx-%(cmodel_lc_a);\
  :\
    %{mmsdos-handle-v1:-ldosv1} \
    %{mhandle-non-i286:\
        %{march=i80286|march=i286:-lck186};\
      mhandle-non-i186:\
        %{march=any|march=i8086|march=i8088:;march=*:-lck086}} \
    %{mtsr:\
        %{nostartfiles:%Tdtr-m%(cmodel_l_ld);:%Tdtr-m%(cmodel_sl_ld)};\
      nostartfiles:\
        %Tdos-m%(cmodel_l_ld);\
      :\
        %Tdos-m%(cmodel_sl_ld)\
     }\
 }

*post_link:
%{!mno-post-link:\
    %{mdosx:\
	%:if-exists-else(../lib/../bin/elf2dosx%s elf2dosx) \
	%{v} \
	%{mcmodel=tiny:--tiny} \
	%{o*:%*} %{!o*:a.out}\
     }\
 }
