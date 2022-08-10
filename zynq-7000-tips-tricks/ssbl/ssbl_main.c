/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * Trampoline Application
 *
 * The purpose of this app is load the primary application into memory
 * and start it.  When the primary application is running in XIP mode from
 * QSPI flash memory only the data of the application is loaded.
 *
 * FSBL authenticates signed partitions in flash memory for XIP partitions,
 * loads this application into high OCM and then starts this application.
 *
 * When this application starts OCM is no longer being used by FSBL such that
 * this app remaps low OCM up high and then copies the primary app data from
 * flash into high OCM while not overwriting itself.
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "xil_cache.h"

#define OCM_HIGH_ADDR 				0xFFFC0000
#define FLASH_DATA_PTR_ADDR			0xFFFF0000
#define HANDOFF_PTR_ADDR			0xFFFF0004
#define LOW_OCM_SIZE				(192 * 1024)

int main()
{
	int i;
	u32 *src, *dest;

    print("SSBL running from high OCM\n\r");

    /* Map OCM from low to high as the primary app data is linked for high OCM.
     * Unlock the SLCR, read the remap register to keep bit 4 unchanged,
     * remap OCM and relock the SLCR
     */
    Xil_Out32(0xF8000008, 0xDF0D);
	u32 ocm_cfg = Xil_In32(0xF8000910);
	Xil_Out32(0xF8000910, (ocm_cfg | 0xF));
    Xil_Out32(0xF8000004, 0x767B);

    /* Copy the data for the program from QSPI to high OCM as the program is running
     * XIP from QSPI but needs RAM for data
     */
    src = *(u32 *)FLASH_DATA_PTR_ADDR;
    dest = (u32 *)OCM_HIGH_ADDR;
    for (i = 0; i < LOW_OCM_SIZE / 4; i++)
    	*dest++ = *src++;

    xil_printf("Handing off to XIP in QSPI at: 0x%08X\r\n", *(u32 *)HANDOFF_PTR_ADDR);

	SsblHandoffExit(*(u32 *)HANDOFF_PTR_ADDR);

    return 0;
}
