ROOTFS_NAME = "rootfs.tar.xz"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = " \
	file://configs/fstab \
	"

do_install() {
	install -d 755 ${D}/etc
	install -m 644 ${WORKDIR}/configs/fstab ${D}/etc

	if [ "${@bb.utils.contains("MACHINE_FEATURES", "split-home", "1", "0", d)}" = "0" ]; then
		sed -i -e 's:^LABEL=home:#LABEL=home:' ${D}/etc/fstab
	fi

	if [ "${@bb.utils.contains("MACHINE_FEATURES", "overlayfs-root", "1", "0", d)}" = "1" ]; then
		sed -i -e 's:^LABEL=rootfs:#LABEL=rootfs:' ${D}/etc/fstab
	fi
}

do_package_qa[noexec] = "1"

FILES:${PN} += "/${ROOTFS_NAME}"
