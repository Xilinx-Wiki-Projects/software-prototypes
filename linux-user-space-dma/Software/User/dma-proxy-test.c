/**
 * Copyright (C) 2021 Xilinx, Inc
 *
 * Licensed under the Apache License, Version 2.0 (the "License"). You may
 * not use this file except in compliance with the License. A copy of the
 * License is located at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations
 * under the License.
 */

/* DMA Proxy Test Application
 *
 * This application is intended to be used with the DMA Proxy device driver. It provides
 * an example application showing how to use the device driver to do user space DMA
 * operations.
 *
 * The driver allocates coherent memory which is non-cached in a s/w coherent system
 * or cached in a h/w coherent system.
 *
 * Transmit and receive buffers in that memory are mapped to user space such that the
 * application can send and receive data using DMA channels (transmit and receive).
 *
 * It has been tested with AXI DMA and AXI MCDMA systems with transmit looped back to
 * receive. Note that the receive channel of the AXI DMA throttles the transmit with
 * a loopback while this is not the case with AXI MCDMA.
 *
 * Build information: The pthread library is required for linking. Compiler optimization
 * makes a very big difference in performance with -O3 being good performance and
 * -O0 being very low performance.
 *
 * The user should tune the number of channels and channel names to match the device
 * tree.
 *
 * More complete documentation is contained in the device driver (dma-proxy.c).
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <pthread.h>
#include <time.h>
#include <sys/time.h>
#include <stdint.h>
#include <signal.h>
#include <sched.h>
#include <time.h>
#include <errno.h>
#include <sys/param.h>

#include "dma-proxy.h"

/* The user must tune the application number of channels to match the proxy driver device tree
 * and the names of each channel must match the dma-names in the device tree for the proxy
 * driver node. The number of channels can be less than the number of names as the other
 * channels will just not be used in testing.
 */
#define TX_CHANNEL_COUNT 1
#define RX_CHANNEL_COUNT 1

const char *tx_channel_names[] = { "dma_proxy_tx", /* add unique channel names here */ };
const char *rx_channel_names[] = { "dma_proxy_rx", /* add unique channel names here */ };

/* Internal data which should work without tuning */

struct channel {
	struct channel_buffer *buf_ptr;
	int fd;
	pthread_t tid;
};

static int verify;
static int test_size;
static volatile int stop = 0;
int num_transfers;

struct channel tx_channels[TX_CHANNEL_COUNT], rx_channels[RX_CHANNEL_COUNT];

/*******************************************************************************************************************/
/* Handle a control C or kill, maybe the actual signal number coming in has to be more filtered?
 * The stop should cause a graceful shutdown of all the transfers so that the application can
 * be started again afterwards.
 */
void sigint(int a)
{
	stop = 1;
}

/*******************************************************************************************************************/
/* Get the clock time in usecs to allow performance testing
 */
static uint64_t get_posix_clock_time_usec ()
{
    struct timespec ts;

    if (clock_gettime (CLOCK_MONOTONIC, &ts) == 0)
        return (uint64_t) (ts.tv_sec * 1000000 + ts.tv_nsec / 1000);
    else
        return 0;
}

/*******************************************************************************************************************/
/*
 * The following function is the transmit thread to allow the transmit and the receive channels to be
 * operating simultaneously. Some of the ioctl calls are blocking so that multiple threads are required.
 */
void tx_thread(struct channel *channel_ptr)
{
	int i, counter = 0, buffer_id, in_progress_count = 0;
	int stop_in_progress = 0;

	// Start all buffers being sent

	for (buffer_id = 0; buffer_id < TX_BUFFER_COUNT; buffer_id += BUFFER_INCREMENT) {

		/* Set up the length for the DMA transfer and initialize the transmit
		 * buffer to a known pattern.
		 */
		channel_ptr->buf_ptr[buffer_id].length = test_size;

		if (verify)
			for (i = 0; i < 1; i++) // test_size / sizeof(unsigned int); i++)
				channel_ptr->buf_ptr[buffer_id].buffer[i] = i + in_progress_count;

		/* Start the DMA transfer and this call is non-blocking
		 *
		 */
		ioctl(channel_ptr->fd, START_XFER, &buffer_id);

		/* Keep track of the number of transfers that are in progress and if the number is less
		 * than the number of channel buffers then stop before all channel buffers are used
		 */
		if (++in_progress_count >= num_transfers)
			break;
	}

	/* Start finishing up the DMA transfers that were started beginning with the 1st channel buffer.
	 */
	buffer_id = 0;

	while (1) {

		/* Perform the DMA transfer and check the status after it completes
		 * as the call blocks til the transfer is done.
		 */
		ioctl(channel_ptr->fd, FINISH_XFER, &buffer_id);
		if (channel_ptr->buf_ptr[buffer_id].status != PROXY_NO_ERROR)
			printf("Proxy tx transfer error\n");

		/* Keep track of how many transfers are in progress and how many completed
		 */
		in_progress_count--;
		counter++;

		/* If all the transfers are done then exit */

		if (counter >= num_transfers)
			break;

		/* If an early stop (control c or kill) has happened then exit gracefully
		 * letting all transfers queued up be completed, but it's trickier because
		 * the number of transmit vs receive channel buffers can be very different
		 * which means another X transfers need to be done gracefully shutdown the
		 * receive without leaving transfers in progress which is unrecoverable
		 */
		if (stop & !stop_in_progress) {
			stop_in_progress = 1;
			num_transfers = counter + RX_BUFFER_COUNT;
		}

		/* If the ones in progress will complete the count then don't start more */

		if ((counter + in_progress_count) >= num_transfers)
			goto end_tx_loop0;

		/* Initialize the buffer and perform the DMA transfer, check the status after it completes
		 * as the call blocks til the transfer is done.
		 */
		if (verify) {
			unsigned int *buffer = (unsigned int *)&channel_ptr->buf_ptr[buffer_id].buffer;
			for (i = 0; i < test_size / sizeof(unsigned int); i++)
				buffer[i] = i + ((TX_BUFFER_COUNT / BUFFER_INCREMENT) - 1) + counter;
		}

		/* Restart the completed channel buffer to start another transfer and keep
		 * track of the number of transfers in progress
		 */
		ioctl(channel_ptr->fd, START_XFER, &buffer_id);

		in_progress_count++;

end_tx_loop0:

		/* Flip to next buffer and wait for it treating them as a circular list
		 */
		buffer_id += BUFFER_INCREMENT;
		buffer_id %= TX_BUFFER_COUNT;
	}
}

void rx_thread(struct channel *channel_ptr)
{
	int in_progress_count = 0, buffer_id = 0;
	int rx_counter = 0;

	// Start all buffers being received

	for (buffer_id = 0; buffer_id < RX_BUFFER_COUNT; buffer_id += BUFFER_INCREMENT) {

		/* Don't worry about initializing the receive buffers as the pattern used in the
		 * transmit buffers is unique across every transfer so it should catch errors.
		 */
		channel_ptr->buf_ptr[buffer_id].length = test_size;

		ioctl(channel_ptr->fd, START_XFER, &buffer_id);

		/* Handle the case of a specified number of transfers that is less than the number
		 * of buffers
		 */
		if (++in_progress_count >= num_transfers)
			break;
	}

	buffer_id = 0;

	/* Finish each queued up receive buffer and keep starting the buffer over again
	 * until all the transfers are done
	 */
	while (1) {

		ioctl(channel_ptr->fd, FINISH_XFER, &buffer_id);

		if (channel_ptr->buf_ptr[buffer_id].status != PROXY_NO_ERROR) {
			printf("Proxy rx transfer error, # transfers %d, # completed %d, # in progress %d\n",
						num_transfers, rx_counter, in_progress_count);
			exit(1);
		}

		/* Verify the data received matches what was sent (tx is looped back to tx)
		 * A unique value in the buffers is used across all transfers
		 */
		if (verify) {
			unsigned int *buffer = &channel_ptr->buf_ptr[buffer_id].buffer;
			int i;
			for (i = 0; i < 1; i++) // test_size / sizeof(unsigned int); i++) this is slow
				if (buffer[i] != i + rx_counter) {
					printf("buffer not equal, index = %d, data = %d expected data = %d\n", i,
						buffer[i], i + rx_counter);
					break;
				}
		}

		/* Keep track how many transfers are in progress so that only the specified number
		 * of transfers are attempted
		 */
		in_progress_count--;

		/* If all the transfers are done then exit */

		if (++rx_counter >= num_transfers)
			break;

		/* If the ones in progress will complete the number of transfers then don't start more
		 * but finish the ones that are already started
		 */
		if ((rx_counter + in_progress_count) >= num_transfers)
			goto end_rx_loop0;

		/* Start the next buffer again with another transfer keeping track of
		 * the number in progress but not finished
		 */
		ioctl(channel_ptr->fd, START_XFER, &buffer_id);

		in_progress_count++;

	end_rx_loop0:

		/* Flip to next buffer treating them as a circular list, and possibly skipping some
		 * to show the results when prefetching is not happening
		 */
		buffer_id += BUFFER_INCREMENT;
		buffer_id %= RX_BUFFER_COUNT;

	}
}

/*******************************************************************************************************************/
/*
 * Setup the transmit and receive threads so that the transmit thread is low priority to help prevent it from
 * overrunning the receive since most testing is done without any backpressure to the transmit channel.
 */
void setup_threads(int *num_transfers)
{
	pthread_attr_t tattr_tx;
	int newprio = 20, i;
	struct sched_param param;

	/* The transmit thread should be lower priority than the receive
	 * Get the default attributes and scheduling param
	 */
	pthread_attr_init (&tattr_tx);
	pthread_attr_getschedparam (&tattr_tx, &param);

	/* Set the transmit priority to the lowest
	 */
	param.sched_priority = newprio;
	pthread_attr_setschedparam (&tattr_tx, &param);

	for (i = 0; i < RX_CHANNEL_COUNT; i++)
		pthread_create(&rx_channels[i].tid, NULL, rx_thread, (void *)&rx_channels[i]);

	for (i = 0; i < TX_CHANNEL_COUNT; i++)
		pthread_create(&tx_channels[i].tid, &tattr_tx, tx_thread, (void *)&tx_channels[i]);
}

/*******************************************************************************************************************/
/*
 * The main program starts the transmit thread and then does the receive processing to do a number of DMA transfers.
 */
int main(int argc, char *argv[])
{
	int i;
	uint64_t start_time, end_time, time_diff;
	int mb_sec;
	int buffer_id = 0;
	int max_channel_count = MAX(TX_CHANNEL_COUNT, RX_CHANNEL_COUNT);

	printf("DMA proxy test\n");

	signal(SIGINT, sigint);

	if ((argc != 3) && (argc != 4)) {
		printf("Usage: dma-proxy-test <# of DMA transfers to perform> <# of bytes in each transfer in KB (< 1MB)> <optional verify, 0 or 1>\n");
		exit(EXIT_FAILURE);
	}

	/* Get the number of transfers to perform */

	num_transfers = atoi(argv[1]);

	/* Get the size of the test to run, making sure it's not bigger than the size of the buffers and
	 * convert it from KB to bytes
	 */
	test_size = atoi(argv[2]);
	if (test_size > BUFFER_SIZE)
		test_size = BUFFER_SIZE;
	test_size *= 1024;

	/* Verify is off by default to get pure performance of the DMA transfers without the CPU accessing all the data
	 * to slow it down.
	 */
	if (argc == 4)
		verify = atoi(argv[3]);
	printf("Verify = %d\n", verify);

	/* Open the file descriptors for each tx channel and map the kernel driver memory into user space */

	for (i = 0; i < TX_CHANNEL_COUNT; i++) {
		char channel_name[64] = "/dev/";
		strcat(channel_name, tx_channel_names[i]);
		tx_channels[i].fd = open(channel_name, O_RDWR);
		if (tx_channels[i].fd < 1) {
			printf("Unable to open DMA proxy device file: %s\r", channel_name);
			exit(EXIT_FAILURE);
		}
		tx_channels[i].buf_ptr = (struct channel_buffer *)mmap(NULL, sizeof(struct channel_buffer) * TX_BUFFER_COUNT,
										PROT_READ | PROT_WRITE, MAP_SHARED, tx_channels[i].fd, 0);
		if (tx_channels[i].buf_ptr == MAP_FAILED) {
			printf("Failed to mmap tx channel\n");
			exit(EXIT_FAILURE);
		}
	}

	/* Open the file descriptors for each rx channel and map the kernel driver memory into user space */

	for (i = 0; i < RX_CHANNEL_COUNT; i++) {
		char channel_name[64] = "/dev/";
		strcat(channel_name, rx_channel_names[i]);
		rx_channels[i].fd = open(channel_name, O_RDWR);
		if (rx_channels[i].fd < 1) {
			printf("Unable to open DMA proxy device file: %s\r", channel_name);
			exit(EXIT_FAILURE);
		}
		rx_channels[i].buf_ptr = (struct channel_buffer *)mmap(NULL, sizeof(struct channel_buffer) * RX_BUFFER_COUNT,
										PROT_READ | PROT_WRITE, MAP_SHARED, rx_channels[i].fd, 0);
		if (rx_channels[i].buf_ptr == MAP_FAILED) {
			printf("Failed to mmap rx channel\n");
			exit(EXIT_FAILURE);
		}
	}

	/* Grab the start time to calculate performance then start the threads & transfers on all channels */

	start_time = get_posix_clock_time_usec();
	setup_threads(&num_transfers);

	/* Do the minimum to know the transfers are done before getting the time for performance */

	for (i = 0; i < RX_CHANNEL_COUNT; i++)
		pthread_join(rx_channels[i].tid, NULL);

	/* Grab the end time and calculate the performance */

	end_time = get_posix_clock_time_usec();
	time_diff = end_time - start_time;
	mb_sec = ((1000000 / (double)time_diff) * (num_transfers * max_channel_count * (double)test_size)) / 1000000;

	printf("Time: %d microseconds\n", time_diff);
	printf("Transfer size: %d KB\n", (long long)(num_transfers) * (test_size / 1024) * max_channel_count);
	printf("Throughput: %d MB / sec \n", mb_sec);

	/* Clean up all the channels before leaving */

	for (i = 0; i < TX_CHANNEL_COUNT; i++) {
		pthread_join(tx_channels[i].tid, NULL);
		munmap(tx_channels[i].buf_ptr, sizeof(struct channel_buffer));
		close(tx_channels[i].fd);
	}
	for (i = 0; i < RX_CHANNEL_COUNT; i++) {
		munmap(rx_channels[i].buf_ptr, sizeof(struct channel_buffer));
		close(rx_channels[i].fd);
	}

	printf("DMA proxy test complete\n");

	return 0;
}
