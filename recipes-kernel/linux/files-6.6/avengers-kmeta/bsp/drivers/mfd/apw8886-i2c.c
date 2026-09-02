// SPDX-License-Identifier: GPL-2.0-only
/*
 * apw8886-i2c.c - Anpec APW8886 PMIC I2C driver
 *
 * Copyright (C) 2018-2020 Realtek Semiconductor Corporation
 * Author: Cheng-Yu Lee <cylee12@realtek.com>
 */

#include <linux/delay.h>
#include <linux/gpio/consumer.h>
#include <linux/i2c.h>
#include <linux/interrupt.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/of.h>
#include <linux/of_device.h>
#include <linux/pm.h>
#include <linux/reboot.h>
#include <linux/regmap.h>
#include <linux/mfd/core.h>
#include <linux/mfd/apw888x.h>
#include <linux/mfd/apw8886.h>


static bool apw8886_regmap_readable_reg(struct device *dev, unsigned int reg)
{
	switch (reg) {
	case APW8886_REG_INTR ... APW8886_REG_PWRKEY:
	case APW8886_REG_FAULT_STATUS:
	case APW8886_REG_SYS_CONTROL ... APW8886_REG_LDO1_SLPVOLT:
	case APW8886_REG_CLAMP:
	case APW8886_REG_VFB5_REF_VOLT_DAC:
	case APW8886_REG_CHIP_ID:
	case APW8886_REG_VERSION:
		return true;
	}
	return false;
}

static bool apw8886_regmap_writeable_reg(struct device *dev, unsigned int reg)
{
	switch (reg) {
	case APW8886_REG_INTR ... APW8886_REG_PWRKEY:
	case APW8886_REG_SYS_CONTROL ... APW8886_REG_LDO1_SLPVOLT:
	case APW8886_REG_VFB5_REF_VOLT_DAC:
	case APW8886_REG_CLAMP:
		return true;
	}
	return false;
}

static bool apw8886_regmap_volatile_reg(struct device *dev, unsigned int reg)
{
	switch (reg) {
	case APW8886_REG_INTR ... APW8886_REG_PWRKEY:
	case APW8886_REG_FAULT_STATUS:
	case APW8886_REG_SYS_CONTROL:
	case APW8886_REG_CLAMP:
	case APW8886_REG_CHIP_ID:
	case APW8886_REG_VERSION:
		return true;
	}
	return false;
}

static bool apw8886_regmap_precious_reg(struct device *dev, unsigned int reg)
{
        return reg == APW8886_REG_INTR;
}

static const struct regmap_config apw8886_regmap_config = {
	.reg_bits         = 8,
	.val_bits         = 8,
	.max_register     = 0x1F,
	.cache_type       = REGCACHE_RBTREE,
	.readable_reg     = apw8886_regmap_readable_reg,
	.writeable_reg    = apw8886_regmap_writeable_reg,
	.volatile_reg     = apw8886_regmap_volatile_reg,
	.precious_reg     = apw8886_regmap_precious_reg,
};

static inline unsigned long apw8886_i2c_get_driver_data(struct i2c_client *client)
{
	if (IS_ENABLED(CONFIG_OF) && client->dev.of_node)
		return (unsigned long)of_device_get_match_data(&client->dev);
	return (uintptr_t)i2c_get_match_data(client);
}

static int apw8886_chip_id_valid(u32 chip_id)
{
	return chip_id == 0x5a || chip_id == 0x9a || chip_id == 0xda;
}

static struct mfd_cell apw8886_devs[] = {
	{
		.name = "apw8886-regulator",
		.of_compatible = "anpec,apw8886-regulator",
	},
};

static irqreturn_t apw8886_irq_thread(int irq, void *data)
{
	struct apw888x_device *adev = data;
	unsigned int val = 0;
	int ret;

	ret = regmap_read(adev->regmap, APW8886_REG_INTR, &val);
	if (ret) {
		dev_err(adev->dev, "failed to read INTR: %d\n", ret);
		return IRQ_HANDLED;
	}
	dev_info(adev->dev, "INTR = %#04x\n", val);

	/* long press only - short press (PWRKEY_IT) is ignored */
	if (val & APW8886_INTR_PWRKEY_LP_MASK) {
		dev_info(adev->dev, "PWRKEY long-press -> orderly_poweroff\n");
		orderly_poweroff(true);
	}

	ret = regmap_write(adev->regmap, APW8886_REG_INTR, 0x00);
	if (ret)
		dev_err(adev->dev, "failed to clear INTR: %d\n", ret);

	return IRQ_HANDLED;
}

static int apw8886_i2c_probe(struct i2c_client *client)
{
	struct device *dev = &client->dev;
	struct apw888x_device *adev;
	int ret;
	u32 chip_id, rev;
	unsigned long pmic_id = apw8886_i2c_get_driver_data(client);

	adev = devm_kzalloc(dev, sizeof(*adev), GFP_KERNEL);
	if (!adev)
		return -ENOMEM;

	adev->regmap = devm_regmap_init_i2c(client, &apw8886_regmap_config);
	if (IS_ERR(adev->regmap))
		return PTR_ERR(adev->regmap);

	/* show chip info */
	ret = regmap_read(adev->regmap, APW8886_REG_CHIP_ID, &chip_id);
	if (ret) {
		dev_err(dev, "failed to read chip_id: %d\n", ret);
		return ret;
	}

	if (!apw8886_chip_id_valid(chip_id)) {
		dev_err(dev, "chip_id(%02x) not match\n", chip_id);
		return -EINVAL;
	}

	regmap_read(adev->regmap, APW8886_REG_VERSION, &rev);
	dev_info(dev, "(%x) rev%d\n", chip_id, rev);

	adev->chip_id = pmic_id;
	adev->chip_rev = rev;
	adev->dev = dev;
	i2c_set_clientdata(client, adev);

	ret = devm_mfd_add_devices(adev->dev, PLATFORM_DEVID_NONE,
		apw8886_devs, ARRAY_SIZE(apw8886_devs), 0, 0, 0);
	if (ret) {
		dev_err(dev, "failed to add sub-devices: %d\n", ret);
		return ret;
	}

	adev->led_gpio = devm_gpiod_get_optional(dev, "led", GPIOD_OUT_HIGH);
	if (IS_ERR(adev->led_gpio)) {
		dev_warn(dev, "led gpio: %ld\n", PTR_ERR(adev->led_gpio));
		adev->led_gpio = NULL;
	}

	if (client->irq > 0) {
		unsigned int stale;

		/*
		 * PWRKEY/PWRKEY_LP/PWRKEY_IT are read-to-clear and nothing ever
		 * read this register before this driver existed, so a stale
		 * event may already be latched. Read first to clear the status
		 * bits, then write 0 to release /INT itself - same order the
		 * interrupt thread uses.
		 */
		ret = regmap_read(adev->regmap, APW8886_REG_INTR, &stale);
		if (ret)
			dev_err(dev, "failed to read stale INTR: %d\n", ret);

		ret = regmap_write(adev->regmap, APW8886_REG_INTR, 0x00);
		if (ret)
			dev_err(dev, "failed to clear stale INTR: %d\n", ret);

		/*
		 * Mask only the raw PWRKEY toggle-low pulse. PWRKEY_IT stays
		 * unmasked so a short press still drops /INT - needed for the
		 * ISO wake controller to resume from S3 on a tap. The runtime
		 * IRQ it causes is a no-op (apw8886_irq_thread only acts on LP).
		 * PWRKEY_LP stays unmasked for the long-press power-off.
		 */
		ret = regmap_update_bits(adev->regmap, APW8886_REG_INTR_MASK,
			APW8886_INTRMASK_PWRKEY | APW8886_INTRMASK_IT,
			APW8886_INTRMASK_PWRKEY);
		if (ret)
			dev_err(dev, "failed to set INTR_MASK: %d\n", ret);

		/*
		 * Keep the PMIC's own hardware long-press-to-poweroff backstop
		 * (ENLPOFF) enabled - it is the last resort that still cuts power
		 * after TdPWRKEYLPOFF (10s default) even if this driver, its irq,
		 * or all of userspace has wedged. But disable LPOFF_TO_DO, which
		 * defaults to auto-restarting the board 1s after that backstop
		 * fires. Left enabled, it races the PWRKEY_LP -> orderly_poweroff
		 * -> SOFTOFF path above: if /PWRKEY is still physically held when
		 * the 10s hardware timer fires (a graceful shutdown that simply
		 * took a bit longer than 10s), the board reboots on its own
		 * regardless of key state. With LPOFF_TO_DO=0 both the SOFTOFF
		 * path and the hardware backstop behave the same way: power off
		 * and stay off until a fresh press.
		 */
		ret = regmap_update_bits(adev->regmap, APW8886_REG_PWRKEY,
			APW8886_PWRKEY_LPOFF_TO_DO_MASK, 0);
		if (ret)
			dev_err(dev, "failed to disable lpoff auto-restart: %d\n", ret);

		/*
		 * Pass the edge type explicitly as well as in DT - some gpio
		 * irqchips only program the trigger when the request carries
		 * the IRQF_TRIGGER_* bits, otherwise the line never fires.
		 */
		ret = devm_request_threaded_irq(dev, client->irq,
			NULL, apw8886_irq_thread,
			IRQF_TRIGGER_FALLING | IRQF_ONESHOT,
			"apw8886-pwrkey", adev);
		if (ret) {
			dev_err(dev, "failed to request irq: %d\n", ret);
			return ret;
		}

		adev->irq = client->irq;
		device_init_wakeup(dev, true);
	} else {
		dev_warn(dev, "no irq specified, PWRKEY events disabled\n");
	}

	return 0;
}

static void apw8886_i2c_remove(struct i2c_client *client)
{
	struct apw888x_device *adev = i2c_get_clientdata(client);

	device_init_wakeup(&client->dev, false);
}

static int apw8886_suspend(struct device *dev)
{
	struct apw888x_device *adev = dev_get_drvdata(dev);

	if (adev->irq <= 0)
		return 0;

	if (adev->led_gpio) {
		gpiod_set_value_cansleep(adev->led_gpio, 0);
	}

	/* release /INT so a press during S3 leaves a clean falling edge */
	regmap_write(adev->regmap, APW8886_REG_INTR, 0x00);

	if (device_may_wakeup(dev))
		adev->irq_wake_on = !enable_irq_wake(adev->irq);

	return 0;
}

static int apw8886_resume(struct device *dev)
{
	struct apw888x_device *adev = dev_get_drvdata(dev);
	unsigned int val = 0;

	if (adev->irq <= 0)
		return 0;

	if (adev->led_gpio) {
		gpiod_set_value_cansleep(adev->led_gpio, 1);
	}

	if (adev->irq_wake_on) {
		disable_irq_wake(adev->irq);
		adev->irq_wake_on = false;
	}

	/*
	 * In S3 the /PWRKEY edge is caught by the SoC ISO wake controller
	 * (wakeup-gpio-list), not by this threaded irq - so apw8886_irq_thread
	 * never ran and /INT is still held low with PWRKEY_IT latched. Do NOT
	 * re-deliver that press. Just read to log it and
	 * write 0 to release /INT so the edge irq is armed for the next press.
	 */
	regmap_read(adev->regmap, APW8886_REG_INTR, &val);
	dev_info(dev, "resume: INTR = %#04x\n", val);
	regmap_write(adev->regmap, APW8886_REG_INTR, 0x00);

	return 0;
}

static DEFINE_SIMPLE_DEV_PM_OPS(apw8886_pm_ops, apw8886_suspend, apw8886_resume);

static void apw8886_i2c_shutdown(struct i2c_client *client)
{
	struct apw888x_device *adev = i2c_get_clientdata(client);
	unsigned int val = adev->chip_id == APW888X_DEVICE_ID_APW8886 ? 0x24 : 0x28;

	dev_info(&client->dev, "reset dc3 nrmvolt\n");
	regmap_write(adev->regmap, APW8886_REG_DC3_NRMVOLT, val);

	/*
	 * Optionally cut all rails via the PMIC SOFTOFF sequence. The PMIC
	 * keeps monitoring /PWRKEY on VCC, so a power-key long-press cold-
	 * boots the board. Enabled per-board through the DT property
	 * "anpec,softoff-on-shutdown".
	 *
	 * Do this on a real power-off and on halt. On reboot the rails must
	 * stay up so the SoC can come back by itself; cutting them would
	 * leave the board off until someone presses the power key.
	 */
	if ((system_state == SYSTEM_POWER_OFF ||
	     system_state == SYSTEM_HALT)) {
		dev_info(&client->dev, "PMIC soft power off\n");
		mdelay(100);
		regmap_update_bits(adev->regmap, APW8886_REG_SYS_CONTROL,
				   APW8886_SOFTOFF_MASK, APW8886_SOFTOFF_MASK);
	}
}

static const struct of_device_id apw8886_of_match[] = {
	{ .compatible = "anpec,apw8886", .data = (void *)APW888X_DEVICE_ID_APW8886, },
	{ .compatible = "anpec,apw7899", .data = (void *)APW888X_DEVICE_ID_APW7899, },
	{}
};
MODULE_DEVICE_TABLE(of, apw8886_of_match);

static const struct i2c_device_id apw8886_i2c_ids[] = {
	{"apw8886", APW888X_DEVICE_ID_APW8886},
	{}
};
MODULE_DEVICE_TABLE(i2c, apw8886_i2c_ids);

static struct i2c_driver apw8886_i2c_driver = {
	.driver = {
		.name = "apw8886",
		.owner = THIS_MODULE,
		.of_match_table = of_match_ptr(apw8886_of_match),
		.pm = pm_sleep_ptr(&apw8886_pm_ops),
	},
	.id_table = apw8886_i2c_ids,
	.probe    = apw8886_i2c_probe,
	.remove   = apw8886_i2c_remove,
	.shutdown = apw8886_i2c_shutdown,
};
module_i2c_driver(apw8886_i2c_driver);

MODULE_DESCRIPTION("Anpec APW8886 PMIC MFD Driver");
MODULE_AUTHOR("Cheng-Yu Lee <cylee12@realtek.com>");
MODULE_LICENSE("GPL v2");
