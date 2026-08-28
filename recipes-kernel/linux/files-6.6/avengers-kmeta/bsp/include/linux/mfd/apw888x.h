/* SPDX-License-Identifier: GPL-2.0-only */
/*
 * Anpec APW888X series PMIC MFD
 *
 * Copyright (C) 2019 Realtek Semiconductor Corporation
 * Author: Cheng-Yu Lee <cylee12@realtek.com>
 */

#ifndef __LINUX_MFD_APW888X_H
#define __LINUX_MFD_APW888X_H

#include <linux/regmap.h>
#include <linux/types.h>

struct gpio_desc;

struct apw888x_device {
	u32 chip_id;
	u32 chip_rev;
	struct device *dev;
	struct regmap *regmap;
	struct gpio_desc *led_gpio;	/* "led-gpios" */
	int irq;			/* client->irq, saved for suspend/resume */
	bool irq_wake_on;		/* enable_irq_wake() succeeded */
};

#define APW888X_DEVICE_ID_APW8889       (8889)
#define APW888X_DEVICE_ID_APW8886       (8886)
#define APW888X_DEVICE_ID_APW7899       (7899)

#endif /* __LINUX_MFD_APW888X_H */
