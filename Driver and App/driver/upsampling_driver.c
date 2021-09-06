#include <linux/init.h>
#include <linux/module.h>
#include <linux/fs.h>
#include <linux/types.h>
#include <linux/cdev.h>
#include <linux/kdev_t.h>
#include <linux/uaccess.h>
#include <linux/errno.h>
#include <linux/kernel.h>
#include <linux/device.h>
#include <linux/string.h>

#include <linux/io.h> //iowrite ioread
#include <linux/slab.h>//kmalloc kfree
#include <linux/platform_device.h>//platform driver
#include <linux/of.h>//of match table
#include <linux/ioport.h>//ioremap

#define DRIVER_NAME "upsampling_driver"
#define DEVICE_NAME "upsampling"		// <-------- proveriti nakon Petalinux da li ce biti isto "upsampling"

MODULE_AUTHOR ("LARB");
MODULE_DESCRIPTION("Driver for Upsampling IP.");
MODULE_LICENSE("Dual BSD/GPL");
MODULE_ALIAS("custom:sisyphus");


dev_t my_dev_id;
static struct class *my_class;
static struct device *my_device;
static struct cdev *my_cdev;

struct upsampling_info {
	unsigned long mem_start;
	unsigned long mem_end;
	void __iomem *base_addr;
	
};

//------------------------ prototypes ------------------------//
static int upsampling_probe (struct platform_device *pdev);
static int upsampling_remove (struct platform_device *pdev);
static int upsampling_open (struct inode *pinode, struct file *pfile);
static int upsampling_close (struct inode *pinode, struct file *pfile);
static ssize_t upsampling_read (struct file *pfile, char __user *buf, size_t length, loff_t *offset);
static ssize_t upsampling_write (struct file *pfile, const char __user *buf, size_t length, loff_t *offset);
static int __init upsampling_init(void);
static void __exit upsampling_exit(void);

struct file_operations my_fops =
{
	.owner = THIS_MODULE,
	.open = upsampling_open,
	.read = upsampling_read,
	.write = upsampling_write,
	.release = upsampling_close,
};

static struct of_device_id upsampling_of_match[] = {					
	{ .compatible = "", },									// <-------- dodati kad se napravi device_tree u Petalinux
	{ /* end of list */ },
};

static struct platform_driver upsampling_driver = {
	.driver = {
		.name = DRIVER_NAME,
		.owner = THIS_MODULE,
		.of_match_table	= upsampling_of_match,
	},
	.probe	= upsampling_probe,
	.remove	= upsampling_remove,
};

MODULE_DEVICE_TABLE(of, upsampling_of_match);

//------------------------ probe ------------------------//

static int upsampling_probe(struct platform_device *pdev)
{
	struct resource *r_mem;
	int rc = 0;
	
	printk(KERN_INFO "Starting upsampling_probe\n");
	
	// Get phisical register adress space from device tree
	r_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	if (r_mem)
	{
		printk(KERN_ALERT "Failed to get resource\n");
		return -ENODEV;
	}
	
	// Get memory for structure upsampling_info
	upp = (struct upsampling_info *) kmalloc(sizeof(struct upsampling_info), GFP_KERNEL);
	if (!upp) 
	{
		printk(KERN_ALERT "Could not allocate upsampling device\n");
		return -ENOMEM;
	}
	
	// Put phisical adresses in upsampling_info structure
	upp->mem_start = r_mem->start;
	upp->mem_end = r_mem->end;
	
	// Reserve that memory space for this drive
	if (!request_mem_region(upp->mem_start, upp->mem_end - upp->mem_start + 1, DEVICE_NAME))
	{
		printk(KERN_ALERT "Could not lock memory region at %p\n",(void *)tp->mem_start);
		rc = -EBUSY;
		goto error_1
	}
	
	// Remap phisical to virtual adresses
	upp->base_addr = ioremap(upp->mem_start, upp->mem_end - upp->mem_start + 1);
	if (!upp->base_addr) {
		printk(KERN_ALERT "Could not allocate memory\n");
		rc = -EIO;
		goto error2;
	}
	
	printk(KERN_NOTICE "Upsampling driver registered\n");
	return 0;
	
	
	error2:
		release_mem_region(upp->mem_start, upp->mem_end - upp->mem_start + 1);
		kfree(upp);
	error_1:
		return rc;
	
}

//------------------------ remove ------------------------//

static int upsampling_remove(struct platform_device *pdev)
{
	printk(KERN_INFO "Starting upsampling_remove\n");
	
	iowrite32(0, upp->base_addr);
	iounmap(upp->base_addr);
	release_mem_region(upp->mem_start, upp->mem_end - upp->start + 1);
	kfree(upp);
	printk(KERN_WARNING "Upsampling driver removed\n");
	
	return 0;	
}

//------------------------ file operations ------------------------//

int upsampling_open(struct inode *pinode, struct file *pfile) 
{
	printk(KERN_INFO "Succesfully opened file\n");
	return 0;
}

int upsampling_close(struct inode *pinode, struct file *pfile) 
{
	printk(KERN_INFO "Succesfully closed file\n");
	return 0;
}

ssize_t upsampling_read(struct file *pfile, char __user *buffer, size_t length, loff_t *offset) 
{
	
	
	
}

ssize_t upsampling_write(struct file *pfile, const char __user *buffer, size_t length, loff_t *offset)
{
	
	
	
}

//********************* INIT & EXIT functions *********************//

static int __init upsampling_init(void)
{
	int ret = 0;
	ret = alloc_chrdev_region(&my_dev_id, 0, 1, DRIVER_NAME);		
	if (ret != 0) 
	{
		printk(KERN_ERR "failed to register char device\n");
		return ret;
	}
	printk(KERN_INFO "char device region allocated\n");
	
	my_class = class_create(THIS_MODULE, "upsampling_class");
	if (my_class == NULL) 
	{
		printk(KERN_ERR "failed to create class\n");
		goto fail_0;		
	}
	printk(KERN_INFO "class created\n");
	
	my_device = device_create(my_class, NULL, my_dev_id, NULL, DRIVER_NAME);
	if (my_device == NUL)
	{
		printk(KERN_ERR "failed to create device\n");
		goto fail_1;
	}
	printk(KERN_INFO "device created\n");
	
	my_cdev = cdev_alloc();
	my_cdev->ops = &my_fops;
	my_cdev->owner = THIS_MODULE;
	ret = cdev_add(my_cdev, my_dev_id, 1);
	if (ret)
	{
		printk(KERN_ERR "failed to add cdev\n");
		goto fail_2;		
	}
	printk(KERN_INFO "cdev added\n");
	printk(KERN_INFO "upsampling: Hello world!\n");
	
	return platform_driver_register(&upsampling_driver);
	
	fail_2:
		device_destroy(my_class, my_dev_id);
	fail_1:
		class_destroy(my_class);
	fail_0:
		unregister_chrdev_region(my_dev_id, 1);
	
	return -1;
}

static int __init upsampling_exit(void)
{
	printk(KERN_INFO "Exit called\n");
	platform_driver_unregister(&upsampling_driver);
	printk(KERN_INFO "Platform driver unregistered\n");
	cdev_del(my_cdev);
	printk(KERN_INFO "cdev removed\n");
	device_destroy(my_class, my_dev_id);
	printk(KERN_INFO "device removed\n");
	uregister_chrdev_region(my_dev_id, 1);
	printk(KERN_INFO "upsampling: Goodbye world\n");	
	
}

module_init(upsampling_init);
module_exit(upsampling_exit);
