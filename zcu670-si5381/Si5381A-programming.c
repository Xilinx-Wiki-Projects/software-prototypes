/******************************************************************************
* Copyright (c) 2022 Xilinx, Inc.  All rights reserved.
* SPDX-License-Identifier: MIT
 *******************************************************************************/
/*
 * Si5381A-programming.c
 *
 * The following application initializes a Si5381 device on a board using specific details
 * about the board as it uses I2C for the device and assumes there is an I2C mux in the path
 * to the device.
 *
 * This application uses a header file based on the generated output from the ClockBuilder
 * Pro tool to perform register initialization of the Si5381 over I2C. Users may want to
 * include their own generated header file based on a custom clock configuration in the
 * ClockBuilder Pro tool. The header file must match the format from the ClockBuilder tool.
 * A set of four header files are provided for four different clock configurations.
 *
 * Typical output of the application is shown below, but not all output may be seen sometimes.
 *
 * 	Si5381 MUX is set
 *	Si5381 IC Configured
 *
 * The function ProgramSi5381() can be called from FSBL such that the main function is not
 * needed.  Create an FSBL in Vitis. In FSBL, edit xfsbl_hooks.c and add a call to the function
 * in the function XFsbl_HookBeforeHandoff() as shown below.
 *
 * XFsbl_HookBeforeHandoff()
 * {
 * 	u32 Status = XFSBL_SUCCESS;
 *
 * 	ProgramSi5381();
 *
 *	return Status;
 * }
 */

#include <stdio.h>
#include "xil_printf.h"
#include "xparameters.h"
#include "xil_types.h"
#include "sleep.h"
#include "xiicps.h"

/* The following header file is the output from the ClockBuilder Pro tool
 * and is a custom name which must be altered when using new generated output.
 */
#include "Si5381A-zcu670_DAC-ADC-REFCLK_122M88_03302021-Registers.h"

/* The following are valid for the ZCU670 board, there is a mux to get to the
 * i2c device
 */
#define I2C_MUXADDR				(0x74)
#define SI5381_MUXVAL			(0x2)
#define SI5381_ADDR				(0x68)
#define SI5381_ID 				(0x5381)
#define I2C_SCLK_RATE_I2CMUX 	(400000U)
#define SI5381_I2C_DEVICE 		(XPAR_XIICPS_1_DEVICE_ID)

/* The following are based on the ClockBuilder Pro output for the device.
 * Comments in the generated header file indicate the need for a time delay
 * after the preamble.
 */
#define PREAMBLE_SIZE 	(3)
#define POSTAMBLE_SIZE	(5)
#define ONE_MS_IN_USEC 	(1000)

/* Device specific commands
 */
#define PAGE_CMD		(1)
#define	PART_NUM_CMD	(2)
#define PAGE_CMD_LEN	(2)

#define BUF_LEN 		(2)

// #define DEBUG

#define print(...) xil_printf (__VA_ARGS__);

/* The following functions assume the I2C bus is responding since they wait for the bus to not
 * be busy without any timeout. The also assumes that mux/bus speed is properly set prior to
 * writing or reading.
 */
static u32 WriteSi538xRegister(XIicPs *I2cInstPtr, int SlaveAddr, int Reg, u8 *Writedata, int Len)
{
	static u8 Buffer[BUF_LEN + 1];
	static int LastPage = -1;
	static int LastSlaveAddr = -1;
	u32 Status = XST_SUCCESS;
	int Page = ((Reg >> 8) & 0xFF);
	int i;

	/* Set the device Current Page (if needed) using the page command
	 * and wait for it to complete
	 */
	if (Page != LastPage || SlaveAddr != LastSlaveAddr ) {

		Buffer[0U] = PAGE_CMD;
		Buffer[1U] = (u8)Page;

#ifdef DEBUG
		print("Si5381 0x%x setting page to 0x%x\n\r", SlaveAddr, Buffer[1U]);
#endif
		Status = XIicPs_MasterSendPolled(I2cInstPtr,
				Buffer, PAGE_CMD_LEN, SlaveAddr);
		if (Status != XST_SUCCESS) {
			print("Si5381 0x%x Setting page %d failed\n\r", SlaveAddr, Buffer[1U]);
			return XST_FAILURE;
		}
		while (XIicPs_BusIsBusy(I2cInstPtr) == TRUE);

		/* Keep track of the last page and slave address used so they
		 * can be set if they are different on the next pass
		 */
		LastPage = Page;
		LastSlaveAddr = SlaveAddr;
	}
	/* Copy the data to write after the register address and send to device waiting
	 * for it to be done
	 */
	Buffer[0U] = Reg & 0XFF;
	for (i = 0; i < Len; i++) {
		Buffer[1 + i] = Writedata[i];
	}
	Status = XIicPs_MasterSendPolled(I2cInstPtr, Buffer, Len+1, SlaveAddr);
	if (Status != XST_SUCCESS) {
		print("Si5381 Write register %d with page %d failed\n\r", Reg, Page);
		return XST_FAILURE;
	}
	while (XIicPs_BusIsBusy(I2cInstPtr) == TRUE);

	return Status;
}

static u32 ReadSi538xRegister(XIicPs *I2cInstPtr, int SlaveAddr, int Reg, u8 *Readbuf, int Len)
{
	u32 Status = XST_SUCCESS;

	/* Write all the address data to the Si538x
	 */
	Status = WriteSi538xRegister(I2cInstPtr, SlaveAddr, Reg, NULL, 0);
	if (XST_SUCCESS != Status) {
		print("Si5381 Set register values for read failed\n\r");
		return XST_FAILURE;
	}
	/* Read the data from the device
	 */
	Status = XIicPs_MasterRecvPolled(I2cInstPtr, Readbuf, Len, SlaveAddr);
	if (Status != XST_SUCCESS) {
		print("Si5381 Polled Recv for data read failed\n\r");
		return XST_FAILURE;
	}
	while (XIicPs_BusIsBusy(I2cInstPtr) == TRUE);

	return Status;
}

int ProgramSi5381() {
	XIicPs I2cInstance;
	XIicPs_Config *I2cCfgPtr;
	u8 WriteBuffer[BUF_LEN] = {0U};
	u8 ReadBuffer[BUF_LEN] = {0U};
	u32 SlaveAddr;
	u32 Id;
	s32 Status;
	int i;

	/* Initialize the I2C driver so that it is ready to use
	 */
	I2cCfgPtr = XIicPs_LookupConfig(SI5381_I2C_DEVICE);
	if (I2cCfgPtr == NULL) {
		print("Si5381 I2C initialization 1 failure\r\n");
		return XST_FAILURE;
	}

	Status = XIicPs_CfgInitialize(&I2cInstance, I2cCfgPtr,
			I2cCfgPtr->BaseAddress);
	if (Status != XST_SUCCESS) {
		print("Si5381 I2C initialization 2 failure\r\n");
		return XST_FAILURE;
	}

	/* Change the I2C serial clock rate
	 */
	Status = XIicPs_SetSClk(&I2cInstance, I2C_SCLK_RATE_I2CMUX);
	if (Status != XST_SUCCESS) {
		print("Si5381 I2C clock set failure\r\n");
		return XST_FAILURE;
	}

	/* Initialize the I2C mux to allow access to the Si5381 device
	 * on the board.
	 */
	WriteBuffer[0U] = SI5381_MUXVAL;
	SlaveAddr = I2C_MUXADDR;
	Status = XIicPs_MasterSendPolled(&I2cInstance,
			WriteBuffer, 1U, SlaveAddr);
	if (Status != XST_SUCCESS) {
		print("SI5381 set MUX failure\n\r");
		return XST_FAILURE;
	}
	while (XIicPs_BusIsBusy(&I2cInstance) == TRUE);

	print("Si5381 MUX is set\n\r");

	/* Verify that this is actually a 5381 by reading the device ID
	 */
	SlaveAddr = SI5381_ADDR;
	Status = ReadSi538xRegister(&I2cInstance, SlaveAddr, PART_NUM_CMD, ReadBuffer, 2);
	Id = (u32)ReadBuffer[1] << 8 | (u32)ReadBuffer[0];
	if (Id != SI5381_ID) {
		print("Si5381 identifier 0x%x is incorrect\n\r", Id);
		return XST_FAILURE;
	}

	/* Write all the registers while handling the preamble of the register data with
	 * special details.
	 */
	for (i = 0; i < (sizeof(si5381a_reve_registers)/sizeof(si5381a_reve_register_t)); i++) {
#ifdef DEBUG
		print("Si5381 %d writing address 0x%x = 0x%x\n\r",
				i, si5381a_reve_registers[i].address, si5381a_reve_registers[i].value);
#endif
		Status = WriteSi538xRegister(&I2cInstance, SlaveAddr,
										si5381a_reve_registers[i].address,
										(u8 *)&si5381a_reve_registers[i].value,	1);
		if (Status != XST_SUCCESS) {
			print("Si5381 Register write failure\r\n");
			return XST_FAILURE;
		}

		/* Based on the comments in the header file a time delay is needed after the
		 * preamble
		 */
		if (i == PREAMBLE_SIZE - 1)
			usleep (625 * ONE_MS_IN_USEC);

	}
	/* Readback most of the registers to verify they were written correctly.
	 */
	for (i = PREAMBLE_SIZE;
		 i < (sizeof(si5381a_reve_registers)/sizeof(si5381a_reve_register_t)) - POSTAMBLE_SIZE; i++) {
#ifdef DEBUG
		print("Si5381 %d reading address 0x%x\n\r", i, si5381a_reve_registers[i].address);
#endif
		Status = ReadSi538xRegister(&I2cInstance, SlaveAddr,
										si5381a_reve_registers[i].address, ReadBuffer, 1);

		if (Status != XST_SUCCESS) {
			print("Si5381 Register read failure\r\n");
			return XST_FAILURE;
		}
		if (ReadBuffer[0] != si5381a_reve_registers[i].value)
				print("Si5381 Readback failure, read: 0x%x, expected: 0x%0x\n\r",
						ReadBuffer[0], si5381a_reve_registers[i].value);
	}
	print("Si5381 IC Configured\r\n");
	return XST_SUCCESS;
}

/* If building as a standalone application rather than calling from FSBL then use the
 * main function below.
 */
#if 0
int main(void)
{
	ProgramSi5381();
}
#endif

