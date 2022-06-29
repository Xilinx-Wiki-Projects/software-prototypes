/******************************************************************************
* Copyright (c) 2019 - 2020 Xilinx, Inc.  All rights reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/

/*
 * This example is based on the xilmailbox_example.c source file from the
 * xilmailbox library.
 *
 * This application works in conjunction with changes to the PLM which cause  it
 * to send an IPI message at a specified rate to this application running on the
 * R5. This application then sends an IPI message back to the PLM.
 *
 * The PLM application sends a trip counter in the message that is received by
 * this application. This application then sends a message with the trip counter
 * incremented.  The trip counter is divided down by this application for display
 * at a one second rate for simplicity of testing.
 *
 * The messages from the PLM to the R5 is a free form message with only a single
 * 32 bit word containing the trip counter while the message sent from this
 * application to the PLM is a format specific to the PLM as described below
 * in the application.
 */

#include <stdlib.h>
#include "xparameters.h"
#include "xilmailbox.h"

#define TEST_CHANNEL_ID		XPAR_XIPIPSU_0_DEVICE_ID
#define REMOTE_IPI_MASK		2  	/* PLM on PMC IPI Mask */

#define XPLMI_MODULE_USER_ID 13U /* must be in sync with PLM xplmi_modules.h */
#define XUSER_R5 			 0U	 	/* must be in sync with PLM demo command id */

#define	MSG_PERIOD_MS		100U
#define COUNTS_PER_PERIOD	2
#define ONE_SECOND			((1000 / MSG_PERIOD_MS) * COUNTS_PER_PERIOD)

XMailbox XMboxInstance;
volatile static int RecvDone = 0;
volatile static int ErrorStatus = 0;

static void DoneHandler(void *CallBackRefPtr);
static void ErrorHandler(void *CallBackRefPtr, u32 Mask);

int main(void)
{
	u32 Status;
	u32 RequestBuffer[2] = { 0 };
	u32 ResponseBuffer[1];

	/* Initialize the mailbox library to use the IPI of the CPU and
	 * register callbacks for read completion and errors
	 */
	Status = XMailbox_Initialize(&XMboxInstance, TEST_CHANNEL_ID);
	if (Status != XST_SUCCESS) {
		xil_printf("Mailbox Initialization Failed\n\r");
		return Status;
	}

	XMailbox_SetCallBack(&XMboxInstance, XMAILBOX_RECV_HANDLER,
			     (void *)DoneHandler, (void *)&XMboxInstance);
	XMailbox_SetCallBack(&XMboxInstance, XMAILBOX_ERROR_HANDLER,
			     (void *)ErrorHandler, (void *)&XMboxInstance);

	/* Loop forever receiving an IPI message from the PLM which
	 * contains a counter and sending an IPI message back to the PLM
	 */
	while (1) {

		if (RequestBuffer[0] != 0) {

			/* Wait for an IPI message to be received, then go get the data from
			 * the IPI request buffer, the request from the PLM is only 1 word with no
			 * predefined structure and the one word being the trip counter
			 */
			ErrorStatus = 0;
			RecvDone = 0;
			while(!ErrorStatus && !RecvDone);

			Status = XMailbox_Recv(&XMboxInstance, REMOTE_IPI_MASK, RequestBuffer,
						   sizeof(RequestBuffer) / sizeof(u32), XILMBOX_MSG_TYPE_REQ);
			if (Status != XST_SUCCESS) {
				xil_printf("Reading an IPI Resp message Failed\n\r");
				break;
			}
		}

		/* Every 1 second worth of messages print out the trip counter that
		 * is received from the PLM to act as a seconds counter
		 */
		if ((RequestBuffer[0] % ONE_SECOND) == 0)
			xil_printf("On R5: Seconds: %d Payload: %d\r\n", RequestBuffer[0] / ONE_SECOND, RequestBuffer[0]);

		/* Build request message ready to send to the PLM using the message structure of
		 * the xplmi of the PLM which is the command API ID in the least significant
		 * byte of the 1st word and the module ID is the next significant byte of the 1st
		 * word. The payload of the command (the trip counter) starts in the next 32 bit
		 * word for the message and since the same request buffer is being used in both
		 * directions make sure to get the trip counter moved before overwriting it.
		 */
		RequestBuffer[1] = RequestBuffer[0] + 1;
		RequestBuffer[0] = XPLMI_MODULE_USER_ID << 8 | XUSER_R5;

		/* Send the command request to the PLM blocking to wait for the command
		 * response.
		 */
		Status = XMailbox_SendData(&XMboxInstance, REMOTE_IPI_MASK, RequestBuffer,
					   sizeof(RequestBuffer) / sizeof(u32), XILMBOX_MSG_TYPE_REQ, 1);
		if (Status != XST_SUCCESS) {
			xil_printf("Sending Req Message Failed\n\r");
			break;
		}

		/* There is no IPI interrupt that is triggered for the request response from the PLM
		 * and the previous API provided blocking to ensure it's done on the target.
		 * Get the IPI message from the IPI response buffer and check the
		 * status of the command response to make sure there is not a failure
		 */
		Status = XMailbox_Recv(&XMboxInstance, REMOTE_IPI_MASK, ResponseBuffer,
					   sizeof(ResponseBuffer) / sizeof(u32), XILMBOX_MSG_TYPE_RESP);
		if (Status != XST_SUCCESS) {
			xil_printf("Reading an IPI Req message Failed\n\r");
			break;
		}

		if (ResponseBuffer[0] != XST_SUCCESS)
			xil_printf("Command failure, Status: 0x%08X\r\n", ResponseBuffer[0]);
	}
	return Status;
}

static void DoneHandler(void *CallBackRef)
{
	RecvDone = 1;
}

static void ErrorHandler(void *CallBackRef, u32 Mask)
{
	ErrorStatus = Mask;
}
