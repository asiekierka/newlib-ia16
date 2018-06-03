/* Linker script for DOS executables with separate data and text segments.
   Partly derived from elks-separate.ld .  */

OUTPUT_FORMAT(binary)
ENTRY(_start)
INPUT(crtbegin.o crtend.o dos-exe-small-crt0.o)
GROUP(-lc -lgcc -ldos-exe-small -lm)

MEMORY
  {
    bseglma	(wx) : ORIGIN = 0x00000, LENGTH = 0xa0000
    hdrvma	(wx) : ORIGIN = 0x00000, LENGTH = 0x40020
    csegvma	(wx) : ORIGIN = 0x00020, LENGTH = 0x10000
    fr0segvma	(wx) : ORIGIN = 0x00000, LENGTH = 0x10000
    fr1segvma	(wx) : ORIGIN = 0x00000, LENGTH = 0x10000
    fr2segvma	(wx) : ORIGIN = 0x00000, LENGTH = 0x10000
    fr3segvma	(wx) : ORIGIN = 0x00000, LENGTH = 0x10000
    fr4segvma	(wx) : ORIGIN = 0x00000, LENGTH = 0x10000
    fr5segvma	(wx) : ORIGIN = 0x00000, LENGTH = 0x10000
    fr6segvma	(wx) : ORIGIN = 0x00000, LENGTH = 0x10000
    fr7segvma	(wx) : ORIGIN = 0x00000, LENGTH = 0x10000
    fd0segvma	(wx) : ORIGIN = 0x00000, LENGTH = 0x10000
    fd1segvma	(wx) : ORIGIN = 0x00000, LENGTH = 0x10000
    fd2segvma	(wx) : ORIGIN = 0x00000, LENGTH = 0x10000
    fd3segvma	(wx) : ORIGIN = 0x00000, LENGTH = 0x10000
    fd4segvma	(wx) : ORIGIN = 0x00000, LENGTH = 0x10000
    fd5segvma	(wx) : ORIGIN = 0x00000, LENGTH = 0x10000
    fd6segvma	(wx) : ORIGIN = 0x00000, LENGTH = 0x10000
    fd7segvma	(wx) : ORIGIN = 0x00000, LENGTH = 0x10000
    dsegvma	(wx) : ORIGIN = 0x00020, LENGTH = 0x10000
  }

SECTIONS
  {
    /* Fabricate a .exe header here.  Although libbfd does have an
       "i386msdos" back-end which produces an "MZ" exe header, it cannot do
       certain things (yet).  In particular, we would like to use the .exe
       header to point %ss to the separate data segment right at startup.

       Note: The section names .msdos_mz_hdr, .msdos_mz_hdr.*,
       .msdos_mz_reloc, and .msdos_mz_reloc.* are special!  I have hacked (my
       fork of) libbfd to use the LMA + size of .msdos_mz_hdr when computing
       paragraph counts at link time; I also intend to hack GNU as and/or
       libbfd to output MZ relocations into .msdos_mz_reloc and
       .msdos_mz_reloc.* at assembly time.  -- tkchia  */

    .msdos_mz_hdr : {
		HIDDEN (__msdos_mz_hdr_start = .);

		/* Signature.  */
		SHORT (0x5a4d)
		/* Bytes in last 512-byte page.  */
		SHORT ((LOADADDR (.data) + SIZEOF (.data)) % 512)
		/* Total number of 512-byte pages.  */
		SHORT ((LOADADDR (.data) + SIZEOF (.data) + 511) / 512)
		/* Relocation entries.  */
		SHORT (__msdos_mz_rels)
		/* Header size in paragraphs.  */
		SHORT (__msdos_mz_hdr_paras)
		/* Minimum extra paragraphs.  */
		SHORT ((0x10000 - SIZEOF (.data) - ADDR (.data)) / 16)
		/* Maximum extra paragraphs.  Instead of setting this to
		   0xffff so that the program hogs up all remaining
		   conventional memory, just let the program have memory up
		   to the end of the data segment, and ask for more memory
		   from DOS if it really needs it.  */
		SHORT ((0x10000 - SIZEOF (.data) - ADDR (.data)) / 16)
		/* Initial %ss.  */
		SHORT (LOADADDR (.data) / 16 - __msdos_mz_hdr_paras
		    - ADDR (.data) / 16 + 0x10000)
		/* Initial %sp.  Let it wrap around from 0.  */
		SHORT (0)
		/* Checksum (unused).  */
		SHORT (0)
		/* Initial %cs:%ip.  */
		SHORT (_start)
		SHORT (LOADADDR (.text) / 16 - __msdos_mz_hdr_paras
		    - ADDR (.text) / 16 + 0x10000)
		/* Relocation table offset.  */
		SHORT (__msdos_mz_rel_start - __msdos_mz_hdr_start)
		/* Overlay number.  */
		SHORT (0)
		*(.msdos_mz_hdr .msdos_mz_hdr.*)

		/* Relocations.  */
		HIDDEN (__msdos_mz_rel_start = .);
		*(.msdos_mz_reloc .msdos_mz_reloc.*)
		HIDDEN (__msdos_mz_rel_end = .);
		HIDDEN (__msdos_mz_rels = (. - __msdos_mz_rel_start) / 4);

		/* Padding.  */
		HIDDEN (__msdos_mz_hdr_paras
			    = (. - __msdos_mz_hdr_start + 15) / 16);
		. = ALIGN (16);

		ASSERT ((__msdos_mz_rel_end - __msdos_mz_rel_start) % 4 == 0,
		    "Error: MZ relocations are not 4-byte aligned");
		ASSERT (__msdos_mz_rels <= 0xffff,
		    "Error: too many MZ relocations");
	} >hdrvma AT>bseglma

    /* Target text sections.  */
    .text : {
		__stext = .;
		*(.startupA)
		*(.init)
		*(.startupB)
		*(.fini)
		*(.startupC)
		*(.text) *(.text.*)
		__etext = .;

		/* Make the data segments start on a paragraph boundary.  */
		. = ALIGN (16);
		__etext_padded = .;

		ASSERT(. <= 0x10000,
		    "Error: too large for a small-model .exe file.");

	} >csegvma AT >bseglma
	__ltext = __etext - __stext;
	__ltext_padded = __etext_padded - __stext;

    /* Target far data sections.  Place the far data sections _before_ the
       near data section (and before near BSS).

       It will be nice to be able to give each input .farrodata.* and
       .fardata.* section its own output section, along with its own LMA and
       VMA, but (as of writing --- Apr 2018) the linker script syntax does
       not allow this.

       So my work-around is to arrange for GCC to tack some sort of octal
       hash value at the end of each .farrodata.* or .fardata.* section
       name, and then arrange for this linker script to distribute the
       sections into a fixed set of "bins", and hope that none of the bins
       are too large (> 64KiB).  -- tkchia  */
    .farrodata.0 : { *(.farrodata.*0) . = ALIGN (16); } >fr0segvma AT >bseglma
    .farrodata.1 : { *(.farrodata.*1) . = ALIGN (16); } >fr1segvma AT >bseglma
    .farrodata.2 : { *(.farrodata.*2) . = ALIGN (16); } >fr2segvma AT >bseglma
    .farrodata.3 : { *(.farrodata.*3) . = ALIGN (16); } >fr3segvma AT >bseglma
    .farrodata.4 : { *(.farrodata.*4) . = ALIGN (16); } >fr4segvma AT >bseglma
    .farrodata.5 : { *(.farrodata.*5) . = ALIGN (16); } >fr5segvma AT >bseglma
    .farrodata.6 : { *(.farrodata.*6) . = ALIGN (16); } >fr6segvma AT >bseglma
    .farrodata.7 : {
		*(.farrodata .farrodata.*)
		. = ALIGN (16);
	} >fr7segvma AT >bseglma
    .fardata.0 : { *(.fardata.*0) . = ALIGN (16); } >fd0segvma AT >bseglma
    .fardata.1 : { *(.fardata.*1) . = ALIGN (16); } >fd1segvma AT >bseglma
    .fardata.2 : { *(.fardata.*2) . = ALIGN (16); } >fd2segvma AT >bseglma
    .fardata.3 : { *(.fardata.*3) . = ALIGN (16); } >fd3segvma AT >bseglma
    .fardata.4 : { *(.fardata.*4) . = ALIGN (16); } >fd4segvma AT >bseglma
    .fardata.5 : { *(.fardata.*5) . = ALIGN (16); } >fd5segvma AT >bseglma
    .fardata.6 : { *(.fardata.*6) . = ALIGN (16); } >fd6segvma AT >bseglma
    .fardata.7 : {
		*(.fardata .fardata.*)
		. = ALIGN (16);
	} >fd7segvma AT >bseglma

    /* Target data sections.  */
    .data : {
		__sdata = .;

		/* Build lists of constructors and destructors.  */
		KEEP (*crtbegin*.o(.ctors))
		KEEP (*(EXCLUDE_FILE (*crtend*.o ) .ctors))
		KEEP (*(SORT(.ctors.*)))
		KEEP (*(.ctors))

		KEEP (*crtbegin*.o(.dtors))
		KEEP (*(EXCLUDE_FILE (*crtend*.o ) .dtors))
		KEEP (*(SORT(.dtors.*)))
		KEEP (*(.dtors))

		*(.rodata) *(.rodata.*)
		*(.data) *(.data.*)
		*(.gcc_except_table)
		__edata = .;

		/* ".../ia16-elf/bin/ld: a.out: R_386_RELSEG16 with
		   unaligned section `.bss'" */
		. = ALIGN (8);
		__edata_padded = .;
	} >dsegvma AT >bseglma

    .bss (NOLOAD) : {
    	 	 __sbss = .;
                *(.bss) *(.bss.*)
                *(COMMON)
                __ebss = .;

                /* Minimum address allowed for sbrk() to use.  */
                __heap_end_minimum = ALIGN(8);

		ASSERT(. <= 0xfff8,
		    "Error: too large for a small-model .exe file.");
    	} >dsegvma AT >bseglma

	__ldata = __edata - __sdata;
	__lbss0 = __ebss - __sbss;
	__lbss1 = __lbss0 + 1;
	__lbss = __lbss1 / 2;

    /DISCARD/ : { *(.*) }
  }
