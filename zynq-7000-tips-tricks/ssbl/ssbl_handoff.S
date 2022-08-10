/******************************************************************************
*
* Copyright (c) 2012 - 2020 Xilinx, Inc.  All rights reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
/*****************************************************************************/
/**
*
* @file handoff.S
*
* Contains the code that does the handoff to the loaded application.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver	Who	Date.word	Changes
* ----- ---- -------- -------------------------------------------------------
* 1.00a ecm	03/01/10 Initial release
* 7.00a kc	10/23/13 Added support for armcc compiler
* </pre>
*
* @note
* Assumes that the starting address of the FSBL is provided by the calling routine
* in R0.
*
******************************************************************************/

.globl SsblHandoffJtagExit

.globl SsblHandoffExit

.section .handoff,"axS"

/***************************** Include Files *********************************/

/************************** Constant Definitions *****************************/

/**************************** Type Definitions *******************************/

/***************** Macros (Inline Functions) Definitions *********************/

/************************** Function Prototypes ******************************/

/************************** Variable Definitions *****************************/

SsblHandoffExit:
		mov	 lr, r0	/* move the destination address into link register */

		mcr	 15,0,r0,cr7,cr5,0		/* Invalidate Instruction cache */
		mcr	 15,0,r0,cr7,cr5,6		/* Invalidate branch predictor array */

		dsb
		isb					/* make sure it completes */

	ldr	r4, =0
		mcr	 15,0,r4,cr1,cr0,0		/* disable the ICache and MMU */

		isb					/* make sure it completes */


		bx		lr	/* force the switch, destination should have been in r0 */

.Ldone: b		.Ldone					/* Paranoia: we should never get here */
.end

