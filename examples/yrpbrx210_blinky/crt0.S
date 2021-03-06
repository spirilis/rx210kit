/* Copyright (c) 2008, 2009, 2011 Red Hat Incorporated.
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions
   are met: 

     Redistributions of source code must retain the above copyright 
     notice, this list of conditions and the following disclaimer.

     Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in the
     documentation and/or other materials provided with the distribution.

     The name of Red Hat Incorporated may not be used to endorse 
     or promote products derived from this software without specific 
     prior written permission.

   This software is provided by the copyright holders and contributors
   "AS IS" and any express or implied warranties, including, but not
   limited to, the implied warranties of merchantability and fitness for
   a particular purpose are disclaimed.  In no event shall Red Hat
   incorporated be liable for any direct, indirect, incidental, special,
   exemplary, or consequential damages (including, but not limited to,
   procurement of substitute goods or services; loss of use, data, or
   profits; or business interruption) however caused and on any theory of
   liability, whether in contract, strict liability, or tort (including
   negligence or otherwise) arising in any way out of the use of this
   software, even if advised of the possibility of such damage.  */

/* This startup code has been modified to provide optimal use with the
 * Renesas RX210 microcontroller.
 *
 * FPU-related instructions ripped out and the CPU is set to its highest
 * possible speed before string initialization & copy operations are performed.
 */

	.text

	.global _start
_start:
.LFB2:
	mvtc	#0, psw
	mov	#__stack, r0
	mvtc	#__vectors, intb

	/* Enable HOCO, set to 50MHz, set CKSEL to HOCO
	 * ICLK by default is CKSEL / 1
	 */
        mov.l   #0x80000, r10
        mov.w   #0xA507, 1022[r10]	; Enable writing to Clock, Operating Power and VRCR registers
	mov.b	#0, 160[r10]		; Prepare for High-Speed power mode
        nop
while_power_transitioning:
        mov.b   160[r10], r11
        and     #16, r11
        cmp     #0, r11			; Loop until Operating Power Control Mode Transition complete
        bne.b   while_power_transitioning
        mov.b   #0, 49812[r10]		; HOCOPCR: Power enabled for HOCO
        mov.b   #0, 54[r10]		; HOCOCR: HCSTP=0 (HOCO is operating)
        mov.b   #3, 55[r10]		; HOCOCR2: HCFRQ = 50MHz
        mov.b   #0, 512[r10]		; VRCR: Clear before modifying system clock

verify_sckcr_written_correctly:
	mov.l	#0x10010100, 16[r10]	; SCKCR: ICLK/PCKD = Clock/1, PCKB/BCK/FCK = Clock/2
	mov.l	16[r10], r11
	cmp	#0x10010100, r11	; Loop until SCKCR shows valid
	bne	verify_sckcr_written_correctly

        mov.w   #256, 38[r10]		; SCKCR3: System clock switch to HOCO
        mov.w   #0xa500, 1022[r10]	; Disable writing to Clock, Operating Power and VRCR registers.
	/* All done with HOCO switch--CPU should be running at 50MHz for the rest of the initialization! */

	mov	#__datastart, r1
	mov	#__romdatastart, r2
	mov	#__romdatacopysize, r3
	smovf

	mov	#__bssstart, r1
	mov	#0, r2
	mov	#__bsssize, r3
	sstr.l

	/* Initialize data pointer register(s).
           Note: The registers used here should agree with the definition of
	   GP_BASE_REGNUM in gcc/config/rx/rx.h.
           Note: We are assuming that -mint-register has not been used when
	   compiling the application.  */
#ifdef _RX_PID
	/* Initialise the constant data pointer and small data pointers.  */
	mov	#__pid_base, r13
	mov	#__gp, r12
#else
	/* Initialise the small data area pointer.  */
	mov	#__gp, r13
#endif
	
	bsr.a	__rx_init

#ifdef PROFILE_SUPPORT	/* Defined in gcrt0.S.  */
	mov	# _start, r1
	mov	# _etext, r2
	bsr.a	__monstartup
#endif

	mov	#0, r1 /* argc */
	mov	#0, r2 /* argv */
	mov	#0, r3 /* envv */
	bsr.a	_main
.LFE2:

#ifdef PROFILE_SUPPORT
        mov      r1, r13       ; Save return code.
	bsr.a	__mcleanup
        mov     r13, r1
#endif

	bsr.a	_exit

	.global	_rx_run_preinit_array
	.type	_rx_run_preinit_array,@function
_rx_run_preinit_array:
	mov	#__preinit_array_start,r1
	mov	#__preinit_array_end,r2
	bra.a	_rx_run_inilist

	.global	_rx_run_init_array
	.type	_rx_run_init_array,@function
_rx_run_init_array:
	mov	#__init_array_start,r1
	mov	#__init_array_end,r2
	mov	#4, r3
	bra.a	_rx_run_inilist

	.global	_rx_run_fini_array
	.type	_rx_run_fini_array,@function
_rx_run_fini_array:
	mov	#__fini_array_start,r2
	mov	#__fini_array_end,r1
	mov	#-4, r3
	/* fall through */

_rx_run_inilist:
next_inilist:
	cmp	r1,r2
	beq.b	done_inilist
	mov.l	[r1],r4
	cmp	#-1, r4
	beq.b	skip_inilist
	cmp	#0, r4
	beq.b	skip_inilist
	pushm	r1-r3
	jsr	r4
	popm	r1-r3
skip_inilist:
	add	r3,r1
	bra.b	next_inilist
done_inilist:
	rts

	.section	.init,"ax"

	.global __rx_init
__rx_init:

	.section	.fini,"ax"

	.global __rx_fini
__rx_fini:
	bsr.a	_rx_run_fini_array

        .section .rodata
        .balign 4
        .global __pid_base
	.weak   __pid_base
__pid_base:   

        .section .sdata
        .balign 4
        .global __gp
	.weak   __gp
__gp:   

	.section .data
	.global ___dso_handle
	.weak   ___dso_handle
___dso_handle:
	.long	0

;;; Provide Dwarf unwinding information that will help GDB stop
;;; backtraces at the right place.  This is stolen from assembly
;;; code generated by GCC with -dA.
	.section	.debug_frame,"",@progbits
.Lframe0:
	.4byte	.LECIE0-.LSCIE0	; Length of Common Information Entry
.LSCIE0:
	.4byte	0xffffffff	; CIE Identifier Tag
	.byte	0x1	; CIE Version
	.ascii "\0"	; CIE Augmentation
	.uleb128 0x1	; CIE Code Alignment Factor
	.sleb128 -1	; CIE Data Alignment Factor
	.byte	0xd	; CIE RA Column
	.byte	0xc	; DW_CFA_def_cfa
	.uleb128 0xc
	.uleb128 0x3
	.byte	0x8d	; DW_CFA_offset, column 0xd
	.uleb128 0x3
	.p2align 2
.LECIE0:
.LSFDE0:
	.4byte	.LEFDE0-.LASFDE0	; FDE Length
.LASFDE0:
	.4byte	.Lframe0	; FDE CIE offset
	.4byte	.LFB2		; FDE initial location
	.4byte	.LFE2-.LFB2	; FDE address range
	.byte   0xf     	; DW_CFA_def_cfa_expression
	.uleb128 1		; length of expression
	.byte 	0x30		; DW_OP_lit0
	.p2align 2
.LEFDE0:

	.text
