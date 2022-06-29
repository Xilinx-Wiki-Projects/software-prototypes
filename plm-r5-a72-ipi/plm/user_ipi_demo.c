/******************************************************************************
* Copyright (c) 2022 Xilinx, Inc.  All rights reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/

/* Introduction
 *
 * The following module contains functionality to run in the PLM to demonstrate
 * user IPI messaging to/from remote CPUs in Versal.
 *
 * This prototype assumes the user has knowledge and experience with IPI
 * messaging as defined in the Versal TRM. The hardware provides a mesh network
 * in which a CPU (source) can message another CPU (destination). The source
 * CPU writes into a request buffer then cause an interrupt to the destination
 * CPU. The destination CPU gets the interrupt, reads the request, and then
 * writes into a response buffer, and lastly acknowledges the interrupt. The
 * acknowledge of the interrupt can be seen by the source CPU to indicate the
 * response is complete but there is no interrupt for this response complete
 * such that polling is used. The response time of the destination CPU must
 * be taken into account.
 *
 * PLM Operation
 *
 * Note the PLM is a server for many system services in the Versal system.
 * It must remain responsive to prevent hanging CPUs when they request a
 * service. The CPUs assume the PLM is always up and responsive in a
 * reasonable time. The PLM architecture is a single threaded design
 * with run to completion tasks such that periodic tasks must be designed
 * for this. Run to completion requires that longer duration work loads
 * must be performed with multiple executions of the task, entering and
 * exiting each time, and maintaining state across the multiple executions.
 *
 * IPI messages received by the PLM must be formated in the expect format
 * expected by the xplmi library used by the PLM application. This format
 * includes module and command IDs in specific words of the request as
 * described in this application.
 *
 * IPI messages sent from the PLM to another CPU have no expected format
 * by the PLM and in this prototype the only data is a trip counter.
 *
 * Prototype Details
 *
 * This prototype must be supported with R5 baremetal/FreeRTOS and A72 Linux
 * applications which are in sync with regards to the supported configuration.
 *
 * This prototype supports several message options for illustration purposes.
 * The PLM and R5 send IPI messages in both directions (birectional) with
 * each IPI message including a request and a response.
 *
 * The A72 IPI messaging has two options which are mutually exclusive and
 * configurable at build time. The default option is for the A72 to send IPI
 * messages with a request to the PLM and the PLM to respond to the request
 * which is defined as unidirectional (one source/one destination).
 *
 * Another option can be built at compile time by setting PLM_2_A72_UNIDIRECT
 * to cause the PLM to send IPI messages to the A72 with the A72 responding to
 * the request which is also unidirectional.
 *
 * With all options a trip counter is sent by the source CPU in the IPI request.
 * The trip counter is intended to be incremented in each direction of flow
 * to easily illustrate successful messaging. The destination CPU increments
 * the trip counter before sending it back to the source CPU regardless of
 * the messaging options (bidirectional vs unidirectional).
 *
 * The application CPU (R5 or A72) can print out the received trip counter at
 * a lower rate based on the message rate to demonstrate a one second counter.
 *
 * PLM Implementation Details
 *
 * This code assumes a new PLM module ID is added to the module list of the
 * xplmi library.  An existing module ID, such as the PLM SEM module ID, can be
 * reused if that module is not being built into the PLM.
 *
 * This code depends on a Vivado system where the application CPUs (R5/A72)
 * are setup to use specific IPI channels and the IPI mask must be adjusted
 * appropriately. The IPI mask maps to the interrupts of the IPI channels.
 */

#include "xplmi.h"
#include "xplmi_cmd.h"
#include "xplmi_modules.h"
#include "xplmi_scheduler.h"

#define XUSER_API(ApiId)		((u32)ApiId)
#define XUSER_API_ID_MASK		0xFFU

#define A72_IPI_MASK			0x20 	// IPI 3
#define R5_IPI_MASK				0x8		// IPI 1

#define NO_BLOCK				0U		// A zero timeout does not block
#define	TASK_PERIOD_MS			10U		// Should be less than or equal to MSG_PERIOD_MS
#define	MSG_PERIOD_MS			100U
#define	FIVE_SECONDS			(5000 / TASK_PERIOD_MS)

/* Unidirectional is defined as only one IPI message with a request and response
 * going from one CPU to another, with the PLM sending a request to the A72 and
 * the A72 returning a response to the request.
 */
// #define PLM_2_A72_UNIDIRECT

/* Create the command structure and module for xplmi to allow IPI messages to be
 * handled and passed to this module.  A module ID is required and can be an existing
 * module, such as the SEM module ID if it is unused, or a new module ID must be
 * defined in the xplmi library.
 */
typedef enum {
	XUSER_R5  = 0U,			/**< API id for R5 command */
	XUSER_A72,				/**< API id for A72 command */
	XUSER_API_MAX,			/**< Number of API features */
} ApiId;

static XPlmi_ModuleCmd UserCmds[XUSER_API_MAX];

static XPlmi_Module UserModule =
{
	XPLMI_MODULE_USER_ID,		// Customized xplmi library by adding a module for users
	UserCmds,
	XUSER_API(XUSER_API_MAX),
	NULL,
};

/* A trip counter is passed to between CPUs where it is expected to be
 * incremented by each CPU. The trip counter is expected to be indexed
 * by the ApiId enumeration. The IPI API uses word counts rather than
 * byte counts.
 */
static u32 TripCounter[2];
#define TRIP_COUNT_SIZE (sizeof(u32) / sizeof(u32))

/* The following function is called by the xplmi processing for each
 * command received for the user module.  Note that the command structure
 * using xplmi is such that the first word of the message contains the
 * command API ID in the least signficant byte and the module ID is in
 * the 2nd byte. The payload for the command starts in the 2nd 32 bit
 * word of the message.
 */
static int ProcessCmd(XPlmi_Cmd *Cmd)
{
	int Status = XST_INVALID_PARAM;
	u32 *Pload = Cmd->Payload;

	/* Handle the commands defined for this user module, two
	 * commands which receive a message from another CPU containing
	 * a counter which is then sent back to the CPU as a trip counter
	 */
	switch (Cmd->CmdId & XUSER_API_ID_MASK) {
		case XUSER_API(XUSER_R5):
			TripCounter[XUSER_R5] = Pload[0] + 1;
			Cmd->Response[1] = Pload[0] + 1;
			Status = XST_SUCCESS;
			break;
		case XUSER_API(XUSER_A72):
			TripCounter[XUSER_A72] = Pload[0] + 1;
			Cmd->Response[1] = Pload[0] + 1;
			Status = XST_SUCCESS;
			break;
		default:
			xil_printf("%s: PLM IPI ERROR invalid parameter to command\n", __func__);
			break;
	}
	return Status;
}

/* The user task function is called by the PLM scheduler at some periodic
 * rate. The periodic task may be running at a faster rate (TASK_PERIOD_MS) than
 * the desired message rate (MSG_PERIOD_MS) to allow the run to completion
 * model.
 */
static int UserTask(void *Arg)
{
	XStatus Status;
	static int ExecutionCount = 0;
	static int Waiting = 0;

	/* The periodic task may be running at a faster rate (TASK_PERIOD_MS) than
	 * the desired message rate (MSG_PERIOD_MS) to allow the run to completion
	 * model with multi-pass so only send a message at the desired message rate.
	 */
	if ((ExecutionCount % (MSG_PERIOD_MS / TASK_PERIOD_MS)) == 0) {

		/* For the R5 CPU, write the counter to the IPI buffer before triggering
		 * the IPI to the other CPU
		 */
		Status = XPlmi_IpiWrite(R5_IPI_MASK, &TripCounter[XUSER_R5], TRIP_COUNT_SIZE,
					XIPIPSU_BUF_TYPE_MSG);
		if (XST_SUCCESS != Status)
			xil_printf("%s: PLM IPI ERROR writing to R5 IPI request buffer\n", __func__);

		Status = XPlmi_IpiTrigger(R5_IPI_MASK);
		if (XST_SUCCESS != Status)
			xil_printf("%s: PLM IPI ERROR triggering IPI to R5 CPU\n", __func__);

#ifdef PLM_2_A72_UNIDIRECT

		/* The Linux application on the A72 should be only accepting IPI interrupts
		 * being the destination of IPI messages and it should not be the source of
		 * IPI messages as this assumes a request from the PLM and the response
		 * from the A72 in a single IPI message. The following does not implement
		 * any error handling for when the A72 does not respond which would be a
		 * application specific.
		 */

#ifdef A72_ERROR
		/* The A72 should have responded so that the state is no longer waiting
		 * for a response, but if it is then keep going other than notification
		 * at a very slow rate as the Linux app is started once Linux is up.
		 * The PLM output is ugly interspersed into the R5 output so don't use
		 * this by default.
		 */
		if (Waiting && ((ExecutionCount % FIVE_SECONDS) == 0))
			xil_printf("%s: PLM IPI ERROR A72 did not respond\n", __func__);
#endif
		/*
		 * Write the counter to the IPI buffer before causing an interrupt for IPI
		 * to the A72
		 */
		Status = XPlmi_IpiWrite(A72_IPI_MASK, &TripCounter[XUSER_A72], TRIP_COUNT_SIZE,
					XIPIPSU_BUF_TYPE_MSG);
		if (XST_SUCCESS != Status)
			xil_printf("%s: PLM IPI ERROR writing to A72 IPI request buffer\n", __func__);

		Status = XPlmi_IpiTrigger(A72_IPI_MASK);
		if (XST_SUCCESS != Status)
			xil_printf("%s: PLM IPI ERROR triggering IPI to A72 CPU\n", __func__);

		Waiting = 1;
	}

	/* Assuming no response from the A72 yet (waiting), try to get a response
	 * from the A72 without blocking (NO_BLOCK) for any time knowing that it may
	 * take several passes of each time period this function is called to get
	 * a response.
	 */
	if (Waiting) {

		Status = XPlmi_IpiPollForAck(A72_IPI_MASK, NO_BLOCK);

		/* When the destination has processed the request and given a response then
		 * get the response which is the trip counter
		 */
		if (XST_SUCCESS == Status) {
			Status = XPlmi_IpiRead(A72_IPI_MASK, &TripCounter[XUSER_A72], TRIP_COUNT_SIZE,
					XIPIPSU_BUF_TYPE_RESP);
			if (XST_SUCCESS != Status)
				xil_printf("%s: PLM IPI ERROR triggering IPI to A72 CPU\n", __func__);

			TripCounter[XUSER_A72]++;
			Waiting = 0;
		}
#endif
	}

	ExecutionCount++;

	return 0;
}

/* Initialize the user processing to cause IPIs to be received and sent with xplmi in the PLM
 * This function must be called from XPlm_ModuleInit() in the PLM.
 */
void User_Init(void)
{
	int i;
	XStatus Status;

	/* Initialize each command handler of the module to call the user command processor
	 * and then register the user module with xplmi to cause IPI messages to be valid
	 */
	for (i = 0; i < UserModule.CmdCnt; i++) {
		UserCmds[i].Handler = ProcessCmd;
	}
	XPlmi_ModuleRegister(&UserModule);

	/* Start a scheduler task for periodic execution to send messages to the remote CPU making
	 * it a lower priority (1) rather than a higher priority at 0
	 */
	Status = XPlmi_SchedulerAddTask(XPLMI_MODULE_USER_ID, UserTask, NULL,
			TASK_PERIOD_MS, XPLM_TASK_PRIORITY_1, NULL, XPLMI_PERIODIC_TASK);
	if (XST_SUCCESS != Status)
		xil_printf("%s: PLM IPI ERROR adding scheduled task\n", __func__);
}
