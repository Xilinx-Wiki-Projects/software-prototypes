/*
 * Copyright (C) 2022, Advanced Micro Devices, Inc. All rights reserved.
 * SPDX-License-Identifier: MIT
 */

#include "xil_io.h"
#include "xil_cache.h"
#include "xil_mmu.h"

#include "xzdma.h"
#include "xaxicdma.h"
#include "xgpio.h"
#include "xipipsu.h"

#define BUFFER_BYTESIZE	64

#define SNOOP_CONTROL_SI4	0xFD005000
#define ENABLE_SNOOP		0x1

#define PL_ACELITE_FPD_TZ	0xFD690118
#define PL_AXI_LPD_TZ		0xFF510050
#define DMA_Ch0_TZ		0xFF510060

#define DMA_Route		0xFE600014
#define PL_AXI_LPD_Route	0xFE600018
#define RPU0_Route		0xFE60001C

#define NORM_WB_OUT_CACHE	0x605UL

#define AXI_ATTR(prot, cache)	((prot << 4) | cache)

#define PROT_UP_S_D		0x0 /* Unprivileged, Secure, Data */
#define	CACHE_OA_M		0x6 /* Write-through No-allocate */

#define FPD_CHANNEL		1
#define LPD_CHANNEL		2
#define CCI0_CHANNEL	1
#define CCI1_CHANNEL	2

#if 1
/* DDR memory test */
static u8* SrcBuffer = (u8*)0x40000;
static u8* DstBuffer= (u8*)0x60000;
#else
/* OCM memory test*/
static u8* SrcBuffer = (u8*)0xfffc0000;
static u8* DstBuffer= (u8*)0xfffe0000;
#endif

XAxiCdma FpdCDma;
XAxiCdma LpdCDma;
XAxiCdma Cci0CDma;
XAxiCdma Cci1CDma;
XZDma ZDma;
XIpiPsu IpiInst;
XGpio Gpio;

u32 DestCpuMask;

static void initBuffers(u8 pattern)
{
	/* Initialize memory */
	for (int Index = 0; Index < BUFFER_BYTESIZE; Index++) {
		SrcBuffer[Index] = pattern;
		DstBuffer[Index] = 0x0;
	}
	Xil_DCacheFlushRange((UINTPTR)SrcBuffer, BUFFER_BYTESIZE);
	Xil_DCacheFlushRange((UINTPTR)DstBuffer, BUFFER_BYTESIZE);
}

static void FpdCdmaConfiguration(void)
{
	XAxiCdma_Config *CDmaConfig;

	CDmaConfig = XAxiCdma_LookupConfig(XPAR_AXICDMA_0_DEVICE_ID);
	XAxiCdma_CfgInitialize(&FpdCDma, CDmaConfig, CDmaConfig->BaseAddress);

	/* Set the AxPROT and AxCACHE signals */
	XGpio_Initialize(&Gpio, XPAR_GPIO_0_DEVICE_ID);
	XGpio_DiscreteWrite(&Gpio, FPD_CHANNEL, AXI_ATTR(PROT_UP_S_D, CACHE_OA_M));

	/* Set PL_ACELITE_FPD_TZ defined by PL */
	Xil_Out32(PL_ACELITE_FPD_TZ, 0x0);
}

static void LpdCdmaConfiguration(void)
{
	XAxiCdma_Config *CDmaConfig;

	CDmaConfig = XAxiCdma_LookupConfig(XPAR_AXICDMA_1_DEVICE_ID);
	XAxiCdma_CfgInitialize(&LpdCDma, CDmaConfig, CDmaConfig->BaseAddress);

	/* Set the AxPROT and AxCACHE signals */
	XGpio_Initialize(&Gpio, XPAR_GPIO_0_DEVICE_ID);
	XGpio_DiscreteWrite(&Gpio, LPD_CHANNEL, AXI_ATTR(PROT_UP_S_D, CACHE_OA_M));

	/* Set PL_AXI_LPD_TZ defined by PL */
	Xil_Out32(PL_AXI_LPD_TZ, 0x0);

	/* Route PL_AXI_LPD through CCI */
	Xil_Out32(PL_AXI_LPD_Route, 0x1);
}

static void CCI0CdmaConfiguration(void)
{
	XAxiCdma_Config *CDmaConfig;

	CDmaConfig = XAxiCdma_LookupConfig(XPAR_AXICDMA_2_DEVICE_ID);
	XAxiCdma_CfgInitialize(&Cci0CDma, CDmaConfig, CDmaConfig->BaseAddress);

	/* Set the AxPROT and AxCACHE signals */
	XGpio_Initialize(&Gpio, XPAR_GPIO_1_DEVICE_ID);
	XGpio_DiscreteWrite(&Gpio, CCI0_CHANNEL, AXI_ATTR(PROT_UP_S_D, CACHE_OA_M));
}

static void CCI1CdmaConfiguration(void)
{
	XAxiCdma_Config *CDmaConfig;

	CDmaConfig = XAxiCdma_LookupConfig(XPAR_AXICDMA_3_DEVICE_ID);
	XAxiCdma_CfgInitialize(&Cci1CDma, CDmaConfig, CDmaConfig->BaseAddress);

	/* Set the AxPROT and AxCACHE signals */
	XGpio_Initialize(&Gpio, XPAR_GPIO_1_DEVICE_ID);
	XGpio_DiscreteWrite(&Gpio, CCI1_CHANNEL, AXI_ATTR(PROT_UP_S_D, CACHE_OA_M));
}

static void LpdDmaConfiguration(void)
{
	XZDma_Config *DmaConfig;
	XZDma_DataConfig Configure;

	DmaConfig = XZDma_LookupConfig(XPAR_VERSAL_CIPS_0_PSPMC_0_PSV_ADMA_0_DEVICE_ID);
	XZDma_CfgInitialize(&ZDma, DmaConfig, DmaConfig->BaseAddress);

	XZDma_SetMode(&ZDma, FALSE, XZDMA_NORMAL_MODE);

	/* Configuration settings */
	Configure.SrcBurstType = XZDMA_INCR_BURST;
	Configure.SrcBurstLen = 0xF;
	Configure.DstBurstType = XZDMA_INCR_BURST;
	Configure.DstBurstLen = 0xF;
	Configure.SrcCache = CACHE_OA_M;
	Configure.DstCache = CACHE_OA_M;
	XZDma_SetChDataConfig(&ZDma, &Configure);

	/* Change TZ bit to be secure master */
	Xil_Out32(DMA_Ch0_TZ , 0x0);

	/* Route LPD DMA through CCI */
	Xil_Out32(DMA_Route , 0x1);
}

static void RpuConfiguration(void)
{
	XIpiPsu_Config *CfgPtr;

	CfgPtr = XIpiPsu_LookupConfig(XPAR_XIPIPSU_0_DEVICE_ID);
	XIpiPsu_CfgInitialize(&IpiInst, CfgPtr, CfgPtr->BaseAddress);

	DestCpuMask = CfgPtr->TargetList[1].Mask;

	/* Route RPU0 through CCI */
	Xil_Out32(RPU0_Route, 0x1);
}

int main (void)
{

	sleep(1);

	xil_printf("\r\n");
	xil_printf("************************************************************\r\n");
	xil_printf("Versal CCI-500 Coherency example\r\n");
	xil_printf("Source buffer 0x%p, Destination buffer 0x%p\r\n", SrcBuffer, DstBuffer);
	xil_printf("************************************************************\r\n");

	/* Enable snooping of APU caches from CCI */
	Xil_Out32(SNOOP_CONTROL_SI4, ENABLE_SNOOP);

	/* Set memory as outer cacheable */
	Xil_SetTlbAttributes((UINTPTR)DstBuffer, NORM_WB_OUT_CACHE);
	dsb();

	FpdCdmaConfiguration();
	LpdCdmaConfiguration();
	CCI0CdmaConfiguration();
	CCI1CdmaConfiguration();
	LpdDmaConfiguration();
	RpuConfiguration();

	/* Initialize buffers */
	xil_printf("\r\nPL FPD DMA Coherency Test\r\n");
	xil_printf("Source buffer pattern: 0x36\r\n");
	initBuffers(0x36);

	/* Write Cache */
	for (int Index = 0; Index < BUFFER_BYTESIZE; Index++) {
		DstBuffer[Index] = 0xFF;
	}

	/* Perform DMA Transfer */
	XAxiCdma_SimpleTransfer(&FpdCDma, (UINTPTR)SrcBuffer, (UINTPTR)DstBuffer, BUFFER_BYTESIZE, NULL, NULL);
	while (XAxiCdma_IsBusy(&FpdCDma));

	xil_printf("Destination buffer readback: 0x%0X\r\n", DstBuffer[0]);

	/* Initialize buffers */
	xil_printf("\r\nPL LPD DMA Coherency Test\r\n");
	xil_printf("Source buffer pattern: 0x37\r\n");
	initBuffers(0x37);

	/* Write Cache */
	for (int Index = 0; Index < BUFFER_BYTESIZE; Index++) {
		DstBuffer[Index] = 0xFF;
	}

	/* Perform DMA Transfer */
	XAxiCdma_SimpleTransfer(&LpdCDma, (UINTPTR)SrcBuffer, (UINTPTR)DstBuffer, BUFFER_BYTESIZE, NULL, NULL);
	while (XAxiCdma_IsBusy(&LpdCDma));

	xil_printf("Destination buffer readback: 0x%0X\r\n", DstBuffer[0]);

	/* Initialize buffers */
	xil_printf("\r\nCCI 0 DMA Coherency Test\r\n");
	xil_printf("Source buffer pattern: 0x38\r\n");
	initBuffers(0x38);

	/* Write Cache */
	for (int Index = 0; Index < BUFFER_BYTESIZE; Index++) {
		DstBuffer[Index] = 0xFF;
	}

	/* Perform DMA Transfer */
	XAxiCdma_SimpleTransfer(&Cci0CDma, (UINTPTR)SrcBuffer, (UINTPTR)DstBuffer, BUFFER_BYTESIZE, NULL, NULL);
	while (XAxiCdma_IsBusy(&Cci0CDma));

	xil_printf("Destination buffer readback: 0x%0X\r\n", DstBuffer[0]);

	/* Initialize buffers */
	xil_printf("\r\nCCI 1 DMA Coherency Test\r\n");
	xil_printf("Source buffer pattern: 0x39\r\n");
	initBuffers(0x39);

	/* Write Cache */
	for (int Index = 0; Index < BUFFER_BYTESIZE; Index++) {
		DstBuffer[Index] = 0xFF;
	}

	/* Perform DMA Transfer */
	XAxiCdma_SimpleTransfer(&Cci1CDma, (UINTPTR)SrcBuffer, (UINTPTR)DstBuffer, BUFFER_BYTESIZE, NULL, NULL);
	while (XAxiCdma_IsBusy(&Cci1CDma));

	xil_printf("Destination buffer readback: 0x%0X\r\n", DstBuffer[0]);

	/* Initialize buffers */
	xil_printf("\r\nLPD DMA Coherency Test\r\n");
	xil_printf("Source buffer pattern: 0xA5\r\n");
	initBuffers(0xA5);

	/* Write Cache */
	for (int Index = 0; Index < BUFFER_BYTESIZE; Index++) {
		DstBuffer[Index] = 0xFF;
	}

	/* Transfer data */
	XZDma_Transfer Data;
	Data.SrcAddr = (UINTPTR)SrcBuffer;
	Data.DstAddr = (UINTPTR)DstBuffer;
	Data.SrcCoherent = 1;
	Data.DstCoherent = 1;
	Data.Size = BUFFER_BYTESIZE;
	XZDma_Start(&ZDma, &Data, 1);
	while(XZDma_ChannelState(&ZDma) == XZDMA_BUSY);

	xil_printf("Destination buffer readback: 0x%0X\r\n", DstBuffer[0]);

	/* Initialize buffers */
	xil_printf("\r\nRPU Coherency Test\r\n");
	xil_printf("Source buffer pattern: 0x5A\r\n");
	initBuffers(0x5A);

	/* Write Cache */
	for (int Index = 0; Index < BUFFER_BYTESIZE; Index++) {
		DstBuffer[Index] = 0xFF;
	}

	/* Send message to RPU0 */
	u32 Msg[3] = {(UINTPTR)SrcBuffer, (UINTPTR)DstBuffer, BUFFER_BYTESIZE};
	XIpiPsu_WriteMessage(&IpiInst,DestCpuMask, Msg, 3, XIPIPSU_BUF_TYPE_MSG);
	XIpiPsu_TriggerIpi(&IpiInst, DestCpuMask);
	XIpiPsu_PollForAck(&IpiInst, DestCpuMask, 100000);

	xil_printf("Destination buffer readback: 0x%0X\r\n", DstBuffer[0]);
	return 0;
}
