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

#define SLCR_ADMA		0xFF4B0024
#define SNOOP_CONTROL_S3	0xFD6E4000
#define ENABLE_SNOOP		0x1

#define NORM_WB_OUT_CACHE	0x605UL

#define HPC_CHANNEL	1
#define LPD_CHANNEL	2

#define AXI_ATTR(prot, cache)	((prot << 4) | cache)

#define PROT_UP_S_D	0x0	/* Unprivileged, Secure, Data */
#define AXI_PROT	PROT_UP_S_D

#define	CACHE_OA_M	0xB /* Write-through No-allocate */

#define RPU_0_CFG	0xFF9A0100
#define RPU_COHERENT	0x2

static u8* SrcBuffer = (u8*)0x40000;
static u8* DestBuffer= (u8*)0x60000;

XZDma ZDma;
XAxiCdma LpdCDma;
XAxiCdma FpdCDma;
XGpio Gpio;
XIpiPsu IpiInst;

u32 DestCpuMask;

static void initBuffers(u8 pattern)
{
	/* Initialize memory */
	for (int Index = 0; Index < BUFFER_BYTESIZE; Index++) {
		SrcBuffer[Index] = pattern;
		DestBuffer[Index] = 0x0;
	}
	Xil_DCacheFlushRange((UINTPTR)SrcBuffer, BUFFER_BYTESIZE);
	Xil_DCacheFlushRange((UINTPTR)DestBuffer, BUFFER_BYTESIZE);
}

static void LpdDmaConfiguration(void)
{
	XZDma_Config *DmaConfig;
	XZDma_DataConfig Configure;

	DmaConfig = XZDma_LookupConfig(XPAR_PSU_ADMA_0_DEVICE_ID);
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
	Xil_Out32(SLCR_ADMA, 0x0);
}

static void FpdCdmaConfiguration(void)
{
	XAxiCdma_Config *CDmaConfig;

	CDmaConfig = XAxiCdma_LookupConfig(XPAR_AXICDMA_0_DEVICE_ID);
	XAxiCdma_CfgInitialize(&FpdCDma, CDmaConfig, CDmaConfig->BaseAddress);

	/* Set the AxPROT and AxCACHE signals */
	XGpio_Initialize(&Gpio, XPAR_GPIO_0_DEVICE_ID);
	XGpio_DiscreteWrite(&Gpio, HPC_CHANNEL, AXI_ATTR(AXI_PROT, CACHE_OA_M));
}

static void LpdCdmaConfiguration(void)
{
	XAxiCdma_Config *CDmaConfig;

	CDmaConfig = XAxiCdma_LookupConfig(XPAR_AXICDMA_1_DEVICE_ID);
	XAxiCdma_CfgInitialize(&LpdCDma, CDmaConfig, CDmaConfig->BaseAddress);

	/* Set the AxPROT and AxCACHE signals */
	XGpio_Initialize(&Gpio, XPAR_GPIO_0_DEVICE_ID);
	XGpio_DiscreteWrite(&Gpio, LPD_CHANNEL, AXI_ATTR(AXI_PROT, CACHE_OA_M));
}

static void RpuConfiguration(void)
{
	XIpiPsu_Config *CfgPtr;

	CfgPtr = XIpiPsu_LookupConfig(XPAR_XIPIPSU_0_DEVICE_ID);
	XIpiPsu_CfgInitialize(&IpiInst, CfgPtr, CfgPtr->BaseAddress);

	DestCpuMask = CfgPtr->TargetList[1].Mask;

	Xil_Out32(RPU_0_CFG, Xil_In32(RPU_0_CFG) | RPU_COHERENT);
}

int main (void)
{
	xil_printf("************************************************************\r\n");
	xil_printf("ZynqMP CCI-400 Coherency example\r\n");
	xil_printf("************************************************************\r\n");

	/* Enable snooping of APU caches from CCI */
	Xil_Out32(SNOOP_CONTROL_S3, ENABLE_SNOOP);

	/* Set memory as outer cacheable */
	Xil_SetTlbAttributes((UINTPTR)DestBuffer, NORM_WB_OUT_CACHE);
	dsb();

	FpdCdmaConfiguration();
	LpdCdmaConfiguration();
	LpdDmaConfiguration();
	RpuConfiguration();

	/* Initialize buffers */
	xil_printf("\r\nPL FPD(HPC) DMA Coherency Test\r\n");
	xil_printf("Source buffer pattern: 0x36\r\n");
	initBuffers(0x36);

	/* Write Cache */
	for (int Index = 0; Index < BUFFER_BYTESIZE; Index++) {
		DestBuffer[Index] = 0xFF;
	}

	/* Perform DMA Transfer */
	XAxiCdma_SimpleTransfer(&FpdCDma, (UINTPTR)SrcBuffer, (UINTPTR)DestBuffer, BUFFER_BYTESIZE, NULL, NULL);
	while (XAxiCdma_IsBusy(&FpdCDma));

	xil_printf("Destination buffer readback: 0x%0X\r\n", DestBuffer[0]);

	/* Initialize buffers */
	xil_printf("\r\nPL LPD DMA Coherency Test\r\n");
	xil_printf("Source buffer pattern: 0x37\r\n");
	initBuffers(0x37);

	/* Write Cache */
	for (int Index = 0; Index < BUFFER_BYTESIZE; Index++) {
		DestBuffer[Index] = 0xFF;
	}

	/* Perform DMA Transfer */
	XAxiCdma_SimpleTransfer(&LpdCDma, (UINTPTR)SrcBuffer, (UINTPTR)DestBuffer, BUFFER_BYTESIZE, NULL, NULL);
	while (XAxiCdma_IsBusy(&LpdCDma));

	xil_printf("Destination buffer readback: 0x%0X\r\n", DestBuffer[0]);

	/* Initialize buffers */
	xil_printf("\r\nLPD DMA Coherency Test\r\n");
	xil_printf("Source buffer pattern: 0xA5\r\n");
	initBuffers(0xA5);

	/* Write Cache */
	for (int Index = 0; Index < BUFFER_BYTESIZE; Index++) {
		DestBuffer[Index] = 0xFF;
	}

	/* Transfer data */
	XZDma_Transfer Data;
	Data.SrcAddr = (UINTPTR)SrcBuffer;
	Data.DstAddr = (UINTPTR)DestBuffer;
	Data.SrcCoherent = 1;
	Data.DstCoherent = 1;
	Data.Size = BUFFER_BYTESIZE;
	XZDma_Start(&ZDma, &Data, 1);
	while(XZDma_ChannelState(&ZDma) == XZDMA_BUSY);

	xil_printf("Destination buffer readback: 0x%0X\r\n", DestBuffer[0]);

	/* Initialize buffers */
	xil_printf("\r\nRPU Coherency Test\r\n");
	xil_printf("Source buffer pattern: 0x5A\r\n");
	initBuffers(0x5A);

	/* Write Cache */
	for (int Index = 0; Index < BUFFER_BYTESIZE; Index++) {
		DestBuffer[Index] = 0xFF;
	}

	/* Send message to RPU0 */
	u32 Msg[3] = {(UINTPTR)SrcBuffer, (UINTPTR)DestBuffer, BUFFER_BYTESIZE};
	XIpiPsu_WriteMessage(&IpiInst,DestCpuMask, Msg, 3, XIPIPSU_BUF_TYPE_MSG);
	XIpiPsu_TriggerIpi(&IpiInst, DestCpuMask);
	XIpiPsu_PollForAck(&IpiInst, DestCpuMask, 100000);

	xil_printf("Destination buffer readback: 0x%0X\r\n", DestBuffer[0]);
}
