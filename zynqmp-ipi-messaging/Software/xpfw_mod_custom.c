#include "xpfw_core.h"
#include "xpfw_module.h"
#include "xpfw_ipi_manager.h"

#define XPFW_IPI_ID 0x1EU
#define XPFW_IPI_MSG_SEND_TIME 5000

#define CHANNELS (sizeof(channel)/sizeof(*channel))

typedef struct ipi_ch {
	u32 mask;
	u32 init;
	char name[5];
} ipi_ch_t;

static u32 cnt = 0;
const XPfw_Module_t *IpiModPtr;

/* IPI Channels used in the example */
ipi_ch_t channel[] = {
		{IPI_PMU_0_IER_RPU_0_MASK, 0, "RPU0"},
		{IPI_PMU_0_IER_RPU_1_MASK, 0, "RPU1"},
		{1<<24, 0, "MB0"}, // Microblaze #0 assigned to PL0
		{1<<25, 0, "MB1"}, // Microblaze #1 assigned to PL1
		{1<<27, 0, "APU"}  // APU assigned to PL3
};

static void IpiHandler(const XPfw_Module_t *ModPtr, u32 IpiNum, u32 SrcMask, const u32* Payload, u8 Len)
{
	for(u32 idx=0; idx < CHANNELS; idx++) {
		if((channel[idx].mask == SrcMask) && (channel[idx].init == 0)) {
			channel[idx].init = 1;
			XPfw_Printf(DEBUG_PRINT_ALWAYS,"PMUFW: IPI received from %s\r\n", channel[idx].name);
		}
	}
}

static void XPfw_SendIpi(void)
{
	s32 Status;
	u32 MsgPtr[1] = {0};
	u32 RespPtr[1] = {0};

	/* Create message */
	MsgPtr[0] = cnt;  // Counter value

	/* Check if all the channels have been initialized */
	for(u32 idx = 0; idx < CHANNELS; idx++) {
		if(!channel[idx].init) {
			return;
		}
	}

	/* Send IPI Message to each channel */
	for(u32 idx = 0; idx < CHANNELS; idx++) {

		XPfw_Printf(DEBUG_PRINT_ALWAYS, "PMUFW ModIPI: Send message number %d to %s\r\n", cnt, channel[idx].name);

		Status = XPfw_IpiWriteMessage(IpiModPtr, channel[idx].mask, MsgPtr, sizeof(MsgPtr)/sizeof(MsgPtr[1]));
		if(XST_SUCCESS != Status) {
			XPfw_Printf(DEBUG_ERROR, "PMUFW ModIPI: IPI Write Message failed\r\n", idx);
			break;
		}

		Status = XPfw_IpiTrigger(channel[idx].mask);
		if(XST_SUCCESS != Status) {
			XPfw_Printf(DEBUG_ERROR, "PMUFW ModIPI: IPI %d Trigger failed\r\n", idx);
			break;
		}

		Status = XPfw_IpiPollForAck(channel[idx].mask, 100);
		if(XST_SUCCESS != Status) {
			XPfw_Printf(DEBUG_ERROR, "PMUFW ModIPI: IPI %d Poll for ACK Timeout\r\n", idx);
			break;
		}

		Status = XPfw_IpiReadResponse(IpiModPtr, channel[idx].mask, RespPtr, sizeof(RespPtr)/sizeof(RespPtr[1]));
		if(XST_SUCCESS != Status) {
			XPfw_Printf(DEBUG_ERROR, "PMUFW ModIPI: IPI %d Read Response failed\r\n", idx);
			break;
		}

		if((RespPtr[0] & 0xFFFF) != cnt) {
			XPfw_Printf(DEBUG_ERROR, "PMUFW ModIPI: IPI %d Response invalid\r\n", idx);
			break;
		}

		XPfw_Printf(DEBUG_PRINT_ALWAYS, "PMUFW ModIPI: Received message number %d from %s\r\n", cnt, channel[idx].name);
	}

	cnt++;
}

static void IpiModCfgInit(const XPfw_Module_t *ModPtr, const u32 *CfgData, u32 Len)
{
	XPfw_CoreScheduleTask(ModPtr, XPFW_IPI_MSG_SEND_TIME, XPfw_SendIpi);
}

void ModCustomInit(void)
{
	IpiModPtr = XPfw_CoreCreateMod();

	XPfw_CoreSetCfgHandler(IpiModPtr, IpiModCfgInit);
	XPfw_CoreSetIpiHandler(IpiModPtr, IpiHandler, XPFW_IPI_ID);
}
