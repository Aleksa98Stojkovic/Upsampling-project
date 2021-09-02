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
#include <linux/of.h>

//#include <linux/mm.h> //memory mapping
#include <linux/io.h> //iowrite ioread
#include <linux/slab.h>//kmalloc kfree
#include <linux/platform_device.h>//platform driver
#include <linux/of.h>//of match table
#include <linux/ioport.h>//ioremap

#define DRIVER_NAME "upsampling_driver"
#define DEVICE_NAME "upsampling"

MODULE_AUTHOR ("LARB");
MODULE_DESCRIPTION("Driver for Upsampling IP.");
MODULE_LICENSE("Dual BSD/GPL");
MODULE_ALIAS("custom:sisyphus");


dev_t my_dev_id;
static struct class *my_class;
static struct device *my_device;
static struct cdev *my_cdev;

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

static struct of_device_id upsampling_of_match[] = {					// <---- !!!!!!!!!!!!!!!!!!!!!!!!
	{ .compatible = "", },
	{ /* end of list */ },
};

static struct platform_driver upsampling_driver = {
	.driver = {
		.name = DRIVER_NAME,
		.owner = THIS_MODULE,
		.of_match_table	= upsampling_of_match,
	},
	.probe		= upsampling_probe,
	.remove		= upsampling_remove,
};

MODULE_DEVICE_TABLE(of, upsampling_of_match);

//------------------------ probe ------------------------//

static int upsampling_probe(struct platform_device *pdev)
{
	
	
	
}

//------------------------ remove ------------------------//

static int upsampling_remove(struct platform_device *pdev)
{
	
	
	
}

//------------------------ file operations ------------------------//

int upsampling_open(struct inode *pinode, struct file *pfile) 
{
	printk(KERN_INFO "Succesfully opened upsampling\n");
	return 0;
}

int upsampling_close(struct inode *pinode, struct file *pfile) 
{
	printk(KERN_INFO "Succesfully closed upsampling\n");
	return 0;
}

ssize_t upsampling_read(struct file *pfile, char __user *buffer, size_t length, loff_t *offset) 
{
	
	
	
}

ssize_t upsampling_write(struct file *pfile, const char __user *buffer, size_t length, loff_t *offset)
{
	
	
	
}

static int __init upsampling_init(void)
{
	
	
	
}

static int __init upsampling_exit(void)
{
	
	
	
}

module_init(upsampling_init);
module_exit(upsampling_exit);
