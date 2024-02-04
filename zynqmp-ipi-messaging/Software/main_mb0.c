/*
 * Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
 * SPDX-License-Identifier: MIT
 */

#include "xparameters.h"
#include "xil_exception.h"
#include "xil_cache.h"
#include "xintc.h"

#define XPAR_XIPIPS_TARGET_PSU_PMU_0_CH0_MASK 0x10000
#define XIPIPSU_ALL_MASK 0x0F0F0301U

#define IPI_PMUTOMB_REQ_BUFF 0xff990EC0
#define IPI_PMUTOMB_RES_BUFF 0xff990EE0
#define IPI_MBTOPMU_REQ_BUFF 0xFF9907C0

#define IPI_MB_TRIG 0xff340000
#define IPI_MB_ISR 0xff340010
#define IPI_MB_IER 0xff340018

#define XPFW_IPI_ID 0x1EU

XIntc InterruptController;	/* Instance of the Interrupt Controller */

void InterruptHandler(void)
{
	u32 TmpBufPtr[] = { 0 }; /**< Holds the received Message, later inverted and sent back as response*/
	u32 *SrcBufferPtr = (u32*)IPI_PMUTOMB_REQ_BUFF;
	u32 *DstBufferPtr = (u32*)IPI_PMUTOMB_RES_BUFF;
	u32 Index;

	/* Copy the IPI Buffer contents into Users's Buffer*/
	for (Index = 0U; Index < (sizeof(TmpBufPtr)/sizeof(*TmpBufPtr)); Index++) {
		TmpBufPtr[Index] = SrcBufferPtr[Index];
	}

	/* Copy the Message to IPI Buffer */
	for (Index = 0U; Index < (sizeof(TmpBufPtr)/sizeof(*TmpBufPtr)); Index++) {
		DstBufferPtr[Index] = TmpBufPtr[Index];
	}

	/* Clear the Interrupt Status - This clears the OBS bit on the SRC CPU registers */
	Xil_Out32(IPI_MB_ISR, ~0);
}

int main (void)
{
	/* Initialize the interrupt controller driver */
	XIntc_Initialize(&InterruptController, XPAR_INTC_0_DEVICE_ID);

	/*
	 * Connect the handler that will be called when an interrupt
	 * for the device occurs, the handler defined above performs the
	 * specific interrupt processing for the device.
	 */
	XIntc_Connect(&InterruptController, 0,
		(XInterruptHandler) InterruptHandler, NULL);

	XIntc_Start(&InterruptController, XIN_REAL_MODE);

	/* Enable the interrupt for IPI */
	XIntc_Enable(&InterruptController, 0);
	Xil_Out32(IPI_MB_IER, XIPIPSU_ALL_MASK);

	/* Register the interrupt controller handler with the exception table. */
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
		(Xil_ExceptionHandler) XIntc_InterruptHandler, &InterruptController);

	/* Initialize the exception table */
	Xil_ExceptionInit();

	/* Enable interrupts */
	Xil_ExceptionEnable();

	/* Write message with the IPI module ID */
	Xil_Out32(IPI_MBTOPMU_REQ_BUFF, (XPFW_IPI_ID << 16));
	Xil_Out32(IPI_MB_TRIG, XPAR_XIPIPS_TARGET_PSU_PMU_0_CH0_MASK);

	while(1);
	return 0;
}
