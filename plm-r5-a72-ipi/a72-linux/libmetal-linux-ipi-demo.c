/*
 * Copyright (c) 2022, Xilinx Inc. and Contributors. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Introduction
 *
 * This Linux application uses the libmetal library to demonstrate IPI
 * messages between Linux on the A72s and the PLM of Versal.
 *
 * This prototype assumes the user has knowledge and experience with IPI
 * messaging as defined in the Versal TRM. The hardware provides a mesh
 * network in which a CPU (source) can message another CPU (destination).
 * The source CPU writes into a request buffer then causes an interrupt
 * to the destination CPU.  The destination CPU gets the interrupt, reads
 * the request, and then writes into a response buffer, and lastly
 * acknowledges the interrupt.  The acknowledge of the interrupt can be
 * see by the source CPU ti indicate the response is complete but there is
 * no interrupt for this response complete such that polling is used.
 * The response time of the destination CPU must be taken into account.
 *
 * Application Details
 *
 * Two modes are supported with the default being the PLM as the IPI
 * message source and the A72 being the destination with only unidirectional
 * IPI messages.  In this mode the IPI interrupt in Linux can be seen
 * incrementing when the application is running (cat /proc/interrupts |
 * grep ipi). The IPI message request from the PLM contains a trip
 * counter which gets incremented by the A72 then put into the IPI message
 * response buffer to be returned to the PLM. In this mode the PLM is
 * configured to send the IPI messages at a specific rate of 100 ms.
 *
 * The 2nd mode of operation is when the A72 is the IPI message source
 * and the PLM is the destination with only unidirectional IPI messages.
 * In this mode the IPI interrupt in Linux will not be incrementing.
 * The IPI message request from the A72 contains a trip counter which
 * gets incremented by the PLM and then put into the IPI message response
 * buffer to be returned to the A72. In this mode the A72 attempts to send
 * the IPI messages at a rate of 100ms but since it's a delay in user
 * space it might not be exactly accurate.
 *
 * The IPI messaging is using the IPI buffers of Versal rather than
 * other memory. A device tree node is required to access the IPI buffers.
 * The application was tested with the vck190 platform included in Vitis
 * with Linux using IPI 3.
 *
 * When the application is functioning you should see output similar to the
 * following with the counter incrementing every second.
 *
 * On A72: Counter: 0 Payload: 0
 * On A72: Counter: 1 Payload: 20
 * On A72: Counter: 2 Payload: 40
 *
 * This application has been tested with 2021.1 Xilinx tools.  Warnings similar
 * to the following are expected when running the application as explained in the
 * release notes of the tools. The application must be linked with the libmetal
 * library of Vitis. The Linux rootfs must be built with libmetal and Vitis must
 * have the sysroot from the Linux build.
 *
 * metal: warning:   reading attribute /sys/devices/platform/ff3f0000.ipi/
 * uio/uio0/maps/map1/offset yields result -22
 *
 * Device Tree
 *
 * The following nodes need to be present in the Linux device tree for this
 * application to function.
 *
 *	ipi@ff360000 {
 *      compatible = "uio";
 *      reg = <0x0 0xff360000 0x0 0x1000>;
 *       interrupt-parent = <&gic>;
 *       interrupts = <0 33 4>;
 *  };
 *  ipi_buf@ff3f0000 {
 *      compatible = "uio";
 *      reg = <0x0 0xff3f0000 0x0 0x1000>;
 *   };
 */

#include <unistd.h>
#include <stdio.h>
#include <errno.h>
#include <sys/types.h>
#include <metal/io.h>
#include <metal/device.h>
#include <metal/irq.h>
#include <metal/sys.h>

/* The following constants describe the IPI devices in Linux based on the
 * device tree nodes. The devices can be seen in /sys/devices/platform on a
 * running Linux target.
 */
#define BUS_NAME        	"platform"
#define IPI_DEV_NAME		"ff360000.ipi"
#define IPI_BUF_DEV_NAME	"ff3f0000.ipi_buf"

#define REMOTE_IPI_MASK		0x2 	/* PLM as the remote IPI */

/* IPI registers offset
 */
#define IPI_TRIG_OFFSET 0x0  /* IPI trigger reg offset */
#define IPI_OBS_OFFSET  0x4  /* IPI observation reg offset */
#define IPI_ISR_OFFSET  0x10 /* IPI interrupt status reg offset */
#define IPI_IMR_OFFSET  0x14 /* IPI interrupt mask reg offset */
#define IPI_IER_OFFSET  0x18 /* IPI interrupt enable reg offset */
#define IPI_IDR_OFFSET  0x1C /* IPI interrup disable reg offset */

/* The IPI message uses the IPI message buffers in the hardware and
 * these offsets correlate to specific source / destination IPI agents
 * request buffers with the response buffers being 32 bytes offset from
 * the request buffer.
 */
#define PLM_TO_IPI3_REQ_OFFSET	0x340
#define IPI3_TO_PLM_REQ_OFFSET 	0xA40

/* The PLM must be built in sync with the following constants.
 */
#define PLM_MODULE_ID		0xD		/* PLM module to do command processing */
#define MSG_RATE_MS			100		/* number of messages / milliscond */
#define COUNTS_PER_SECOND	((1000 / MSG_RATE_MS) * 2)

/* The default mode of operation is for the A72 to be the source of
 * the IPI messages.  Comment this out for the PLM to be the source
 * of the IPI messages making sure the PLM application is configured
 * to match.
 */
#define	A72_TO_PLM_UNIDIRECTIONAL

struct metal_device *ipi_dev;
struct metal_io_region *ipi_io;
struct metal_device *ipi_buf_dev;
struct metal_io_region *ipi_io_buffer;
int ipi_irq;

/* The following function is used when the A72 is the source
 * of the IPI messages. It creates a message with the input counter
 * in the IPI message request buffer, sends the request to the PLM,
 * and then waits for a response from the PLM. The response
 * contains the counter from the PLM.
 */
static uint32_t send_ipi_msg(uint32_t counter)
{
	uint32_t val;

	/* Create a new IPI message in the IPI 3 to PLM IPI buffer
	 * request memory.  The request must be formatted to match
	 * the xplmi library format of the PLM which has the least
	 * significant byte of the first 32 bit word containing the
	 * command which is zero in this case. The next significant
	 * byte of the first 32 bit word must contain the module
	 * of the PLM that is to be processing the command.
	 */
	metal_io_write32(ipi_io_buffer, IPI3_TO_PLM_REQ_OFFSET,
						PLM_MODULE_ID << 8 | 1);

	/* Send the trip counter by putting it into the payload after
	 * the command / module word
	 */
	metal_io_write32(ipi_io_buffer, IPI3_TO_PLM_REQ_OFFSET + 4,
						counter);

	/* Trigger the PLM IPI to tell it there is an IPI message
	 */
	metal_io_write32(ipi_io, IPI_TRIG_OFFSET, REMOTE_IPI_MASK);

	/* Wait for the remote to handle the interrupt to indicate the command
	 * was processed and a command response is valid in the buffer, there
	 * likely needs to be a timeout here in case there is no response?
	 */
	while (1) {
		val = metal_io_read32(ipi_io, IPI_OBS_OFFSET);
		if ((val & REMOTE_IPI_MASK) == 0)
			break;
	}

	/* Return the trip counter which is in the response from the PLM
	 */
	return metal_io_read32(ipi_io_buffer, IPI3_TO_PLM_REQ_OFFSET + 32 + 4);
}

/* The following function is called when an IPI message interrupt is
 * received.  It gets the counter from the request and then increments
 * the counter and sends it back in the response buffer of the same IPI
 * message.
 */
static int _ipi_irq_handler (int vect_id, void *priv)
{
	uint32_t val, val2;

	(void)priv;
	(void)vect_id;

	/* Get the trip counter from the received IPI message and then
	 * send a message back to the PLM incrementing the trip counter
	 */
	val = metal_io_read32(ipi_io_buffer, PLM_TO_IPI3_REQ_OFFSET);

	/* Increment the trip counter to send it back to the
	 * PLM in an IPI message, putting it into the payload after
	 * the command / module word
	 */
	metal_io_write32(ipi_io_buffer, PLM_TO_IPI3_REQ_OFFSET + 32,
						val + 1);

	/* Get the interrupt status and clear the interrupt
	 * so that it does not continue to interrupt and so the sending
	 * CPU can see the command response is ready
	 */
	val2 = metal_io_read32(ipi_io, IPI_ISR_OFFSET);
	if (val2 & REMOTE_IPI_MASK)
		metal_io_write32(ipi_io, IPI_ISR_OFFSET, REMOTE_IPI_MASK);

	/* Display the trip counter at a slow one second rate so that
	 * it's easy to see working correctly
	 */
	if (val % COUNTS_PER_SECOND  == 0)
		printf("On A72: Seconds: %d Payload: %d\r\n", val / COUNTS_PER_SECOND, val);

	return METAL_IRQ_HANDLED;
}

int init_ipi(void)
{
	int ret;

	/* Open IPI buffer device and map the IO into the memory map so that
	 * it is accessible
	 */
	ret = metal_device_open(BUS_NAME, IPI_BUF_DEV_NAME, &ipi_buf_dev);
	if (ret) {
		printf("Failed to open device %s.\n", IPI_BUF_DEV_NAME);
		return ret;
	}
	ipi_io_buffer = metal_device_io_region(ipi_buf_dev, 0);
	if (!ipi_io_buffer) {
		printf("Failed to map io buffer region for %s.\n", ipi_buf_dev->name);
		ret = -ENODEV;
		metal_device_close(ipi_buf_dev);
		return ret;
	}

	/* Open IPI device and map the IO into the memory map so that
	 * it is accessible
	 */
	ret = metal_device_open(BUS_NAME, IPI_DEV_NAME, &ipi_dev);
	if (ret) {
		printf("Failed to open device %s.\n", IPI_DEV_NAME);
		return ret;
	}
	ipi_io = metal_device_io_region(ipi_dev, 0);
	if (!ipi_io) {
		printf("Failed to map io region for %s.\n", ipi_dev->name);
		ret = -ENODEV;
		metal_device_close(ipi_buf_dev);
		metal_device_close(ipi_dev);
		return ret;
	}

	/* Get the IPI IRQ from the opened IPI device
	 */
	ipi_irq = (intptr_t)ipi_dev->irq_info;

	/* Disable theIPI interrupt in the IPI and in Linux
	 */
	metal_io_write32(ipi_io, IPI_IDR_OFFSET, REMOTE_IPI_MASK);
	metal_irq_disable(ipi_irq);

	/* Clear any old IPI interrupt and register a handler
	 * for the IPI interrupt
	 * Clearing the ISR causes a false observation on the other CPU
	 */
#if 0
	metal_io_write32(ipi_io, IPI_ISR_OFFSET, REMOTE_IPI_MASK);
#endif
	metal_irq_register(ipi_irq, _ipi_irq_handler, 0);

	return 0;
}

void deinit_ipi(void)
{
	/* Disable the IPI interrupt in the h/w and in Linux
	 */
	if (ipi_io)
		metal_io_write32(ipi_io, IPI_IDR_OFFSET, REMOTE_IPI_MASK);

	metal_irq_disable(ipi_irq);

	/* Disconnect from the interrupt and close the devices
	 */
	metal_irq_unregister(ipi_irq);

	if (ipi_dev) {
		metal_device_close(ipi_dev);
		ipi_dev = NULL;
	}
	if (ipi_buf_dev) {
		metal_device_close(ipi_buf_dev);
		ipi_buf_dev = NULL;
	}
}

int main(void)
{
	int ret;
	struct metal_init_params init_param = METAL_INIT_DEFAULTS;
	uint32_t trip_counter = 0;

	ret = metal_init(&init_param);
	if (ret) {
		printf("Metal initialization failure\r\n");
		goto out;
	}

	ret = init_ipi();
	if (ret) {
		goto out;
	}

	/* Enable IPI interrupt in Linux and in the IPI h/w
	 */
	metal_irq_enable(ipi_irq);
	metal_io_write32(ipi_io, IPI_IER_OFFSET, REMOTE_IPI_MASK);

	/* For this demo just sit waiting while interrupts happen when
	 * the PLM is sending to the A72, otherwise send messages from
	 * the A72 to the PLM at a periodic rate
	 */
	while (1) {

		/* The timing from Linux space is only approximate so that the
		 * sleep might need to be tuned if a very specific message rate is
		 * desired.
		 */
#ifdef A72_TO_PLM_UNIDIRECTIONAL
		trip_counter = send_ipi_msg(trip_counter + 1);
		if ((trip_counter % COUNTS_PER_SECOND) == 0)
			printf("On A72: Seconds: %d: Payload: %d\n", trip_counter / COUNTS_PER_SECOND,
					trip_counter);
		usleep(MSG_RATE_MS * 1000);
#endif
	};

out:
	deinit_ipi();
	metal_finish();

	return ret;
}
