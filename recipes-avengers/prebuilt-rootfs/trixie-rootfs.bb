# Hanlding prebuilt rootfs
# Use "bitbake trixie-image" to generate a Debian 13 trixie image

DESCRIPTIOM = "Handle Prebuilt Rootfs for Debian 13 trixie image"
LICENSE = "CLOSED"

require trixie-rootfs.inc

TRIXIE_ROOTFS_NAME = "trixie-rootfs.tar.xz"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = "file://${TRIXIE_ROOTFS_NAME};unpack=0"

do_install:append() {
	ln -sf ${WORKDIR}/${TRIXIE_ROOTFS_NAME} ${D}/${ROOTFS_NAME}
}
