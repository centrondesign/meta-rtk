DESCRIPTIOM = "Debian 13 trixie image"
LICENSE = "CLOSED"

inherit image
require recipes-avengers/prebuilt-rootfs/trixie-rootfs.inc

IMAGE_FEATURES = ""
IMAGE_FEATURES += "${@bb.utils.contains('MACHINE_FEATURES', 'overlayfs-root', ' overlayfs-root', '', d)}"
PACKAGE_INSTALL = "kernel-modules linux-firmware-rtl8822 rtk-mod-wifi"
PACKAGE_INSTALL:append = " ${@bb.utils.contains('MACHINE_FEATURES', 'v4l2', 'rtk-mod-v4l2dec rtk-mod-v4l2cap', '', d)}"
PACKAGE_INSTALL:append = " ${@([t for t in d.getVar('IMAGE_INSTALL', True).split() if t.startswith('linux-firmware')] or [''])[0]}"
PACKAGE_INSTALL:append = " trixie-rootfs"

#use the layout with separate home partition
WKS_FILE := "${@bb.utils.contains('MACHINE_FEATURES', 'split-home', 'avengers-home.wks', '${WKS_FILE}', d)}"

fakeroot do_prebuilt() {
	tar --exclude=usr/lib/firmware --exclude=usr/lib/modules -xf ${IMAGE_ROOTFS}/${ROOTFS_NAME} -C ${IMAGE_ROOTFS}
	rm -f ${IMAGE_ROOTFS}/${ROOTFS_NAME}
}

do_prebuilt[depends] += "virtual/fakeroot-native:do_populate_sysroot"

addtask prebuilt after do_rootfs before do_image
