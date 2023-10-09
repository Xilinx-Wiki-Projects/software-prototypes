/*
 * Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
 * SPDX-License-Identifier: MIT
 */

#include <unistd.h>
#include <stdio.h>
#include <errno.h>
#include <sys/types.h>
#include <metal/io.h>
#include <metal/device.h>
#include <metal/irq.h>
#include <metal/sys.h>

#define BUS_NAME		"platform"
#define IPI_DEV_NAME		"ff370000.ipi"
#define IPI_BUF_DEV_NAME	"ff990000.ipi_buf"

#define IPI_TRIG_OFFSET 0x0  /* IPI trigger reg offset */
#define IPI_OBS_OFFSET  0x4  /* IPI observation reg offset */
#define IPI_ISR_OFFSET  0x10 /* IPI interrupt status reg offset */
#define IPI_IMR_OFFSET  0x14 /* IPI interrupt mask reg offset */
#define IPI_IER_OFFSET  0x18 /* IPI interrupt enable reg offset */
#define IPI_IDR_OFFSET  0x1C /* IPI interrup disable reg offset */

#define REMOTE_IPI_MASK 0x0F0F0301U

#define IPI_PMUTOCH10_REQ_OFFSET 0xF80
#define IPI_PMUTOCH10_RES_OFFSET 0xFA0
#define IPI_CH10TOPMU_REQ_OFFSET 0xDC0
#define IPI_PMU_MASK 0x10000

#define XPFW_IPI_ID 0x1EU

struct metal_device *ipi_dev;
struct metal_io_region *ipi_io;
struct metal_device *ipi_buf_dev;
struct metal_io_region *ipi_io_buffer;
int ipi_irq;

static int ipi_irq_handler (int vect_id, void *priv)
{
	uint32_t TmpBufPtr[] = { 0 }; /**< Holds the received Message, later inverted and sent back as response*/
	uint32_t Index;

	/* Copy the IPI Buffer contents into Users's Buffer*/
	for (Index = 0U; Index < (sizeof(TmpBufPtr)/sizeof(*TmpBufPtr)); Index++) {
		TmpBufPtr[Index] = metal_io_read32(ipi_io_buffer, IPI_PMUTOCH10_REQ_OFFSET + (sizeof(*TmpBufPtr) * Index));
	}

	/* Copy the Message to IPI Buffer */
	for (Index = 0U; Index < (sizeof(TmpBufPtr)/sizeof(*TmpBufPtr)); Index++) {
		metal_io_write32(ipi_io_buffer, IPI_PMUTOCH10_RES_OFFSET + (sizeof(*TmpBufPtr) * Index), TmpBufPtr[Index]);
	}

	/* Clear the Interrupt Status - This clears the OBS bit on the SRC CPU registers */
	metal_io_write32(ipi_io, IPI_ISR_OFFSET, ~0);

	return METAL_IRQ_HANDLED;
}

int main(void)
{
	int ret;
	struct metal_init_params init_param = METAL_INIT_DEFAULTS;

	ret = metal_init(&init_param);
	if (ret) {
		printf("Failed to initialize Metal\n");
		goto err1;
	}

	metal_set_log_level(METAL_LOG_NOTICE);

	/* Open and map IPI buffer memory region */
	ret = metal_device_open(BUS_NAME, IPI_BUF_DEV_NAME, &ipi_buf_dev);
	if (ret) {
		printf("Failed to open device %s\n", IPI_BUF_DEV_NAME);
		goto err2;
	}

	ipi_io_buffer = metal_device_io_region(ipi_buf_dev, 0);
	if (!ipi_io_buffer) {
		printf("Failed to map io buffer region for %s\n", ipi_buf_dev->name);
		ret = -ENODEV;
		goto err3;
	}

	/* Open and map IPI interrupt memory region */
	ret = metal_device_open(BUS_NAME, IPI_DEV_NAME, &ipi_dev);
	if (ret) {
		printf("Failed to open device %s\n", IPI_DEV_NAME);
		goto err3;
	}

	ipi_io = metal_device_io_region(ipi_dev, 0);
	if (!ipi_io) {
		printf("Failed to map io region for %s\n", ipi_dev->name);
		ret = -ENODEV;
		goto err4;
	}

	/* Register interrupt handler */
	ipi_irq = (intptr_t)ipi_dev->irq_info;
	metal_irq_register(ipi_irq, ipi_irq_handler, 0);
	metal_irq_enable(ipi_irq);

	/* Enable Remote IPIs */
	metal_io_write32(ipi_io, IPI_IER_OFFSET, REMOTE_IPI_MASK);

	/* Write message with the IPI module ID */
	metal_io_write32(ipi_io_buffer, IPI_CH10TOPMU_REQ_OFFSET, (XPFW_IPI_ID << 16));
	metal_io_write32(ipi_io, IPI_TRIG_OFFSET, IPI_PMU_MASK);

	while(1);

	metal_io_write32(ipi_io, IPI_IDR_OFFSET, REMOTE_IPI_MASK);
	metal_irq_disable(ipi_irq);
	metal_irq_unregister(ipi_irq);

err4:
	metal_device_close(ipi_dev);
err3:
	metal_device_close(ipi_buf_dev);
err2:
	metal_finish();
err1:
	return ret;
}
