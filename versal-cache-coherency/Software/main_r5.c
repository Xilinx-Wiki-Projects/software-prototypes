/*
 * Copyright (C) 2022, Advanced Micro Devices, Inc. All rights reserved.
 * SPDX-License-Identifier: MIT
 */

#include "xil_io.h"
#include "xil_cache.h"

#include "xscugic.h"
#include "xipipsu.h"

/* Global Instances of GIC and IPI devices */
XScuGic GicInst;
XIpiPsu IpiInst;

void DataAbortHandler(void *CallBackRef)
{
}

void IpiIntrHandler(void *XIpiPsuPtr)
{
	u32 IpiSrcMask;
	u32 TmpBufPtr[3] = { 0 };

	u32 SrcIndex;
	XIpiPsu *InstancePtr = (XIpiPsu *) XIpiPsuPtr;

	IpiSrcMask = XIpiPsu_GetInterruptStatus(InstancePtr);

	/* Poll for each source */
	for (SrcIndex = 0U; SrcIndex < InstancePtr->Config.TargetCount;
			SrcIndex++) {

		if (IpiSrcMask & InstancePtr->Config.TargetList[SrcIndex].Mask) {

			/* Read Incoming Message Buffer Corresponding to Source CPU */
			XIpiPsu_ReadMessage(InstancePtr,
					InstancePtr->Config.TargetList[SrcIndex].Mask, TmpBufPtr,
					3, XIPIPSU_BUF_TYPE_MSG);

			u8* SrcBuffer = (u8*)TmpBufPtr[0];
			u8* DstBuffer = (u8*)TmpBufPtr[1];
			for (int Index = 0; Index < TmpBufPtr[2]; Index++) {
				DstBuffer[Index] = SrcBuffer[Index];
			}

			/* Clear the Interrupt Status */
			XIpiPsu_ClearInterruptStatus(InstancePtr,
					InstancePtr->Config.TargetList[SrcIndex].Mask);

		}
	}
}

int main (void)
{
	XIpiPsu_Config *CfgPtr;
	XScuGic_Config *IntcConfig;

	/* Register abort handler to check write operation failure */
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_DATA_ABORT_INT, &DataAbortHandler, NULL);

	/* Disable DCache to ensure access to DDR is performed */
	Xil_DCacheDisable();

	/* Look Up the config data */
	CfgPtr = XIpiPsu_LookupConfig(XPAR_XIPIPSU_0_DEVICE_ID);

	/* Init with the Cfg Data */
	XIpiPsu_CfgInitialize(&IpiInst, CfgPtr, CfgPtr->BaseAddress);

	/* Initialize the interrupt controller driver */
	IntcConfig = XScuGic_LookupConfig(XPAR_SCUGIC_0_DEVICE_ID);

	XScuGic_CfgInitialize(&GicInst, IntcConfig, IntcConfig->CpuBaseAddress);

	/*
	 * Connect the interrupt controller interrupt handler to the
	 * hardware interrupt handling logic in the processor.
	 */
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
			(Xil_ExceptionHandler) XScuGic_InterruptHandler, &GicInst);

	/*
	 * Connect a device driver handler that will be called when an
	 * interrupt for the device occurs, the device driver handler
	 * performs the specific interrupt processing for the device
	 */
	XScuGic_Connect(&GicInst, IpiInst.Config.IntId,
			(Xil_InterruptHandler) IpiIntrHandler, (void *) &IpiInst);

		/* Enable the interrupt for the device */
	XScuGic_Enable(&GicInst, IpiInst.Config.IntId);

	/* Enable interrupts */
	Xil_ExceptionEnable();

	/* Enable reception of IPIs from all CPUs */
	XIpiPsu_InterruptEnable(&IpiInst, XIPIPSU_ALL_MASK);

	/* Clear Any existing Interrupts */
	XIpiPsu_ClearInterruptStatus(&IpiInst, XIPIPSU_ALL_MASK);

	/* Loop forever */
	while(1);
}
