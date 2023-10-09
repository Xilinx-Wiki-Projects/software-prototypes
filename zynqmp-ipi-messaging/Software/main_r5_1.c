/*
 * Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
 * SPDX-License-Identifier: MIT
 */

#include "xparameters.h"
#include "xil_exception.h"
#include "xil_cache.h"
#include "xilmailbox.h"

#define XPFW_IPI_ID 0x1EU

XScuGic GicInst;
XMailbox XMboxInstance;

static void MailboxHandler(void *CallBackRef)
{
	u32 Status = XST_FAILURE;
	u32 TmpBufPtr[] = { 0 };

	Status = XMailbox_Recv(&XMboxInstance, XPAR_XIPIPS_TARGET_PSU_PMU_0_CH0_MASK, TmpBufPtr, sizeof(TmpBufPtr) / sizeof(*TmpBufPtr), XILMBOX_MSG_TYPE_REQ);
	if (Status != XST_SUCCESS) {
		xil_printf("Reading an IPI Resp message Failed\n\r");
		return;
	}

	Status = XMailbox_SendData(&XMboxInstance, XPAR_XIPIPS_TARGET_PSU_PMU_0_CH0_MASK, TmpBufPtr, sizeof(TmpBufPtr) / sizeof(*TmpBufPtr), XILMBOX_MSG_TYPE_RESP, 0);
	if (Status != XST_SUCCESS) {
		xil_printf("Sending Req Message Failed\n\r");
		return;
	}
}

static void MailboxErrorHandler(void *CallBackRef, u32 Mask)
{
}

int main() {

	/* Wait for pretty printing after FSBL */
	usleep(100);

	/* Initialize the interrupt controller driver */
	XScuGic_Config *IntcConfig = XScuGic_LookupConfig(XPAR_SCUGIC_0_DEVICE_ID);
	XScuGic_CfgInitialize(&GicInst, IntcConfig, IntcConfig->CpuBaseAddress);

	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,(Xil_ExceptionHandler) XScuGic_InterruptHandler, &GicInst);
	Xil_ExceptionEnable();

	/* Initialize Mailbox */
	XMailbox_Initialize(&XMboxInstance, XPAR_XIPIPSU_0_DEVICE_ID);

	/* Set Mailbox callback handlers */
	XMailbox_SetCallBack(&XMboxInstance, XMAILBOX_RECV_HANDLER, (void *)MailboxHandler, (void *)&XMboxInstance);
	XMailbox_SetCallBack(&XMboxInstance, XMAILBOX_ERROR_HANDLER, (void *)MailboxErrorHandler, (void *)&XMboxInstance);

	/* Create message with the IPI module ID */
	u32 TmpBufPtr[] = { XPFW_IPI_ID << 16 };

	XMailbox_SendData(&XMboxInstance, XPAR_XIPIPS_TARGET_PSU_PMU_0_CH0_MASK, TmpBufPtr, sizeof(TmpBufPtr) / sizeof(*TmpBufPtr), XILMBOX_MSG_TYPE_REQ, 1);

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
