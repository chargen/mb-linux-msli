/*
 * Copyright (C) 2008-2009 Michal Simek <monstr@monstr.eu>
 * Copyright (C) 2008-2009 PetaLogix
 * Copyright (C) 2006 Atmark Techno, Inc.
 *
 * This file is subject to the terms and conditions of the GNU General Public
 * License. See the file "COPYING" in the main directory of this archive
 * for more details.
 */

OUTPUT_FORMAT("elf32-microblaze", "elf32-microblaze", "elf32-microblaze")
OUTPUT_ARCH(microblaze)
ENTRY(_start)

#include <asm/page.h>
#include <asm-generic/vmlinux.lds.h>

jiffies = jiffies_64 + 4;

SECTIONS {
	. = CONFIG_KERNEL_START;
	_start = CONFIG_KERNEL_BASE_ADDR;
	.text : AT(ADDR(.text) - LOAD_OFFSET) {
		_text = . ;
		_stext = . ;
		*(.text .text.*)
		*(.fixup)

		*(.exitcall.exit)
		SCHED_TEXT
		LOCK_TEXT
		KPROBES_TEXT
		IRQENTRY_TEXT
		. = ALIGN (4) ;
		_etext = . ;
	}

	. = ALIGN (4) ;
	__fdt_blob : AT(ADDR(__fdt_blob) - LOAD_OFFSET) {
		_fdt_start = . ;		/* place for fdt blob */
		*(__fdt_blob) ;			/* Any link-placed DTB */
	        . = _fdt_start + 0x8000;	/* Pad up to 32kbyte */
		_fdt_end = . ;
	}

	. = ALIGN(16);
	RO_DATA(16)
	. = ALIGN(16);
	__ex_table : AT(ADDR(__ex_table) - LOAD_OFFSET) {
		__start___ex_table = .;
		*(__ex_table)
		__stop___ex_table = .;
	}

	/*
	 * sdata2 section can go anywhere, but must be word aligned
	 * and SDA2_BASE must point to the middle of it
	 */
	.sdata2 : AT(ADDR(.sdata2) - LOAD_OFFSET) {
		_ssrw = .;
		. = ALIGN(4096); /* page aligned when MMU used - origin 0x8 */
		*(.sdata2)
	. = ALIGN(8);
	_essrw = .;
	_ssrw_size = _essrw - _ssrw;
	_KERNEL_SDA2_BASE_ = _ssrw + (_ssrw_size / 2);
	}

	/* FIXED in mainline version */
	_sdata = . ;
	/* page aligned when MMU used - origin 0x4 */
	.data ALIGN (4096) : AT(ADDR(.data) - LOAD_OFFSET) {
		DATA_DATA
	}
	. = ALIGN(32);
	.data.cacheline_aligned : AT(ADDR(.data.cacheline_aligned) - LOAD_OFFSET) {
		*(.data.cacheline_aligned)
	}
	_edata = . ;

	/* Reserve some low RAM for r0 based memory references */
	. = ALIGN(0x4) ;
	r0_ram = . ;
	. = . +  4096;	/* a page should be enough */

	/* The initial task */
	. = ALIGN(8192);
	.data.init_task : AT(ADDR(.data.init_task) - LOAD_OFFSET) {
		*(.data.init_task)
	}

	/* Under the microblaze ABI, .sdata and .sbss must be contiguous */
	. = ALIGN(8);
	.sdata : AT(ADDR(.sdata) - LOAD_OFFSET) {
		_ssro = .;
		*(.sdata)
	}

	.sbss :	AT(ADDR(.sbss) - LOAD_OFFSET) {
		_ssbss = .;
		*(.sbss)
		_esbss = .;
		_essro = .;
		_ssro_size = _essro - _ssro ;
		_KERNEL_SDA_BASE_ = _ssro + (_ssro_size / 2) ;
	}

	. = ALIGN(PAGE_SIZE);
	__init_begin = .;

	. = ALIGN(4096);
	.init.text : AT(ADDR(.init.text) - LOAD_OFFSET) {
		_sinittext = . ;
		*(.init.text)
		*(.exit.text)
		*(.exit.data)
		_einittext = .;
	}

	.init.data : AT(ADDR(.init.data) - LOAD_OFFSET) {
		*(.init.data)
	}

	. = ALIGN(4);
	.init.ivt : AT(ADDR(.init.ivt) - LOAD_OFFSET) {
		__ivt_start = .;
		*(.init.ivt)
		__ivt_end = .;
	}

	.init.setup : AT(ADDR(.init.setup) - LOAD_OFFSET) {
		__setup_start = .;
		*(.init.setup)
		__setup_end = .;
	}

	.initcall.init : AT(ADDR(.initcall.init) - LOAD_OFFSET ) {
		__initcall_start = .;
		INITCALLS
		__initcall_end = .;
	}

	.con_initcall.init : AT(ADDR(.con_initcall.init) - LOAD_OFFSET) {
		__con_initcall_start = .;
		*(.con_initcall.init)
		__con_initcall_end = .;
	}

	SECURITY_INIT

	__init_end_before_initramfs = .;

	.init.ramfs ALIGN(4096) : AT(ADDR(.init.ramfs) - LOAD_OFFSET) {
		__initramfs_start = .;
		*(.init.ramfs)
		__initramfs_end = .;
		. = ALIGN(4);
		LONG(0);
/*
 * FIXME this can break initramfs for MMU.
 * Pad init.ramfs up to page boundary,
 * so that __init_end == __bss_start. This will make image.elf
 * consistent with the image.bin
 */
		/* . = ALIGN(4096); */
	}
	__init_end = .;

	.bss ALIGN (4096) : AT(ADDR(.bss) - LOAD_OFFSET) {
		/* page aligned when MMU used */
		__bss_start = . ;
			*(.bss*)
			*(COMMON)
		. = ALIGN (4) ;
		__bss_stop = . ;
		_ebss = . ;
	}
	. = ALIGN(4096);
	_end = .;
}
