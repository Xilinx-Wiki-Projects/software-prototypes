/*
 * Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
 * SPDX-License-Identifier: MIT
 */

#include "xparameters.h"
#include "xil_exception.h"
#include "xil_cache.h"
#include "xscugic.h"
#include "xipipsu.h"
#include "xipipsu_hw.h"

#define XPFW_IPI_ID 0x1EU

XScuGic GicInst;
XIpiPsu IpiInst;

void IpiIntrHandler(void *XIpiPsuPtr)
{
	u32 SrcIndex;
	XIpiPsu *InstancePtr = (XIpiPsu *) XIpiPsuPtr;

	u32 TmpBufPtr[] = { 0 };
	u32 IpiSrcMask = XIpiPsu_GetInterruptStatus(InstancePtr);

	/* Poll for each source */
	for (SrcIndex = 0U; SrcIndex < InstancePtr->Config.TargetCount;	SrcIndex++) {

		if (IpiSrcMask & InstancePtr->Config.TargetList[SrcIndex].Mask) {

			/*  Read Incoming Message Buffer Corresponding to Source CPU */
			XIpiPsu_ReadMessage(InstancePtr,
					InstancePtr->Config.TargetList[SrcIndex].Mask, TmpBufPtr,
					sizeof(TmpBufPtr) / sizeof(*TmpBufPtr), XIPIPSU_BUF_TYPE_MSG);

			/* Send Response */
			XIpiPsu_WriteMessage(InstancePtr,
					InstancePtr->Config.TargetList[SrcIndex].Mask, TmpBufPtr,
					sizeof(TmpBufPtr) / sizeof(*TmpBufPtr), XIPIPSU_BUF_TYPE_RESP);

			/* Clear the Interrupt Status - This clears the OBS bit on teh SRC CPU registers */
			XIpiPsu_ClearInterruptStatus(InstancePtr,
					InstancePtr->Config.TargetList[SrcIndex].Mask);
		}
	}
}

int main() {

	/* Wait for pretty printing after FSBL */
	usleep(100);

	/* Initialize the IPI driver */
	XIpiPsu_Config * CfgPtr = XIpiPsu_LookupConfig(XPAR_XIPIPSU_0_DEVICE_ID);
	XIpiPsu_CfgInitialize(&IpiInst, CfgPtr, CfgPtr->BaseAddress);

	/* Initialize the interrupt controller driver */
	XScuGic_Config *IntcConfig = XScuGic_LookupConfig(XPAR_SCUGIC_0_DEVICE_ID);
	XScuGic_CfgInitialize(&GicInst, IntcConfig, IntcConfig->CpuBaseAddress);

	/*
	 * Connect the interrupt controller interrupt handler to the
	 * hardware interrupt handling logic in the processor.
	 */
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
			(Xil_ExceptionHandler) XScuGic_InterruptHandler, &GicInst);

	XScuGic_Connect(&GicInst, IpiInst.Config.IntId,
			(Xil_InterruptHandler) IpiIntrHandler, (void *) &IpiInst);

	/* Enable the interrupt for the device */
	XScuGic_Enable(&GicInst, IpiInst.Config.IntId);

	/* Enable reception of IPIs from all CPUs */
	XIpiPsu_InterruptEnable(&IpiInst, XIPIPSU_ALL_MASK);
	XIpiPsu_ClearInterruptStatus(&IpiInst, XIPIPSU_ALL_MASK);

	/* Enable interrupts */
	Xil_ExceptionEnable();

	/* Create message with the IPI module ID */
	u32 TmpBufPtr[] = { XPFW_IPI_ID << 16 };

	XIpiPsu_WriteMessage(&IpiInst, XPAR_XIPIPS_TARGET_PSU_PMU_0_CH0_MASK, TmpBufPtr, sizeof(TmpBufPtr) / sizeof(*TmpBufPtr), XIPIPSU_BUF_TYPE_MSG);
	XIpiPsu_TriggerIpi(&IpiInst, XPAR_XIPIPS_TARGET_PSU_PMU_0_CH0_MASK);

	do {
		/**
		 * Do Nothing
		 * We need to loop on to receive IPIs and respond to them
		 */
		__asm("wfi");
	} while (1);

	/* Control never reaches here */
	return 0;

}
