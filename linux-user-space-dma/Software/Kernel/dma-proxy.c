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

/*
 * DMA Proxy
 *
 * This module is designed to be a small example of a DMA device driver that is
 * a client to the DMA Engine using the AXI DMA / MCDMA driver. It serves as a proxy
 * for kernel space DMA control to a user space application.
 *
 * A zero copy scheme is provided by allowing user space to mmap a kernel allocated
 * memory region into user space, referred to as a set of channel buffers. Ioctl functions 
 * are provided to start a DMA transfer (non-blocking), finish a DMA transfer (blocking) 
 * previously started, or start and finish a DMA transfer blocking until it is complete.
 * An input argument which specifies a channel buffer number (0 - N) to be used for the
 * transfer is required.
 *
 * By default the kernel memory allocated for user space mapping is going to be 
 * non-cached at this time. Non-cached memory is pretty slow for the application.
 * A h/w coherent system for MPSOC has been tested and is recommended for higher
 * performance applications. 
 *
 * Hardware coherency requires the following items in the system as documented on the 
 * Xilinx wiki and summarized below::
 *   The AXI DMA read and write channels AXI signals must be tied to the correct state to
 *    generate coherent transactions.
 *   An HPC slave port on MPSOC is required
 *   The CCI of MPSOC must be initialized prior to the APU booting Linux
 *   A dma-coherent property is added in the device tree for the proxy driver.
 *
 * There is an associated user space application, dma_proxy_test.c, and dma_proxy.h
 * that works with this device driver.
 *
 * The hardware design was tested with an AXI DMA / MCDMA  with scatter gather and
 * with the transmit channel looped back to the receive channel. It should
 * work with or without scatter gather as the scatter gather mentioned in the 
 * driver is only at the s/w framework level rather than in the hw.
 *
 * This driver is character driver which creates devices that user space can
 * access for each DMA channel, such as /dev/dma_proxy_rx and /dev/dma_proxy_tx.
 * The number and names of channels are taken from the device tree.
 * Multiple instances of the driver (with multiple IPs) are also supported.

 * An internal test mode is provided to allow it to be self testing without the 
 * need for a user space application and this mode is good for making bigger
 * changes to this driver.
 *
 * This driver is designed to be simple to help users get familiar with how to 
 * use the DMA driver provided by Xilinx which uses the Linux DMA Engine. 
 *
 * To use this driver a node must be added into the device tree.  Add a 
 * node similar to the examples below adjusting the dmas property to match the
 * name of the AXI DMA / MCDMA node.
 * 
 * The dmas property contains pairs with the first of each pair being a reference
 * to the DMA IP in the device tree and the second of each pair being the
 * channel of the DMA IP. For the AXI DMA IP the transmit channel is always 0 and
 * the receive is always 1. For the AXI MCDMA IP the 1st transmit channel is
 * always 0 and receive channels start at 16 since there can be a maximum of 16
 * transmit channels. Each name in the dma-names corresponds to a pair in the dmas
 * property and is only a logical name that allows user space access to the channel
 * such that the name can be any name as long as it is unique.
 *
 *    For h/w coherent systems with MPSoC, the property dma-coherent can be added
 * to the node in the device tree. 
 * 
 * Example device tree nodes: 
 *
 * For AXI DMA with transmit and receive channels with a loopback in hardware
 * 
 * dma_proxy {
 *   compatible ="xlnx,dma_proxy";
 *   dmas = <&axi_dma_1_loopback 0  &axi_dma_1_loopback 1>;
 *   dma-names = "dma_proxy_tx", "dma_proxy_rx";
 * };
 *
 * For AXI DMA with only the receive channel
 * 
 * dma_proxy2 {
 *   compatible ="xlnx,dma_proxy";
 *   dmas = <&axi_dma_0_noloopback 1>;
 *   dma-names = "dma_proxy_rx_only";
 * };
 *
 * For AXI MCDMA with two channels 
 *
 * dma_proxy3 {
 *   compatible ="xlnx,dma_proxy";
 *   dmas = <&axi_mcdma_0 0  &axi_mcdma_0 16 &axi_mcdma_0 1 &axi_mcdma_0 17> ;
 *   dma-names = "dma_proxy_tx_0", "dma_proxy_rx_0", "dma_proxy_tx_1", "dma_proxy_rx_1";
 * };
 */

#include <linux/dmaengine.h>
#include <linux/module.h>
#include <linux/version.h>
#include <linux/kernel.h>
#include <linux/dma-mapping.h>
#include <linux/slab.h>
#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/fs.h>
#include <linux/workqueue.h>
#include <linux/platform_device.h>
#include <linux/of_dma.h>
#include <linux/ioctl.h>
#include <linux/uaccess.h>

#include "dma-proxy.h"

MODULE_LICENSE("GPL");

#define DRIVER_NAME           "dma_proxy"
#define TX_CHANNEL            0
#define RX_CHANNEL            1
#define TEST_SIZE             1024

/*
 * The following module parameter controls if the internal test runs when the module is inserted.
 * Note that this test requires a transmit and receive channel to function and uses the first
 * transmit and receive channnels when multiple channels exist.
 */
static unsigned internal_test = 0;
module_param(internal_test, int, S_IRUGO);

/*
 * Trace functions if enabled
 */
static unsigned trace = 0;
module_param(trace, int, S_IRUGO);

struct proxy_bd;
struct dma_proxy_channel;
struct dma_proxy;

/*
 * The following data structures represent a single channel of DMA, transmit or receive in the case
 * when using AXI DMA.  It contains all the data to be maintained for the channel.
 */
struct proxy_bd {
    struct completion cmp;
    dma_cookie_t cookie;

    dma_addr_t dma_handle;
    struct scatterlist sglist;
};

struct dma_proxy_channel {
    struct channel_buffer *pBufferTable;    /* user to kernel space interface */
    dma_addr_t buffer_phys_addr;

    struct dma_proxy* pDmaProxy;
    struct device *pProxyDevice;                /* character device support */
    struct device *pDmaDevice;
    struct cdev cdev;

    struct proxy_bd pBdTable[BUFFER_COUNT];

    struct dma_chan *pDmaChannel;                /* dma support */
    u32 direction;                        /* DMA_MEM_TO_DEV or DMA_DEV_TO_MEM */
    int bdindex;
    int channel;
};

struct dma_proxy {
    int channel_count;
    struct dma_proxy_channel *pChannels;
    char **names;
    struct work_struct work;
    dev_t dev_node;
    struct class *pClass;
};

/*
 * Handle a callback and indicate the DMA transfer is complete to another
 * thread of control
 */
static void sync_callback(void *completion)
{
    if(trace) {
        printk(KERN_INFO "%s\n",__func__);
    }

    /*
     * Indicate the DMA transaction completed to allow the other
     * thread of control to finish processing
     */
    complete(completion);
}

static void show_buflen(struct dma_proxy_channel *pChannel)
{
    if(trace) {
        int i;

        for(i = 0; i < BUFFER_COUNT; i++) {
            printk(KERN_INFO "%s(%s%d):%d=%05x\n",
                __func__,
                (DMA_MEM_TO_DEV==pChannel->direction)?"TX":"XX",
                pChannel->channel,
                i,
                pChannel->pBufferTable[i].length
                );
        }
    }
}

/*
 * Prepare a DMA buffer to be used in a DMA transaction, submit it to the DMA engine
 * to be queued and return a cookie that can be used to track that status of the
 * transaction
 */
static void start_transfer(struct dma_proxy_channel *pChannel)
{
    enum dma_ctrl_flags flags = DMA_CTRL_ACK | DMA_PREP_INTERRUPT;
    struct dma_async_tx_descriptor *chan_desc;
    struct dma_device *dma_device = pChannel->pDmaChannel->device;
    int bdindex = pChannel->bdindex;

    if(trace) {
        printk(KERN_INFO "%s(%s%d,%d) (len=%08x)\n",
            __func__,
            (DMA_MEM_TO_DEV==pChannel->direction)?"TX":"RX",
            pChannel->channel,
            bdindex,
            pChannel->pBufferTable[bdindex].length
            );
    }

    /*
     * A single entry scatter gather list is used as it's not clear how to do it with a simpler method.
     * Get a descriptor for the transfer ready to submit
     */
	sg_init_table(&pChannel->pBdTable[bdindex].sglist, 1);
	sg_dma_address(&pChannel->pBdTable[bdindex].sglist) = pChannel->pBdTable[bdindex].dma_handle;
	sg_dma_len(&pChannel->pBdTable[bdindex].sglist) = pChannel->pBufferTable[bdindex].length;

    chan_desc = dma_device->device_prep_slave_sg(pChannel->pDmaChannel, &pChannel->pBdTable[bdindex].sglist, 1, 
                        pChannel->direction, flags, NULL);

    if(!chan_desc) {
        printk(KERN_ERR "%s(%d): dmaengine_prep*() error\n",__func__,pChannel->channel);
    } else {
        chan_desc->callback = sync_callback;
        chan_desc->callback_param = &pChannel->pBdTable[bdindex].cmp;

        /*
         * Initialize the completion for the transfer and before using it
         * then submit the transaction to the DMA engine so that it's queued
         * up to be processed later and get a cookie to track it's status
         */
        init_completion(&pChannel->pBdTable[bdindex].cmp);

        pChannel->pBdTable[bdindex].cookie = dmaengine_submit(chan_desc);
        if(dma_submit_error(pChannel->pBdTable[bdindex].cookie)) {
            printk(KERN_ERR "%s(%d): Submit error\n",__func__,pChannel->channel);
             return;
        }

        /*
         * Start the DMA transaction which was previously queued up in the DMA engine
         */
        dma_async_issue_pending(pChannel->pDmaChannel);
    }
}

/*
 * Wait for a DMA transfer that was previously submitted to the DMA engine
 */
static void wait_for_transfer(struct dma_proxy_channel *pChannel)
{
    unsigned long timeout = msecs_to_jiffies(3000);
    enum dma_status status;
    int bdindex = pChannel->bdindex;

    if(trace) {
        printk(KERN_INFO "%s(%s%d,%d)\n",__func__,(DMA_MEM_TO_DEV==pChannel->direction)?"TX":"RX",pChannel->channel,bdindex);
    }

    pChannel->pBufferTable[bdindex].status = PROXY_BUSY;

    /*
     * Wait for the transaction to complete, or timeout, or get an error
     */
    timeout = wait_for_completion_timeout(&pChannel->pBdTable[bdindex].cmp, timeout);
    status = dma_async_is_tx_complete(pChannel->pDmaChannel, pChannel->pBdTable[bdindex].cookie, NULL, NULL);

    if(timeout == 0)  {
        pChannel->pBufferTable[bdindex].status  = PROXY_TIMEOUT;
        printk(KERN_ERR "%s(%s%d,%d): DMA timed out\n",
		__func__,
		(DMA_MEM_TO_DEV==pChannel->direction)?"TX":"RX",
		pChannel->channel,
		bdindex
		);
    } else if(status != DMA_COMPLETE) {
        pChannel->pBufferTable[bdindex].status = PROXY_ERROR;
        printk(KERN_ERR "%s(%s%d,%d): DMA returned completion callback status of: %s\n",
            __func__,
	    (DMA_MEM_TO_DEV==pChannel->direction)?"TX":"RX",
            pChannel->channel,
	    bdindex,
            status == DMA_ERROR ? "error" : "in progress"
            );
    } else {
        pChannel->pBufferTable[bdindex].status = PROXY_NO_ERROR;
    }
}

/*
 * The following functions are designed to test the driver from within the device
 * driver without any user space. It uses the first channel buffer for the transmit and receive.
 * If this works but the user application does not then the user application is at fault.
 */
static void tx_test(struct work_struct *local_work)
{
    struct dma_proxy *pDmaProxy;
    pDmaProxy = container_of(local_work, struct dma_proxy, work);

    /*
     * Use the 1st buffer for the test
     */
    pDmaProxy->pChannels[TX_CHANNEL].pBufferTable[0].length = TEST_SIZE;
    pDmaProxy->pChannels[TX_CHANNEL].bdindex = 0;

    start_transfer(&pDmaProxy->pChannels[TX_CHANNEL]);
    wait_for_transfer(&pDmaProxy->pChannels[TX_CHANNEL]);
}

static void test(struct dma_proxy *pDmaProxy)
{
    int i;

    printk(KERN_INFO "Starting internal test\n");

    /*
     * Initialize the buffers for the test
     */
    for(i = 0; i < TEST_SIZE / sizeof(unsigned int); i++) {
        pDmaProxy->pChannels[TX_CHANNEL].pBufferTable[0].buffer[i] = i;
        pDmaProxy->pChannels[RX_CHANNEL].pBufferTable[0].buffer[i] = 0;
    }

    /*
     * Since the transfer function is blocking the transmit channel is started from a worker
     * thread
     */
    INIT_WORK(&pDmaProxy->work, tx_test);
    schedule_work(&pDmaProxy->work);

    /*
     * Receive the data that was just sent and looped back
     */
    pDmaProxy->pChannels[RX_CHANNEL].pBufferTable->length = TEST_SIZE;
    pDmaProxy->pChannels[TX_CHANNEL].bdindex = 0;

    start_transfer(&pDmaProxy->pChannels[RX_CHANNEL]);
    wait_for_transfer(&pDmaProxy->pChannels[RX_CHANNEL]);

    /*
     * Verify the receiver buffer matches the transmit buffer to
     * verify the transfer was good
     */
    for(i = 0; i < TEST_SIZE / sizeof(unsigned int); i++)
        if(pDmaProxy->pChannels[TX_CHANNEL].pBufferTable[0].buffer[i] !=
                pDmaProxy->pChannels[RX_CHANNEL].pBufferTable[0].buffer[i]) {
            printk(KERN_ERR "buffers not equal, first index = %d\n", i);
            break;
        }

    printk(KERN_INFO "Internal test complete\n");
}

/*
 * Map the memory for the channel interface into user space such that user space can
 * access it using coherent memory which will be non-cached for s/w coherent systems
 * such as Zynq 7K or the current default for Zynq MPSOC. MPSOC can be h/w coherent
 * when set up and then the memory will be cached.
 */
static int mmap(struct file *file_p, struct vm_area_struct *vma)
{
    struct dma_proxy_channel *pChannel = (struct dma_proxy_channel *)file_p->private_data;

    return dma_mmap_coherent(pChannel->pDmaDevice, vma,
                       pChannel->pBufferTable, pChannel->buffer_phys_addr,
                       vma->vm_end - vma->vm_start);
}

/*
 * Open the device file and set up the data pointer to the proxy channel data for the
 * proxy channel such that the ioctl function can access the data structure later.
 */
static int local_open(struct inode *ino, struct file *file)
{
    file->private_data = container_of(ino->i_cdev, struct dma_proxy_channel, cdev);

    return 0;
}

/*
 * Close the file and there's nothing to do for it
 */
static int release(struct inode *ino, struct file *file)
{
#if 0
    struct dma_proxy_channel *pChannel = (struct dma_proxy_channel *)file->private_data;
    struct dma_device *dma_device = pChannel->pDmaChannel->device;

    /* Stop all the activity when the channel is closed assuming this
     * may help if the application is aborted without normal closure
     * This is not working and causes an issue that may need investigation in the 
     * DMA driver at the lower level.
     */
    dma_device->device_terminate_all(pChannel->pDmaChannel);
#endif
    return 0;
}

/*
 * Perform I/O control to perform a DMA transfer using the input as an index
 * into the buffer descriptor table such that the application is in control of
 * which buffer to use for the transfer.The BD in this case is only a s/w
 * structure for the proxy driver, not related to the hw BD of the DMA.
 */
static long ioctl(struct file *file, unsigned int cmd, unsigned long arg)
{
    struct dma_proxy_channel *pChannel = (struct dma_proxy_channel *)file->private_data;

    /*
     * Get the bd index from the input argument as all commands require it
     */
    if(copy_from_user(&pChannel->bdindex, (int *)arg, sizeof(pChannel->bdindex)))
        return -EINVAL;

    /*
     * Perform the DMA transfer on the specified channel blocking til it completes
     */
    switch(cmd) {
    case START_XFER:
        start_transfer(pChannel);
        break;
    case FINISH_XFER:
        wait_for_transfer(pChannel);
        break;
    case XFER:
        start_transfer(pChannel);
        wait_for_transfer(pChannel);
        break;
    case SHOW_BUFLEN:
        show_buflen(pChannel);
        break;
    }

    return 0;
}

static struct file_operations dm_fops = {
    .owner    = THIS_MODULE,
    .open     = local_open,
    .release  = release,
    .unlocked_ioctl = ioctl,
    .mmap    = mmap
};


/*
 * Initialize the driver to be a character device such that is responds to
 * file operations.
 */
static int cdevice_init(struct dma_proxy *pDmaProxy, int channel, char *name)
{
    int rc;
    struct dma_proxy_channel *pChannel;

    if(trace) {
        printk(KERN_INFO "%s(%d,%s)\n",__func__,channel,name);
    }
    pChannel = &pDmaProxy->pChannels[channel];

    /*
     * Initialize the device data structure before registering the character 
     * device with the kernel.
     */
    cdev_init(&pChannel->cdev, &dm_fops);
    pChannel->cdev.owner = THIS_MODULE;

    /*
     * Create the device node in /dev so the device is accessible
     * as a character device
     */
    rc = cdev_add(&pChannel->cdev, MKDEV(MAJOR(pDmaProxy->dev_node),channel), 1);
    if(rc) {
        dev_err(pChannel->pDmaDevice, "unable to add char device\n");
        return rc;
    }

    pChannel->pDmaProxy = pDmaProxy;
    pChannel->pProxyDevice = device_create(pDmaProxy->pClass, NULL,
                           MKDEV(MAJOR(pDmaProxy->dev_node),channel), NULL, name);
    if(IS_ERR_OR_NULL(pChannel->pProxyDevice)) {
        dev_err(pChannel->pDmaDevice, "unable to create the device\n");
        cdev_del(&pChannel->cdev);
        if(!pChannel->pProxyDevice) {
            rc =- -ENOMEM;
        } else {
            rc = PTR_ERR(pChannel->pProxyDevice);
        }
    }

    return rc;
}

/*
 * Exit the character device by freeing up the resources that it created and
 * disconnecting itself from the kernel.
 */
static void cdevice_exit(struct dma_proxy_channel *pChannel)
{
    /* Take everything down in the reverse order
     * from how it was created for the char device
     */
    if(pChannel->pProxyDevice) {
        device_destroy(pChannel->pDmaProxy->pClass, pChannel->cdev.dev);

        cdev_del(&pChannel->cdev);
    }
}

/*
 * Create a DMA channel by getting a DMA channel from the DMA Engine and then setting
 * up the channel as a character device to allow user space control.
 */
static int create_channel(struct platform_device *pdev, struct dma_proxy* pDmaProxy, int channel, u32 direction)
{
    int rc, bd;
    struct dma_proxy_channel *pChannel;
    char *name;

    /*
     * Request the DMA channel from the DMA engine and then use the device from
     * the channel for the proxy channel also.
     */
    pChannel = &pDmaProxy->pChannels[channel];
    name = pDmaProxy->names[channel];
    if(trace) {
        printk(KERN_INFO "%s(%s)\n",__func__,name);
    }
    pChannel->channel = channel;
    pChannel->pDmaDevice = &pdev->dev;
    pChannel->pDmaChannel = dma_request_chan(&pdev->dev, name);
    if(IS_ERR_OR_NULL(pChannel->pDmaChannel)) {
        dev_err(pChannel->pDmaDevice, "DMA channel request error: %s\n",name);
        if(!pChannel->pDmaChannel) {
            return -ENODEV;
        } else {
            return PTR_ERR(pChannel->pDmaChannel);
        }
    }

    /*
     * Initialize the character device for the dma proxy channel
     */
    rc = cdevice_init(pDmaProxy, channel, name);
    if(rc) {
        return rc;
    }

    pChannel->direction = direction;

    /*
     * Allocate DMA memory that will be shared/mapped by user space, allocating
     * a set of buffers for the channel with user space specifying which buffer
     * to use for a tranfer..
     */
    pChannel->pBufferTable = (struct channel_buffer *)
        dmam_alloc_coherent(pChannel->pDmaDevice,
                    sizeof(struct channel_buffer) * BUFFER_COUNT,
                    &pChannel->buffer_phys_addr, GFP_KERNEL);
    if(IS_ERR_OR_NULL(pChannel->pBufferTable)) {
        dev_err(pChannel->pDmaDevice, "DMA allocation error\n");
        if(!pChannel->pBufferTable) {
            return -ENOMEM;
        } else {
            return PTR_ERR(pChannel->pBufferTable);
        }
    }
    if(trace) {
        printk(KERN_INFO "Allocating memory, virtual address: %px physical address: %px\n",
                pChannel->pBufferTable, (void *)pChannel->buffer_phys_addr);
    }

    /*
     * Initialize each entry in the buffer descriptor table such that the physical address    
     * address of each buffer is ready to use later.
     */
    for(bd = 0; bd < BUFFER_COUNT; bd++) {
        pChannel->pBdTable[bd].dma_handle = (dma_addr_t)(pChannel->buffer_phys_addr + 
                        (sizeof(struct channel_buffer) * bd) + offsetof(struct channel_buffer, buffer));
        if(trace) {
            printk(KERN_INFO "\t%d: pa=%px\n",bd,(void*)pChannel->pBdTable[bd].dma_handle);
        }
    }

    /*
     * The buffer descriptor index into the channel buffers should be specified in each 
     * ioctl but we will initialize it to be safe.
     */
    pChannel->bdindex = 0;
    return 0;
}
/* Initialize the dma proxy device driver module.
 */
static int dma_proxy_probe(struct platform_device *pdev)
{
    int rc, channel;
    struct dma_proxy *pDmaProxy;
    struct device *dev = &pdev->dev;
    enum dma_transfer_direction eDmaTransferDirection;

    if(trace) {
        printk(KERN_INFO "dma_proxy module initialized\n");
    }
    
    pDmaProxy = (struct dma_proxy *) devm_kmalloc(&pdev->dev, sizeof(struct dma_proxy), GFP_KERNEL);
    if(IS_ERR_OR_NULL(pDmaProxy)) {
        dev_err(dev, "Cound not allocate proxy device\n");
        if(!pDmaProxy) {
            return -ENOMEM;
        } else {
            return PTR_ERR(pDmaProxy);
        }
    }
    dev_set_drvdata(dev, pDmaProxy);

    /*
     * Figure out how many pChannels there are from the device tree based
     * on the number of strings in the dma-names property
     */
    pDmaProxy->channel_count = device_property_read_string_array(&pdev->dev,
                         "dma-names", NULL, 0);
    if(pDmaProxy->channel_count <= 0) {
        return 0;
    }

    if(trace) {
        printk(KERN_INFO "Device Tree Channel Count: %d\r\n", pDmaProxy->channel_count);
    }

    /*
     * Allocate the memory for channel names and then get the names
     * from the device tree
     */
    pDmaProxy->names = devm_kmalloc_array(&pdev->dev, pDmaProxy->channel_count, 
            sizeof(char *), GFP_KERNEL);
    if(IS_ERR_OR_NULL(pDmaProxy->names)) {
        dev_err(dev, "Cound not allocate names\n");
        if(!pDmaProxy->names) {
            return -ENOMEM;
        } else {
            return PTR_ERR(pDmaProxy->names);
        }
    }

    rc = device_property_read_string_array(&pdev->dev, "dma-names", 
                    (const char **)pDmaProxy->names, pDmaProxy->channel_count);
    if(rc < 0) {
        return rc;
    }
    
    /*
     * Allocate the memory for the pChannels since the number is known.
     */
    pDmaProxy->pChannels = devm_kmalloc(&pdev->dev,
            sizeof(struct dma_proxy_channel) * pDmaProxy->channel_count, GFP_KERNEL);
    if(IS_ERR_OR_NULL(pDmaProxy->pChannels)) {
        if(!pDmaProxy->pChannels) {
            return -ENOMEM;
        } else {
            return PTR_ERR(pDmaProxy->pChannels);
        }
    }

    pDmaProxy->pClass = class_create(
#if LINUX_VERSION_CODE <= KERNEL_VERSION(6, 3, 13)
                             THIS_MODULE,
#endif
                             DRIVER_NAME
                             );
    if(IS_ERR_OR_NULL(pDmaProxy->pClass)) {
        dev_err(dev, "unable to create class\n");
        if(!pDmaProxy->pClass) {
            rc = -ENOMEM;
        } else {
            rc = PTR_ERR(pDmaProxy->pClass);
        }
        return rc;
    }

    /*
     * Allocate a region to get a major number
     */
    rc = alloc_chrdev_region(&pDmaProxy->dev_node, 0, pDmaProxy->channel_count, DRIVER_NAME);
    if(rc) {
        dev_err(dev, "unable to get a char device number\n");
        return rc;
    }

    /*
     * Create the pChannels in the proxy. The direction does not matter
     * as the DMA channel has it inside it and uses it, other than this will not work 
     * for cyclic mode.
     */
    for(channel = 0; channel < pDmaProxy->channel_count; channel++) {
        if(trace) {
            printk(KERN_INFO "Creating channel %s\r\n", pDmaProxy->names[channel]);
        }
        if(NULL != strstr(pDmaProxy->names[channel],"rx")) {
            eDmaTransferDirection = DMA_DEV_TO_MEM;
        } else {
            eDmaTransferDirection = DMA_MEM_TO_DEV;
        }
        rc = create_channel(pdev, pDmaProxy, channel, eDmaTransferDirection);
        if(rc) {
            return rc;
        }
    }

    if(internal_test) {
        test(pDmaProxy);
    }
    return 0;
}
 
/* Exit the dma proxy device driver module.
 */
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 11, 0)
static void dma_proxy_remove(struct platform_device *pdev)
#else
static int dma_proxy_remove(struct platform_device *pdev)
#endif
{
    int i;
    struct device *dev = &pdev->dev;
    struct dma_proxy *pDmaProxy = dev_get_drvdata(dev);

    if(trace) {
        printk(KERN_INFO "dma_proxy module exited\n");
    }

    /*
     * Take care of the char device infrastructure for each
     * channel except for the last channel. Handle the last
     * channel seperately.
     */
    for(i = 0; i < pDmaProxy->channel_count; i++) { 
        if(pDmaProxy->pChannels[i].pProxyDevice) {
            cdevice_exit(&pDmaProxy->pChannels[i]);
        }
    }

    /* Take care of the DMA pChannels and any buffers allocated
     * for the DMA transfers. The DMA buffers are using managed
     * memory such that it's automatically done.
     */
    for(i = 0; i < pDmaProxy->channel_count; i++) {
        if(pDmaProxy->pChannels[i].pDmaChannel) {
            pDmaProxy->pChannels[i].pDmaChannel->device->device_terminate_all(pDmaProxy->pChannels[i].pDmaChannel);
            dma_release_channel(pDmaProxy->pChannels[i].pDmaChannel);
        }
    }

    class_destroy(pDmaProxy->pClass);
    unregister_chrdev_region(pDmaProxy->dev_node,pDmaProxy->channel_count);
#if LINUX_VERSION_CODE < KERNEL_VERSION(6, 11, 0)
    return 0;
#endif
}

static const struct of_device_id dma_proxy_of_ids[] = {
    { .compatible = "xlnx,dma_proxy",},
    {}
};

static struct platform_driver dma_proxy_driver = {
    .driver = {
        .name = "dma_proxy_driver",
        .owner = THIS_MODULE,
        .of_match_table = dma_proxy_of_ids,
    },
    .probe = dma_proxy_probe,
    .remove = dma_proxy_remove,
};

static int __init dma_proxy_init(void)
{
    return platform_driver_register(&dma_proxy_driver);

}

static void __exit dma_proxy_exit(void)
{
    platform_driver_unregister(&dma_proxy_driver);
}

module_init(dma_proxy_init)
module_exit(dma_proxy_exit)

MODULE_AUTHOR("Xilinx, Inc.");
MODULE_DESCRIPTION("DMA Proxy Prototype");
MODULE_LICENSE("GPL v2");
