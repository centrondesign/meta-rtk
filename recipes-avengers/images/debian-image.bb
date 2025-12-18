DESCRIPTIOM = "Linux Based Image for GamePad"
LICENSE = "CLOSED"

require recipes-avengers/images/linux-image.bb

PACKAGE_INSTALL:append = " prebuilt-rootfs  rtk-mod-npu"

#IMAGE_NAME = "gnulinux"
