# add a common override for all rtd1619b based board

MACHINEOVERRIDES =. "stark:bleedingedge-rtd1619b:"

require conf/machine/include/arm/armv8-2a/tune-cortexa55.inc
require conf/machine/include/avengers.inc
require conf/machine/include/overlayfs.inc

SPL_SUFFIX = "bin_pad"
SPL_BINARY = "spl/u-boot-spl.bin_pad"

#UBOOT_MACHINE = "rtd1619b_emmc_defconfig"
UBOOT_CONFIG ??= "rtd1619b_emmc"
UBOOT_CONFIG[rtd1619b_emmc] = "rtd1619b_${MACHINE}_defconfig,,u-boot.itb"

IMAGE_BOOT_FILES += " \
	u-boot.bin-rtd1619b_emmc \
	"

KERNEL_DEVICETREE = " \
	realtek/rtd1619b-${MACHINE}.dtb \
	realtek/rtd1619b-rescue-${MACHINE}.dtb \
	"
IMAGE_INSTALL:append = " ${@bb.utils.contains('MACHINE_FEATURES', 'drm', 'linux-firmware-rtd1619b', '', d)}"
IMAGE_INSTALL:append = " ${@bb.utils.contains('MACHINE_FEATURES', 'npu', 'libnpu', '', d)}"
IMAGE_INSTALL:append = " ${@bb.utils.contains('MACHINE_FEATURES', 'npu', 'rtk-mod-npu', '', d)}"
IMAGE_INSTALL:append = " ${@bb.utils.contains('MACHINE_FEATURES', 'npu', 'npu-header-dev', '', d)}"
IMAGE_INSTALL:append = " ${@bb.utils.contains('MACHINE_FEATURES', 'npu', 'fr-demo', '', d)}"
IMAGE_INSTALL:append = " ${@bb.utils.contains('MACHINE_FEATURES', 'npu', 'od-demo', '', d)}"
IMAGE_INSTALL:append = " ${@bb.utils.contains('MACHINE_FEATURES', 'npu', 'pose-demo', '', d)}"
IMAGE_INSTALL:append = " ${@bb.utils.contains('MACHINE_FEATURES', 'tee', 'linux-tee', '', d)}"
